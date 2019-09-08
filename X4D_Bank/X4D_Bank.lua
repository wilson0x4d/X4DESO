local X4D_Bank = LibStub:NewLibrary("X4D_Bank", 1028)
if (not X4D_Bank) then
    return
end
local X4D = LibStub("X4D")
X4D.Bank = X4D_Bank

X4D_Bank.NAME = "X4D_Bank"
X4D_Bank.VERSION = "1.28"

X4D_BANKACTION_NONE = 0
X4D_BANKACTION_DEPOSIT = 1
X4D_BANKACTION_WITHDRAW = 2
X4D_BANKACTION_IGNORE = 3

local constUnspecified = X4D.Colors.Gray .. "Unspecified"
local constDeposit = X4D.Colors.Deposit .. "Deposit"
local constWithdraw = X4D.Colors.Withdraw .. "Withdraw"

local _itemTypeChoices = {
    constUnspecified,
    constDeposit,
    constWithdraw,
}

X4D_Bank.Colors = {
    X4D = "|cFFAE19",
    Gray = "|cC5C5C5",
    Gold = "|cFFD700",
    StackCount = "|cFFFFFF",
    BagSpaceLow = "|cFFd00b",
    BagSpaceFull = "|cAA0000",
    Subtext = "|c5C5C5C",
}

local _nextAutoDepositTime = 0 -- the next time we will bother attempting to auto-deposit/withdraw any currency
local _isBankBusy = false -- true if a bank is currently busy processing, used to prevent renentrancy into async addon methods
local _isBankOpen = false -- true if a bank is currently open, regardless of its processing state

--region MRL helpers

local _mrlIdealRate = 5 -- arbitrary
local _mrlLastTimestamp = 0
local _mrlCountSinceLast = 0
local function MRL_Increment(count)
	if (count == nil) then
		count = 1
	end
	_mrlCountSinceLast = _mrlCountSinceLast + count
	return _mrlCountSinceLast
end
local function MRL_GetCount()
	return _mrlCountSinceLast
end
local function MRL_WouldExceedLimit()
	-- TODO: calculate based on all factors, Fx. does the MRL have decay? what is the peak before we must meet decay requirements? et cetera.
	local ts = GetGameTimeMilliseconds()
	local seconds = ((ts - _mrlLastTimestamp) + 1) / 1000
	local rate = _mrlCountSinceLast / seconds
	return (rate > _mrlIdealRate); -- arbitrary, 2-per-second (sustained) would hit limit
end
local function MRL_GetMessageRateLimit()
	-- TODO: this is guesswork, I still have not seen a definition of MRL from ZO staff, see also: https://forums.elderscrollsonline.com/en/discussion/169096/what-is-the-message-rate-limit-exactly
	-- NOTE: the MRL of 500ms noted in that thread would appear to be incorrect for bank management, suggesting different MRLs are applied to difference game services, if we refactor MRL into reusable code we must be able to get an "MRL state" based on a "group key" so that relevant bits of code can share an instance, without sharing a reference
	local ts = GetGameTimeMilliseconds()
	local seconds = ((ts - _mrlLastTimestamp) + 1) / 1000
	local rate = _mrlCountSinceLast / seconds
	if (rate > _mrlIdealRate) then
		waitTime = (((rate - _mrlIdealRate) / _mrlIdealRate) * 500) -- wait one "half second" (500ms) for every overage of "ideal-per-second", ie. if ideal rate is 3 and current rate is 9, we wait ~800ms to 'nudge' the rate down toward our ideal rate (~50% if we're doing sustained rates), if the next rate count is 6 (overage of 3), we nudge down again by ~600 (another 50%, or 75% of original burst rate). typically it takes ~2 seconds to match target MRL, and we do not incur heavy delays in UI/performance doing it this way.
	else
		waitTime = 50 -- TODO: determine average (or current) ping/latency, and apply it here, effectively giving up "a network slice" to other addon code
	end
	if (waitTime < 50) then -- max effective rate once at peak is 20/s
		waitTime = 50 -- apply a minimum wait period, this solves the problem of overly aggressive ideal-rate delay calculations (e.g. sub-50ms waits, they only eat CPU, providing no real value beyond the initial burst)
	end
--	X4D.Log:Verbose("X4D_Bank MRL waitTime=" .. waitTime)
	return waitTime
end
local function MRL_ResetRate()
	_mrlCountSinceLast = 0
	_mrlLastTimestamp = GetGameTimeMilliseconds()
end

--endregion MRL helpers
--region Chat Callback

local function DefaultChatCallback(color, text)
    d(color .. text)
end

X4D_Bank.ChatCallback = DefaultChatCallback

function X4D_Bank.RegisterChatCallback(self, callback)
    if (callback ~= nil) then
        X4D_Bank.ChatCallback = callback
    else
        X4D_Bank.ChatCallback = DefaultChatCallback
    end
end

function X4D_Bank.UnregisterChatCallback(self, callback)
    if (X4D_Bank.ChatCallback == callback) then
        self:RegisterChatCallback(nil)
    end
end

local function InvokeChatCallback(color, text)
    local callback = X4D_Bank.ChatCallback
    if (color == nil) then
        color = "|cFF0000"
    end
    if (color:len() < 8) then
        color = "|cFF0000"
    end
    if (callback ~= nil) then
        callback(color, text)
    end
end

--endregion

local function IsSlotIgnoredItem(slot)
    if (not slot.IsEmpty) then
        local normalized = X4D.Bags:GetNormalizedString(slot)
        local patterns = X4D_Bank.Settings:Get("IgnoredItemPatterns")
        for i = 1, #patterns do
            local pattern = patterns[i]
            local isIgnored = false
            if (not pcall( function()
                    if (normalized:find(pattern)) then
                        isIgnored = true
                    end
                end)) then
                InvokeChatCallback(X4D.Colors.SYSTEM, "(BANK) Bad Item Pattern: |cFF7777" .. pattern)
            end
            if (isIgnored) then
                return true
            end
        end
    end
    return false
end

local function GetPatternAction(slot)
--    X4D.Log:Verbose{"GetPatternAction", slot.Id, slot.Item.Name}
    local patternAction = X4D_BANKACTION_NONE
    if (not slot.IsEmpty) then
        if (IsSlotIgnoredItem(slot)) then
            patternAction = X4D_BANKACTION_IGNORE
        else
            local normalized = X4D.Bags:GetNormalizedString(slot)
            local withdrawPatterns = X4D_Bank.Settings:Get("WithdrawItemPatterns")
            for i = 1, #withdrawPatterns do
                local pattern = withdrawPatterns[i]
                if (not pcall( function()
                    if (normalized:find(pattern)) then
                        patternAction = X4D_BANKACTION_WITHDRAW
                    end
                end)) then
                    InvokeChatCallback(X4D.Colors.SYSTEM, "(Bank) Bad 'Withdraw Item' Pattern: |cFF7777" .. pattern)
                end
                if (patternAction ~= X4D_BANKACTION_NONE) then
                    return patternAction
                end
            end
            local depositPatterns = X4D_Bank.Settings:Get("DepositItemPatterns")
            for i = 1, #depositPatterns do
                local pattern = depositPatterns[i]
                if (not pcall( function()
                        if (normalized:find(pattern)) then
                            patternAction = X4D_BANKACTION_DEPOSIT
                        end
                    end)) then
                    InvokeChatCallback(X4D.Colors.SYSTEM, "(Bank) Bad 'Deposit Item' Pattern: |cFF7777" .. pattern)
                end
                if (patternAction ~= X4D_BANKACTION_NONE) then
                    return patternAction
                end
            end
        end
    end
    return patternAction
end

local function TryGetBag(bagId)
    return X4D.Bags:GetBag(bagId, true)
end

local function TryDepositFixedAmount()
    local availableAmount = GetCurrentMoney() - X4D_Bank.Settings:Get("ReserveCashOnHand")
    local depositAmount = X4D_Bank.Settings:Get("AutoDepositFixedAmount")
    if (depositAmount > 0) then
        if (availableAmount < depositAmount) then
            depositAmount = availableAmount
        end
        if (availableAmount >= depositAmount) then
            DepositMoneyIntoBank(depositAmount)
        end
    end
    return availableAmount - depositAmount
end

local function TryDepositPercentage(availableAmount)
    local depositAmount = (availableAmount * (X4D_Bank.Settings:Get("AutoDepositPercentage") / 100))
    if (depositAmount > 0) then
        DepositMoneyIntoBank(depositAmount)
    end
    return availableAmount - depositAmount
end

local function TryWithdrawReserveAmount()
    local carriedAmount = GetCurrentMoney()
    local deficit = X4D_Bank.Settings:Get("ReserveCashOnHand") - carriedAmount
    if (deficit > 0) then
        if (GetBankedMoney() > deficit) then
            WithdrawMoneyFromBank(deficit)
        end
    end
end

local function CreateSettingsName(itemType)
    return itemType.Id
end

local _itemTypeActions = nil
local _itemTypeActionsExpiry = 0

local function GetItemTypeActions()
	local startTime = GetGameTimeMilliseconds()
	if (_itemTypeActions == nil or _itemTypeActionsExpiry < GetGameTimeMilliseconds()) then
		-- TODO: when settings are saved/set, these actions should be invalidated in order to cause a refresh, instead we have an expiry implemented, below.
		local itemTypeActions = { }
		for _,groupName in pairs(X4D.Items.ItemGroups) do
			for _,itemType in pairs(X4D.Items.ItemTypes) do
				if (itemType.Group == groupName) then
					local dropdownName = CreateSettingsName(itemType)
					local direction = X4D_Bank.Settings:Get(dropdownName) or 0
					itemTypeActions[itemType.Id] = direction
				end
			end
		end
		_itemTypeActions = itemTypeActions
		_itemTypeActionsExpiry = startTime + 7000 -- TODO: arbitrary, could remove expiry if this was invalidated whenever settings were set, so this expiry only exists to ensure new settings are picked up within a reasonable time-frame after being set -- we chose 7s because we feel it's improbably that a user would interact with a bank, reconfigure the add-on, then interact with the bank again within a 7 second period
	end
	return _itemTypeActions 
end

local function ShouldDepositItemType(slot)
	local itemTypeActions = GetItemTypeActions()
    return itemTypeActions[slot.Item.ItemType] == X4D_BANKACTION_DEPOSIT
end

local function ShouldWithdrawItemType(slot)
	local itemTypeActions = GetItemTypeActions()
    return itemTypeActions[slot.Item.ItemType] == X4D_BANKACTION_WITHDRAW
end

local function TryCombinePartialStacks(bag, depth)
    if (depth == nil) then
        depth = 3
    end
    ClearCursor()
    local combines = { }
    local combineCount = 0
    for i = 1, bag.PartialStackCount do
        local lval = bag.PartialStacks[i]
        if (lval == nil) then
--            X4D.Log:Error{"TryCombinePartialStacks", "INVALID SLOT INDEX " .. i}
        else
            for j = i + 1, (bag.PartialStackCount - 1) do
                local rval = bag.PartialStacks[j]
                if (rval ~= nil) then
                    local lslot = bag.Slots[lval.Id]
                    local rslot = bag.Slots[rval.Id]
					if lslot ~= nil and rslot ~= nil and(not lslot.IsEmpty) and(not rslot.IsEmpty) and (lval.Item ~= nil and rval.Item ~= nil) then
						if ((lval.Id ~= rval.Id) and(lval.ItemLevel == rval.ItemLevel) and(lval.ItemQuality == rval.ItemQuality) and (lval.Item.Id == rval.Item.Id) and(rval.StackCount ~= 0) and(lval.StackCount ~= 0) and(lslot.IsStolen == rslot.IsStolen)) then
							table.insert(combines, { [1] = lval, [2] = rval })
							break
						end
					end
                end
            end
        end
    end
    for i,combine in pairs(combines) do
--        X4D.Log:Verbose{i,combine}
        local lval, rval = combines[i][1], combines[i][2]
        local countToMove = (rval.Item.StackMax - rval.StackCount)
        if (lval.StackCount < countToMove) then
            countToMove = lval.StackCount
        end
        if (countToMove > 0) then
            rval.StackCount = rval.StackCount + countToMove
            lval.StackCount = lval.StackCount - countToMove
            CallSecureProtected("PickupInventoryItem", bag.Id, lval.Id, countToMove)
            CallSecureProtected("PlaceInInventory", bag.Id, rval.Id)
			MRL_Increment(1)
            local message = zo_strformat("<<1>> <<2>><<t:3>> <<4>>x<<5>> <<6>>",
                "Restacked", lval.Item:GetItemIcon(), lval.Item:GetItemLink(), X4D.Colors.StackCount, countToMove)
			InvokeChatCallback(lval.ItemColor, message)
            combineCount = combineCount + 1
			if (MRL_WouldExceedLimit()) then
				return false
			end
        end
    end
    if (combineCount > 0 and depth > 0) then
        return TryCombinePartialStacks(bag, depth - 1)
	else
		return true
    end
end

local function FindTargetSlots(sourceSlot, targetBag)
    local partials = { }
    local empties = { }
    local remaining = sourceSlot.StackCount
	for slotIndex = 0, (targetBag.SlotCount - 1) do
        local slot = targetBag.Slots[slotIndex]
        if (slot == nil) then
            X4D.Log:Error{"FindTargetSlots", "INVALID SLOT INDEX " .. slotIndex}
        elseif (slot.IsEmpty) then
            table.insert(empties, slot)
        elseif (sourceSlot.Item ~= nil and slot.Item ~= nil) then
			if ((sourceSlot.ItemLevel == slot.ItemLevel) and(sourceSlot.ItemQuality == slot.ItemQuality) and(sourceSlot.Item.Id == slot.Item.Id) and(slot.StackCount < slot.Item.StackMax) and(sourceSlot.IsStolen == slot.IsStolen)) then
				table.insert(partials, slot)
				remaining = slot.Item.StackMax - slot.StackCount
				if (remaining <= 0) then
					break
				end
			end
		end
    end
    return partials, empties
end

local function TryMoveSourceSlotToTargetBag(sourceBag, sourceSlot, targetBag, directionText)
    local itemIcon = sourceSlot.Item:GetItemIcon()
    local itemLink = sourceSlot.Item:GetItemLink()
    local countRemaining = 0
    local totalMoved = 0
    local usedEmptySlot = false
    local partialSlots, emptySlots = FindTargetSlots(sourceSlot, targetBag)
--    X4D.Log:Verbose{partialSlots, emptySlots}
    for _, targetSlot in pairs(partialSlots) do
        local countToMove = targetSlot.Item.StackMax - targetSlot.StackCount
        if (countToMove > sourceSlot.StackCount) then
            countToMove = sourceSlot.StackCount
        end
        CallSecureProtected("PickupInventoryItem", sourceBag.Id, sourceSlot.Id, countToMove)
        CallSecureProtected("PlaceInInventory", targetBag.Id, targetSlot.Id)
		MRL_Increment(1)
--        X4D.Log:Verbose{"TryMove(topartial)", sourceBag.Id, sourceSlot.Id, countToMove, targetBag.Id, targetSlot.Id}
        totalMoved = totalMoved + countToMove
        sourceSlot.StackCount = sourceSlot.StackCount - countToMove
        if (sourceSlot.StackCount <= 0) then
            sourceSlot.IsEmpty = true
			sourceSlot.Item = nil
            break
        end
		if (MRL_WouldExceedLimit()) then
			return totalMoved, usedEmptySlot
		end
    end
    if (not sourceSlot.IsEmpty) then
        for _, targetSlot in pairs(emptySlots) do
            if (targetSlot.IsEmpty) then
                local countToMove = sourceSlot.StackCount
                CallSecureProtected("PickupInventoryItem", sourceBag.Id, sourceSlot.Id, countToMove)
                CallSecureProtected("PlaceInInventory", targetBag.Id, targetSlot.Id)
				MRL_Increment(1)
--                X4D.Log:Verbose{"TryMove(toempty)", sourceBag.Id, sourceSlot.Id, countToMove, targetBag.Id, targetSlot.Id}
                targetSlot.IsEmpty = false
                usedEmptySlot = true
                totalMoved = totalMoved + countToMove
                sourceSlot.StackCount = sourceSlot.StackCount - countToMove
                if (sourceSlot.StackCount <= 0) then
                    sourceSlot.IsEmpty = true
					sourceSlot.Item = nil
                    break
                end
            end
			if (MRL_WouldExceedLimit()) then
				return totalMoved, usedEmptySlot
			end
        end
    end
    if (totalMoved > 0) then
        local message = zo_strformat("<<1>> <<2>><<t:3>> <<4>>x<<5>>",
            directionText, itemIcon, itemLink, X4D.Colors.StackCount, totalMoved)
		InvokeChatCallback(sourceSlot.ItemColor, message)
    end
    return totalMoved, usedEmptySlot
end

local function ConductTransactions(transactionState)
    local isESOPlusSubscriber = IsESOPlusSubscriber()
	local itemTypeActions = GetItemTypeActions()
	if (transactionState[BAG_BACKPACK] == nil) then
		transactionState[BAG_BACKPACK] = TryGetBag(BAG_BACKPACK)
	end
	if (transactionState[BAG_BANK] == nil) then
		transactionState[BAG_BANK] = TryGetBag(BAG_BANK)
	end
	if (isESOPlusSubscriber and transactionState[BAG_SUBSCRIBER_BANK] == nil) then
		transactionState[BAG_SUBSCRIBER_BANK] = TryGetBag(BAG_SUBSCRIBER_BANK)
	end

    if (not TryCombinePartialStacks(transactionState[BAG_BACKPACK])) then
		return false
	end
	if (not TryCombinePartialStacks(transactionState[BAG_BANK])) then
		return false
	end
    if (isESOPlusSubscriber) then
        if (not TryCombinePartialStacks(transactionState[BAG_SUBSCRIBER_BANK])) then
            return false
        end
	end

    ClearCursor()

	if (transactionState.pendingDeposits == nil) then
		for _, slot in pairs(transactionState[BAG_BACKPACK].Slots) do
			if (slot ~= nil and not slot.IsEmpty and slot.Item ~= nil) then
				local slotAction = GetPatternAction(slot)
				if (slotAction == X4D_BANKACTION_NONE) then
					slotAction = itemTypeActions[slot.Item.ItemType]
                end
                if (slotAction == X4D_BANKACTION_DEPOSIT) then
					transactionState.pendingDepositCount = transactionState.pendingDepositCount + 1
					transactionState.pendingDeposits = {
						n = transactionState.pendingDeposits,
                        v = slot,
                        b = BAG_BACKPACK
					}
				end
			else
				transactionState[BAG_BACKPACK].FreeCount = transactionState[BAG_BACKPACK].FreeCount + 1
			end
		end
		if (transactionState.pendingDeposits == nil) then
			transactionState.pendingDeposits = false
		end
	end

	if (transactionState.pendingWithdrawals == nil) then
		for _, slot in pairs(transactionState[BAG_BANK].Slots) do
			if (slot ~= nil and not slot.IsEmpty) then
				local slotAction = GetPatternAction(slot)
				if (slotAction == X4D_BANKACTION_NONE and slot.Item ~= nil) then
					slotAction = itemTypeActions[slot.Item.ItemType]
				end
				if (slotAction == X4D_BANKACTION_WITHDRAW) then
					transactionState.pendingWithdrawalCount = transactionState.pendingWithdrawalCount + 1
					transactionState.pendingWithdrawals = {
						n = transactionState.pendingWithdrawals,
                        v = slot,
                        b = BAG_BANK
					}
				end
			else
				transactionState[BAG_BANK].FreeCount = transactionState[BAG_BANK].FreeCount + 1
			end
		end

        if (isESOPlusSubscriber) then
            for _, slot in pairs(transactionState[BAG_SUBSCRIBER_BANK].Slots) do
                if (slot ~= nil and not slot.IsEmpty) then
                    local slotAction = GetPatternAction(slot)
                    if (slotAction == X4D_BANKACTION_NONE and slot.Item ~= nil) then
                        slotAction = itemTypeActions[slot.Item.ItemType]
                    end
                    if (slotAction == X4D_BANKACTION_WITHDRAW) then
                        transactionState.pendingWithdrawalCount = transactionState.pendingWithdrawalCount + 1
                        transactionState.pendingWithdrawals = {
                            n = transactionState.pendingWithdrawals,
                            v = slot,
                            b = BAG_SUBSCRIBER_BANK
                        }
                    end
                else
                    transactionState[BAG_SUBSCRIBER_BANK].FreeCount = transactionState[BAG_SUBSCRIBER_BANK].FreeCount + 1
                end
            end
        end

		if (transactionState.pendingWithdrawals == nil) then
			transactionState.pendingWithdrawals = false
		end
	end

	local wasAnyChangeMade = false
    local shouldProcessBags = (transactionState.pendingDepositCount > 0 or transactionState.pendingWithdrawalCount > 0)
	local sourceBag
	local targetBag
	while (shouldProcessBags) do
        shouldProcessBags = false
        -- deposits
        while (transactionState.pendingDeposits) do
            local sourceSlot = transactionState.pendingDeposits.v
            sourceBag = transactionState[transactionState.pendingDeposits.b]
            transactionState.pendingDeposits = transactionState.pendingDeposits.n
            if (not sourceSlot.IsEmpty) then
                local usedEmptySlots = 0

                if (transactionState[BAG_BANK].FreeCount > 0 or not isESOPlusSubscriber) then
                    targetBag = transactionState[BAG_BANK]
                elseif (isESOPlusSubscriber) then
                    targetBag = transactionState[BAG_SUBSCRIBER_BANK]
                end

                local countMoved, L_usedEmptySlot = TryMoveSourceSlotToTargetBag(sourceBag, sourceSlot, targetBag, "Deposited")
                wasAnyChangeMade = wasAnyChangeMade or countMoved > 0
                if (L_usedEmptySlot) then
                    usedEmptySlots = usedEmptySlots + 1
                end
                while (countMoved > 0 and not sourceSlot.IsEmpty) do
                    transactionState.totalDeposits = transactionState.totalDeposits + countMoved
                    countMoved, L_usedEmptySlot = TryMoveSourceSlotToTargetBag(sourceBag, sourceSlot, targetBag, "Deposited")
                    if (L_usedEmptySlot) then
                        usedEmptySlots = usedEmptySlots + 1
                    end
                end
                transactionState.totalDeposits = transactionState.totalDeposits + countMoved
                if (usedEmptySlots > 0) then
                    targetBag.FreeCount = targetBag.FreeCount - usedEmptySlots
                    if (transactionState.pendingWithdrawalCount > 0) then
                        shouldProcessBags = true
                    end
                end
                if (sourceSlot.IsEmpty) then
                    sourceBag.FreeCount = sourceBag.FreeCount + 1
                    transactionState.pendingDepositCount = transactionState.pendingDepositCount - 1
                end
                if (MRL_WouldExceedLimit()) then
                    return false
                end
            end
        end
        -- withdrawals
		targetBag = transactionState[BAG_BACKPACK]
		while (transactionState.pendingWithdrawals) do
            local sourceSlot = transactionState.pendingWithdrawals.v
            sourceBag = transactionState[transactionState.pendingWithdrawals.b]
			transactionState.pendingWithdrawals = transactionState.pendingWithdrawals.n
			if (not sourceSlot.IsEmpty) then
				local usedEmptySlots = 0
				local countMoved, L_usedEmptySlot = TryMoveSourceSlotToTargetBag(sourceBag, sourceSlot, targetBag, "Withdrew")
				wasAnyChangeMade = wasAnyChangeMade or countMoved > 0
				if (L_usedEmptySlot) then
					usedEmptySlots = usedEmptySlots + 1
				end
				while (countMoved > 0 and not sourceSlot.IsEmpty) do
					transactionState.totalWithdrawals = transactionState.totalWithdrawals + countMoved
					countMoved, L_usedEmptySlot = TryMoveSourceSlotToTargetBag(sourceBag, sourceSlot, targetBag, "Withdrew")
					if (L_usedEmptySlot) then
						usedEmptySlots = usedEmptySlots + 1
					end
				end
				transactionState.totalWithdrawals = transactionState.totalWithdrawals + countMoved
				if (usedEmptySlot) then
					targetBag.FreeCount = targetBag.FreeCount - usedEmptySlots
					if (transactionState.pendingDepositCount > 0) then
						shouldProcessBags = true
					end
				end
				if (sourceSlot.IsEmpty) then
					sourceBag.FreeCount = sourceBag.FreeCount + 1
					transactionState.pendingWithdrawalCount = transactionState.pendingWithdrawalCount - 1
				end
				if (MRL_WouldExceedLimit()) then
					return false
				end
			end
        end
	end

	-- HACK: we require at least one "re-entry" in order to continue deposits and withdrawals in the case where we've hit a cap, before v1.27 we would simply loop one addiitonal iteration
	if (wasAnyChangeMade) then
		-- HACK: this reset ensures that we do not wait unnecessarily (the loop above already performed this check, and exiting with `false` would incur a wait we would not otherwise incur, the user will notice.)
		MRL_ResetRate()
		return false
	end

	-- HACK: ideally we should not need to refresh state like this to know proper "FreeCount" -- however, FreeCount is not being maintained correctly, today, and without this we get incorrect counts on the summary message printed further below
    transactionState[BAG_BACKPACK] = TryGetBag(BAG_BACKPACK)
    transactionState[BAG_BANK] = TryGetBag(BAG_BANK)
    if (isESOPlusSubscriber) then
        transactionState[BAG_SUBSCRIBER_BANK] = TryGetBag(BAG_SUBSCRIBER_BANK)
    end

    local message
    local inventoryFreeColor = X4D.Colors.Gold
    if (transactionState[BAG_BACKPACK].FreeCount < (transactionState[BAG_BACKPACK].SlotCount * 0.2)) then
        inventoryFreeColor = X4D.Colors.Red
    end
    local bankFreeColor = X4D.Colors.Gold
    local bankFreeCount = transactionState[BAG_BANK].FreeCount
    local bankSlotCount = transactionState[BAG_BANK].SlotCount
    if (isESOPlusSubscriber) then
        bankFreeCount = bankFreeCount + transactionState[BAG_SUBSCRIBER_BANK].FreeCount
        bankSlotCount = bankSlotCount + transactionState[BAG_SUBSCRIBER_BANK].SlotCount
    end
    X4D.Log:Warning(isESOPlusSubscriber, "isESOPlusSubscriber")
    if (bankFreeCount < (bankSlotCount * 0.2)) then
        bankFreeColor = X4D.Colors.Red
    end
    if (transactionState.totalDeposits > 0 or transactionState.totalWithdrawals > 0) then
        message = string.format("Bank Deposits: %s, Withdrawals: %s, Bank: %s/%s free, Backpack: %s/%s free",
            X4D.Colors.Gold .. transactionState.totalDeposits .. X4D.Colors.X4D, X4D.Colors.Gold .. transactionState.totalWithdrawals .. X4D.Colors.X4D, 
            bankFreeColor .. bankFreeCount .. X4D.Colors.X4D, bankSlotCount,
            inventoryFreeColor .. transactionState[BAG_BACKPACK].FreeCount .. X4D.Colors.X4D, transactionState[BAG_BACKPACK].SlotCount)
    else
        message = string.format("Bank: %s/%s free, Backpack: %s/%s free",
            bankFreeColor .. bankFreeCount .. X4D.Colors.X4D, bankSlotCount,
            inventoryFreeColor .. transactionState[BAG_BACKPACK].FreeCount .. X4D.Colors.X4D, transactionState[BAG_BACKPACK].SlotCount)
    end
    InvokeChatCallback(X4D.Colors.X4D, message)

	return true
end

local function OnOpenBankAsync(timer, transactionState)
    timer:Stop()
--	X4D.Log:Warning("BEGIN " .. timer.Name)
	if (not _isBankOpen) then
		_isBankBusy = false
	else
		-- item transactions
		if (not ConductTransactions(transactionState)) then
			timer._interval = MRL_GetMessageRateLimit()
			timer._enabled = true -- we do not call start because zo_calllater is called on our behalf if _enabled == true
		else
			-- monetary transactions
			if (_nextAutoDepositTime <= GetGameTimeMilliseconds()) then
				_nextAutoDepositTime = GetGameTimeMilliseconds() + (X4D_Bank.Settings:Get("AutoDepositDebounceSeconds") * 1000) + 2000
				local availableAmount = TryDepositFixedAmount()
				TryDepositPercentage(availableAmount)
			end
			TryWithdrawReserveAmount()
			_isBankBusy = false
		end
	end
--	X4D.Log:Warning("END " .. timer.Name)
end

local function OnOpenBank(eventCode)
--	X4D.Log:Warning("BEGIN OnOpenBank")
	_isBankOpen = true;
	local banker = X4D.NPCs:GetOrCreate("interact")
	X4D.NPCs.CurrentNPC(banker)
	if (not _isBankBusy) then
		_isBankBusy = true
		local transactionState = {
			totalDeposits = 0,
			totalWithdrawals = 0,
			pendingDeposits = nil, 
			pendingDepositCount = 0,
			pendingWithdrawals = nil,
			pendingWithdrawalCount = 0,
		}
		MRL_ResetRate() -- we always reset the rate limit when the UI is first opened, the allow the rate to compound for the duration of the bank session
		X4D.Async:CreateTimer(OnOpenBankAsync):Start(500, transactionState, "X4D_Bank::ConductTransactions") -- we apply a standard start delay of 500 ms, an arbitrary period, but it seems to be enough to allow the UI to finish initializing itself with data
	end
--	X4D.Log:Warning("END OnOpenBank")
end

local function OnCloseBank()
	_isBankOpen = false;
	-- TODO: cancel any busy timers
    -- coerce update of bag snapshots on close
    local inventoryState = TryGetBag(BAG_BACKPACK)
    local bankState = TryGetBag(BAG_BANK)
    if (IsESOPlusSubscriber()) then
        local subscriberBankState = TryGetBag(BAG_SUBSCRIBER_BANK)
    end
	X4D.NPCs.CurrentNPC(nil)
end

function X4D_Bank:GetOrCreateBanker(tag)
	return X4D.NPCs:GetOrCreate(tag)
end

local function SetComboboxValue(controlName, value)
    local combobox = _G[controlName]
    local dropmenu = ZO_ComboBox_ObjectFromContainer(GetControl(combobox, 'Dropdown'))
    local items = dropmenu:GetItems()
    for k, v in pairs(items) do
        if (v.name == value) then
            dropmenu:SetSelectedItem(v.name)
        end
    end
end

local function SetCheckboxValue(controlName, value)
    local control = _G[controlName]
    if (control ~= nil) then
        local checkbox = control:GetNamedChild("Checkbox")
        if (checkbox ~= nil) then
            checkbox:SetState(value and 1 or 0)
            checkbox:toggleFunction(value)
        end
    end
end

local function SetSliderValue(controlName, value, minValue, maxValue)
    local range = maxValue - minValue
    local slider = _G[controlName]
    local slidercontrol = slider:GetNamedChild('Slider')
    local slidervalue = slider:GetNamedChild('ValueLabel')
    slidercontrol:SetValue((value - minValue) / range)
    slidervalue:SetText(tostring(value))
end

local function InitializeSettingsUI()
    local LAM = LibStub("LibAddonMenu-2.0")
    local cplId = LAM:RegisterAddonPanel("X4D_BANK_CPL", {
        type = "panel",
        name = "X4D |cFFAE19Bank |c4D4D4D" .. X4D_Bank.VERSION,
    } )

    local panelControls = {
        [1] =
        {
            type = "dropdown",
            name = "Settings Are..",
            tooltip = "Settings Scope",
            choices = { "Account-Wide", "Per-Character" },
            getFunc = function() return X4D_Bank.Settings:Get("SettingsAre") or "Account-Wide" end,
            setFunc = function(v)
                if (X4D_Bank.Settings:Get("SettingsAre") ~= v) then
                    X4D_Bank.Settings:Set("SettingsAre", v)
                end
            end,
        },
        [2] =
        {
            type = "header",
            name = "Gold Deposits and Withdrawals",
        },
        [3] =
        {
            type = "slider",
            name = "Cash On Hand",
            tooltip = "If non-zero, the specified amount of carried gold will never be auto-deposited. If you are carrying less than this amount and the remainder is available in the bank the difference will be auto-withdrawn.",
            min = 0,
            max = 100000,
            step = 1000,
            getFunc = function() return X4D_Bank.Settings:Get("ReserveCashOnHand") end,
            setFunc = function(v) X4D_Bank.Settings:Set("ReserveCashOnHand", tonumber(tostring(v))) end,
        },
        [4] =
        {
            type = "slider",
            name = "Auto-Deposit Fixed Amount",
            tooltip = "If non-zero, will auto-deposit up to the configured amount when accessing the bank.",
            min = 0,
            max = 10000,
            step = 100,
            getFunc = function() return X4D_Bank.Settings:Get("AutoDepositFixedAmount") end,
            setFunc = function(v) X4D_Bank.Settings:Set("AutoDepositFixedAmount", tonumber(tostring(v))) end,
        },
        [5] =
        {
            type = "slider",
            name = "Auto-Deposit Percentage",
            tooltip = "If non-zero, will auto-deposit percentage of non-reserve gold when accessing the bank.",
            min = 0,
            max = 100,
            step = 1,
            getFunc = function() return X4D_Bank.Settings:Get("AutoDepositPercentage") end,
            setFunc = function(v) X4D_Bank.Settings:Set("AutoDepositPercentage", tonumber(tostring(v))) end,
        },
        [6] =
        {
            type = "slider",
            name = "Auto-Deposit Down-Time (DEBOUNCE)", -- TODO: there is a bug where when this setting is changed, the bank deposit expiry times are not recalculated (UX is broken) -- a /reloadui works around this
            tooltip = "If non-zero, will wait specified time (in seconds) between bank interactions before auto-depositing again.",
            min = 0,
            max = 3600,
            step = 36,
            getFunc = function() return X4D_Bank.Settings:Get("AutoDepositDebounceSeconds") end,
            setFunc = function(v) X4D_Bank.Settings:Set("AutoDepositDebounceSeconds", tonumber(tostring(v))) end,
        },
        [7] =
        {
            type = "checkbox",
            name = "Display Money Updates",
            tooltip = "When enabled, money updates are displayed in the Chat Window.",
            getFunc = function()
                return X4D.Bank.Settings:Get("DisplayMoneyUpdates")
            end,
            setFunc = function()
                X4D.Bank.Settings:Set("DisplayMoneyUpdates", not X4D.Bank.Settings:Get("DisplayMoneyUpdates"))
                if (X4D.Loot ~= nil) then
                    X4D.Loot.Settings:Set("DisplayMoneyUpdates", X4D.Bank.Settings:Get("DisplayMoneyUpdates"))
                end
            end,
        },
    }

    -- LAM:AddCheckbox(cplId,
    -- "X4D_BANK_CHECK_START_NEW_STACKS", "Start New Stacks?",
    -- "When enabled, new stacks of items will be created in your bank after partial stacks are filled.",
    -- function() return X4D_Bank.Settings:Get("StartNewStacks") end,
    -- function() X4D_Bank.Settings:Set("StartNewStacks", not X4D_Bank.Settings:Get("StartNewStacks")) end)

    --region ItemType Options

    for _,groupName in pairs(X4D.Items.ItemGroups) do
        table.insert(panelControls, {
            type = "header",
            name = groupName,
        })
        for _,itemType in pairs(X4D.Items.ItemTypes) do
            if (itemType.Group == groupName) then
                local dropdownName = CreateSettingsName(itemType)
                table.insert(panelControls, {
                    type = "dropdown",
                    name = itemType.Name,
                    tooltip = itemType.Tooltip or itemType.Canonical,
                    choices = _itemTypeChoices,
                    getFunc = function() 
                        local v = X4D_Bank.Settings:Get(itemType.Id) or X4D_BANKACTION_NONE
                        if (v == X4D_BANKACTION_DEPOSIT) then
                            return constDeposit
                        elseif (v == X4D_BANKACTION_WITHDRAW) then
                            return constWithdraw
                        else
                            return constUnspecified
                        end
                    end,
                    setFunc = function(v)
                        if (v == constDeposit) then
                            v = X4D_BANKACTION_DEPOSIT
                        elseif (v == constWithdraw) then
                            v = X4D_BANKACTION_WITHDRAW
                        else
                            v = X4D_BANKACTION_NONE
                        end
                        X4D_Bank.Settings:Set(itemType.Id, v)
                    end,
                    width = "half",
                })
            end
        end
    end

    table.insert(panelControls, {
        type = "header",
        name = 'Reset',
    })
    table.insert(panelControls, {
        type = "dropdown",
        name = "All Item Types",
        tooltip = "Use this to reset ALL item type settings to a specific value. This only exists to make reconfiguration a little less tedious. Please be aware that the UI will reload to force the changes to take effect.",
        choices = _itemTypeChoices,
        getFunc = function() 
            return constUnspecified
        end,
        setFunc = function(v)
            if (v == constDeposit) then
                v = X4D_BANKACTION_DEPOSIT
            elseif (v == constWithdraw) then
                v = X4D_BANKACTION_WITHDRAW
            else
                v = X4D_BANKACTION_NONE
            end
            for _,itemType in pairs(X4D.Items.ItemTypes) do
                local dropdownName = CreateSettingsName(itemType)
                X4D_Bank.Settings:Set(dropdownName, v)
            end
            ReloadUI() -- only necessary because i have no way to force LibAddonMenu to re-get/refresh all options
        end,
        width = "half",
    })

    -- endregion

	table.insert(panelControls, {
		type = "header",
		name = "Advanced Override Settings",
	})
	table.insert(panelControls, {
		type = "description",
		text = "This section provides advanced options which override the simple Deposit/Withdraw settings above. Hover the mouse over each option to see a useful description of behavior."
    })
    
    table.insert(panelControls, {
        type = "editbox",
        name = "'For " .. GetString(SI_BANK_WITHDRAW) .. "' Items",
        tooltip = "Line-delimited list of 'Withdraw' item patterns, items matching these patterns will be withdrawn from the bank regardless of any item type settings.\n|cFFFFFFITEM NAMES ARE NO LONGER SUPPORTED BY THE GAME, USE ITEM ID+OPTIONS INSTEAD.",
        isMultiline = true,
        width = "half",
        getFunc = function()
            local patterns = X4D_Bank.Settings:Get("WithdrawItemPatterns")
            if (patterns == nil or type(patterns) == "string") then
                patterns = { }
            end
            return table.concat(patterns, "\n")
        end,
        setFunc = function(v)
            local result = v:Split("\n")
            -- NOTE: this is a hack to deal with the fact that the LUA parser in ESO bugs out processing escaped strings in SavedVars :(
            for _, x in pairs(result) do
                if (x:EndsWith("]")) then
                    result[_] = x .. "+"
                end
            end
            X4D_Bank.Settings:Set("WithdrawItemPatterns", result)
        end,
    })

    table.insert(panelControls, {
        type = "editbox",
        name = "'For " .. GetString(SI_BANK_DEPOSIT) .. "' Items",
        tooltip = "Line-delimited list of 'Deposit' item patterns, items matching these patterns will be deposited into the bank regardless of any item type settings.\n|cFFFFFFITEM NAMES ARE NO LONGER SUPPORTED BY THE GAME, USE ID+OPTIONS INSTEAD.\n|cFFFFC7Note that the 'Withdraw' item patterns list takes precedence over the 'Deposit Patterns' list.",
        isMultiline = true,
        width = "half",
        getFunc = function()
            local patterns = X4D_Bank.Settings:Get("DepositItemPatterns")
            if (patterns == nil or type(patterns) == "string") then
                patterns = { }
            end
            return table.concat(patterns, "\n")
        end,
        setFunc = function(v)
            local result = v:Split("\n")
            -- NOTE: this is a hack to deal with the fact that the LUA parser in ESO bugs out processing escaped strings in SavedVars :(
            for _, x in pairs(result) do
                if (x:EndsWith("]")) then
                    result[_] = x .. "+"
                end
            end
            X4D_Bank.Settings:Set("DepositItemPatterns", result)
        end,
    })

    table.insert(panelControls, {
        type = "editbox",
        name = "'Ignored' Items",
        tooltip = "Line-delimited list of items to ignore using 'lua patterns'. Ignored items will NOT be withdrawn, deposited nor restacked regardless of any other setting.\n|cFFFFFFITEM NAMES ARE NO LONGER SUPPORTED BY THE GAME, USE ITEM ID+OPTIONS INSTEAD.\n|cC7C7C7Special patterns exist, such as: STOLEN, item qualities like TRASH, NORMAL, MAGIC, ARCANE, ARTIFACT, LEGENDARY, item types like BLACKSMITHING, CLOTHIER, MATERIALS, etc",
        isMultiline = true,
        width = "half",
        getFunc = function()
            local patterns = X4D_Bank.Settings:Get("IgnoredItemPatterns")
            if (patterns == nil or type(patterns) == "string") then
                patterns = { }
            end
            return table.concat(patterns, "\n")
        end,
        setFunc = function(v)
            local result = v:Split("\n")
            -- NOTE: this is a hack to deal with the fact that the LUA parser in ESO bugs out processing escaped strings in SavedVars :(
            for _, x in pairs(result) do
                if (x:EndsWith("]")) then
                    result[_] = x .. "+"
                end
            end
            X4D_Bank.Settings:Set("IgnoredItemPatterns", result)
        end,
    })

    LAM:RegisterOptionControls(
        "X4D_BANK_CPL",
        panelControls
    )

end

local function formatnum(n)
    local left, num, right = string.match(n, "^([^%d]*%d)(%d*)(.-)$")
    return left ..(num:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. right
end

local _goldIcon = " " .. X4D.Icons:CreateString("EsoUI/Art/currency/currency_gold.dds")

local function OnMoneyUpdate(eventId, newMoney, oldMoney, reasonId)
    --NOTE: Loot addon takes precedence
    if (not X4D.Bank.Settings:Get("DisplayMoneyUpdates")) then
        return
    end
    if ((reasonId == 1 or reasonId == 60 or reasonId == 63) and (X4D.Vendors ~= nil)) then
        -- leave display of income/expenses to Vendors Addon when present
        return
    end
    local reason = X4D.Currency:GetMoneyReason(reasonId)
    local amount = newMoney - oldMoney
    if (amount >= 0) then
        InvokeChatCallback(X4D_Bank.Colors.Gold, string.format("%s %s%s %s  (%s on-hand)", reason[1], formatnum(amount), _goldIcon, X4D_Bank.Colors.Subtext, formatnum(newMoney)))
    else
        InvokeChatCallback(X4D_Bank.Colors.Gold, string.format("%s %s%s %s  (%s on-hand)", reason[2], formatnum(math.abs(amount)), _goldIcon, X4D_Bank.Colors.Subtext, formatnum(newMoney)))
    end
end

local _statusBarPanel

local function UpdateStatusBarText()
    local backpack = X4D.Bags:GetBackpack()
    local backpackColor = "|cFFFFFF"
    if (backpack.FreeCount < (backpack.SlotCount * 0.2)) then
        backpackColor = X4D.Colors.Red
    end

    local bank, subscriberBank = X4D.Bags:GetBank()
    local bankColor = "|cFFFFFF"
    local bankFreeCount = bank.FreeCount
    local bankSlotCount = bank.SlotCount
    if (subscriberBank ~= nil) then
        bankFreeCount = bankFreeCount + subscriberBank.FreeCount
        bankSlotCount = bankSlotCount + subscriberBank.SlotCount
    end
    if (bankFreeCount < (bankSlotCount * 0.2)) then
        bankColor = X4D.Colors.Red
    end

    local text = string.format("  %s%s%s  %s%s%s  %s%s/%s%s  %s%s/%s%s  ",
        X4D.Currency.Gold.Color,
        X4D.Currency.Gold:GetCurrentAmount(),
        X4D.Icons:CreateString(X4D.Currency.Gold.Icon),
        X4D.Currency.AlliancePoints.Color,
        X4D.Currency.AlliancePoints:GetCurrentAmount(),
        X4D.Icons:CreateString(X4D.Currency.AlliancePoints.Icon),
        backpackColor,
        backpack.SlotCount - backpack.FreeCount,
        backpack.SlotCount,
        X4D.Icons:CreateString("/esoui/art/tooltips/icon_bag.dds"),
        bankColor,
        bankSlotCount - bankFreeCount,
        bankSlotCount,
        X4D.Icons:CreateString("/esoui/art/icons/guildranks/guild_rankicon_misc09_large.dds", 26,26))
    if (text == nil) then text = "" end
    _statusBarPanel:SetText(text)
end

local function InitializeUI()
    if (X4D.UI ~= nil) then
        _statusBarPanel = X4D.UI.StatusBar:CreatePanel("X4D_Bank_StatusBarPanel", UpdateStatusBarText, 7, 10)
    end
end

local function OnAddOnLoaded(eventCode, addonName)
    if (addonName ~= X4D_Bank.NAME) then
        return
    end
    local stopwatch = X4D.Stopwatch:StartNew()
--    X4D.Log:Debug({"OnAddonLoaded", eventCode, addonName}, X4D_Bank.NAME)
    X4D_Bank.Settings = X4D.Settings:Open(
        X4D_Bank.NAME .. "_SV",
        {
            SettingsAre = "Per-Character",
            AutoDepositDebounceSeconds = 900,
            ReserveCashOnHand = 0,
            AutoDepositFixedAmount = 0,
            AutoDepositPercentage = 1,
            StartNewStacks = true,
            DisplayMoneyUpdates = true,
            WithdrawItemPatterns =
            {
                -- items matching a "Withdraw" pattern will be withdrawn from the bank regardles of any itemtype settings
            },
            DepositItemPatterns =
            {
                -- items matching a "Deposit" pattern will be deposited into the bank regardless of any itemtype settings
                -- withdraw patterns take precedence over any deposit patterns
            },
            IgnoredItemPatterns =
            {
                -- items matching an "ignored" pattern will be left alone regardless of any other pattern or setting, it is considered a "safety list"
                "STOLEN",
                "item:44904:", -- ring of mara
				"item:44903:", -- pledge of mara
            }
        },
        2)

	-- we record banker locations, similar to how we record vendor locations, using the NPC module
    X4D_Bank.DB = X4D.NPCs

    InitializeSettingsUI()

    InitializeUI()

    EVENT_MANAGER:RegisterForEvent(X4D_Bank.NAME, EVENT_OPEN_BANK, OnOpenBank)
    EVENT_MANAGER:RegisterForEvent(X4D_Bank.NAME, EVENT_CLOSE_BANK, OnCloseBank)
    if (X4D.Loot == nil) then
        EVENT_MANAGER:RegisterForEvent(X4D_Bank.NAME, EVENT_MONEY_UPDATE, OnMoneyUpdate)
    end
    stopwatch:Stop()
    X4D_Bank.Took = stopwatch.ElapsedMilliseconds()
end

EVENT_MANAGER:RegisterForEvent(X4D_Bank.NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)