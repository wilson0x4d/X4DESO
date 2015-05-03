local X4D_Bank = LibStub:NewLibrary("X4D_Bank", 1019)
if (not X4D_Bank) then
    return
end
local X4D = LibStub("X4D")
X4D.Bank = X4D_Bank

X4D_Bank.NAME = "X4D_Bank"
X4D_Bank.VERSION = "1.19"

local constLeaveAlone = "Leave Alone"
local constDeposit = X4D.Colors.Deposit .. "Deposit"
local constWithdraw = X4D.Colors.Withdraw .. "Withdraw"

local _itemTypeChoices = {
    constLeaveAlone,
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

local _nextAutoDepositTime = 0

--region Chat Callback

local function DefaultEmitCallback(color, text)
    d(color .. text)
end

X4D_Bank.EmitCallback = DefaultEmitCallback

function X4D_Bank.RegisterEmitCallback(self, callback)
    if (callback ~= nil) then
        X4D_Bank.EmitCallback = callback
    else
        X4D_Bank.EmitCallback = DefaultEmitCallback
    end
end

function X4D_Bank.UnregisterEmitCallback(self, callback)
    if (X4D_Bank.EmitCallback == callback) then
        self:RegisterEmitCallback(nil)
    end
end

local function InvokeChatCallback(color, text)
    local callback = X4D_Bank.EmitCallback
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
                end )) then
                InvokeChatCallback(X4D.Colors.SYSTEM, "(BANK) Bad Item Pattern: |cFF7777" .. pattern)
            end
            if (isIgnored) then
                return true
            end
        end
    end
    return false
end

local function TryGetBag(bagId)
    return X4D.Bags:GetBag(bagId, true)
end

local function TryDepositFixedAmount()
    local availableAmount = GetCurrentMoney() - X4D_Bank.Settings:Get("AutoDepositReserve")
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
    if (not X4D_Bank.Settings:Get("AutoWithdrawReserve")) then
        return
    end
    local carriedAmount = GetCurrentMoney()
    local deficit = X4D_Bank.Settings:Get("AutoDepositReserve") - carriedAmount
    if (deficit > 0) then
        if (GetBankedMoney() > deficit) then
            WithdrawMoneyFromBank(deficit)
        end
    end
end

local function ShouldDepositItem(slot, itemTypeDirections)
    return (not IsSlotIgnoredItem(slot)) and (itemTypeDirections[slot.Item.ItemType] == 1)
end

local function ShouldWithdrawItem(slot, itemTypeDirections)
    return (not IsSlotIgnoredItem(slot)) and (itemTypeDirections[slot.Item.ItemType] == 2)
end

local function CreateSettingsName(itemType)
    return itemType.Id
end

local function GetItemTypeActions()
    local itemTypeDirections = { }
    for _,groupName in pairs(X4D.Items.ItemGroups) do
        for _,itemType in pairs(X4D.Items.ItemTypes) do
            if (itemType.Group == groupName) then
                local dropdownName = CreateSettingsName(itemType)
                local direction = X4D_Bank.Settings:Get(dropdownName) or 0
                itemTypeDirections[itemType.Id] = direction
            end
        end
    end
    return itemTypeDirections
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
            X4D.Log:Error{"TryCombinePartialStacks", "INVALID SLOT INDEX " .. i}
        else
            for j = i + 1, (bag.PartialStackCount - 1) do
                local rval = bag.PartialStacks[j]
                if (rval ~= nil) then
                    local lslot = bag.Slots[lval.Id]
                    local rslot = bag.Slots[rval.Id]
                    if ((lval.Id ~= rval.Id) and(lval.ItemLevel == rval.ItemLevel) and(lval.ItemQuality == rval.ItemQuality) and(lval.Item.Name == rval.Item.Name) and(rval.StackCount ~= 0) and(lval.StackCount ~= 0) and lslot ~= nil and rslot ~= nil and(not lslot.IsEmpty) and(not rslot.IsEmpty) and(lslot.IsStolen == rslot.IsStolen)) then
                        table.insert(combines, { [1] = lval, [2] = rval })
                        combineCount = combineCount + 1
                        break
                    end
                end
            end
        end
    end
    for i = 0, (combineCount - 1) do
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
            local message = zo_strformat("<<1>> <<2>><<t:3>> <<4>>x<<5>>",
                "Restacked", lval.Item:GetItemIcon(), lval.Item:GetItemLink(lval.ItemOptions), X4D.Colors.StackCount, countToMove)
			InvokeChatCallback(lval.ItemColor, message)
        end
    end
    if (combineCount > 0 and depth > 0) then
        TryCombinePartialStacks(bag, depth - 1)
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
        elseif ((sourceSlot.ItemLevel == slot.ItemLevel) and(sourceSlot.ItemQuality == slot.ItemQuality) and(sourceSlot.Item.Name == slot.Item.Name) and(slot.StackCount < slot.Item.StackMax) and(sourceSlot.IsStolen == slot.IsStolen)) then
            table.insert(partials, slot)
            remaining = slot.Item.StackMax - slot.StackCount
            if (remaining <= 0) then
                break
            end
        end
    end
    return partials, empties
end

local function TryMoveSourceSlotToTargetBag(sourceBag, sourceSlot, targetBag, directionText)
    local itemIcon = sourceSlot.Item:GetItemIcon()
    local itemLink = sourceSlot.Item:GetItemLink(sourceSlot.ItemOptions)
    local countRemaining = 0
    local totalMoved = 0
    local usedEmptySlot = false
    local partialSlots, emptySlots = FindTargetSlots(sourceSlot, targetBag)
    --X4D.Log:Verbose{partialSlots, emptySlots}
    for _, targetSlot in pairs(partialSlots) do
        local countToMove = targetSlot.Item.StackMax - targetSlot.StackCount
        if (countToMove > sourceSlot.StackCount) then
            countToMove = sourceSlot.StackCount
        end
        CallSecureProtected("PickupInventoryItem", sourceBag.Id, sourceSlot.Id, countToMove)
        CallSecureProtected("PlaceInInventory", targetBag.Id, targetSlot.Id)
        X4D.Log:Verbose{"TryMove(topartial)", sourceBag.Id, sourceSlot.Id, countToMove, targetBag.Id, targetSlot.Id}
        totalMoved = totalMoved + countToMove
        sourceSlot.StackCount = sourceSlot.StackCount - countToMove
        if (sourceSlot.StackCount <= 0) then
            sourceSlot.IsEmpty = true
            break
        end
    end
    if (not sourceSlot.IsEmpty) then
        for _, targetSlot in pairs(emptySlots) do
            if (targetSlot.IsEmpty) then
                local countToMove = sourceSlot.StackCount
                CallSecureProtected("PickupInventoryItem", sourceBag.Id, sourceSlot.Id, countToMove)
                CallSecureProtected("PlaceInInventory", targetBag.Id, targetSlot.Id)
                X4D.Log:Verbose{"TryMove(toempty)", sourceBag.Id, sourceSlot.Id, countToMove, targetBag.Id, targetSlot.Id}
                targetSlot.IsEmpty = false
                usedEmptySlot = true
                totalMoved = totalMoved + countToMove
                sourceSlot.StackCount = sourceSlot.StackCount - countToMove
                if (sourceSlot.StackCount <= 0) then
                    sourceSlot.IsEmpty = true
                    break
                end
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

local function TryDepositsAndWithdrawals()
    local totalDeposits = 0
    local totalWithdrawals = 0

    local inventoryState = TryGetBag(BAG_BACKPACK)
    local bankState = TryGetBag(BAG_BANK)

    TryCombinePartialStacks(inventoryState)
    TryCombinePartialStacks(bankState)

    ClearCursor()

    local itemTypeDirections = GetItemTypeActions()
    local pendingDeposits = { }
    local pendingDepositCount = 0
    local pendingWithdrawals = { }
    local pendingWithdrawalCount = 0

    local backpackFreeCount = 0
    local bankFreeCount = 0

    for _, slot in pairs(inventoryState.Slots) do
        if (slot ~= nil and not slot.IsEmpty) then
            if (ShouldDepositItem(slot, itemTypeDirections)) then
                pendingDepositCount = pendingDepositCount + 1
                table.insert(pendingDeposits, slot)
            end
        else
            backpackFreeCount = backpackFreeCount + 1
        end
    end

    for _, slot in pairs(bankState.Slots) do
        if (slot ~= nil and not slot.IsEmpty) then
            if (ShouldWithdrawItem(slot, itemTypeDirections)) then
                pendingWithdrawalCount = pendingWithdrawalCount + 1
                table.insert(pendingWithdrawals, slot)
            end
        else
            bankFreeCount = bankFreeCount + 1
        end
    end

    local shouldProcessBags = (pendingDepositCount > 0 or pendingWithdrawalCount > 0)
    local sourceBag
    local targetBag
    while (shouldProcessBags) do
        shouldProcessBags = false
        sourceBag = inventoryState
        targetBag = bankState
        for _,sourceSlot in pairs(pendingDeposits) do
            if (not sourceSlot.IsEmpty) then
                local countMoved, usedEmptySlot = TryMoveSourceSlotToTargetBag(sourceBag, sourceSlot, targetBag, "Deposited")
                while (countMoved > 0 and not sourceSlot.IsEmpty) do
                    totalDeposits = totalDeposits + countMoved
                    countMoved, usedEmptySlot = TryMoveSourceSlotToTargetBag(sourceBag, sourceSlot, targetBag, "Deposited")
                end
                totalDeposits = totalDeposits + countMoved
                if (usedEmptySlot) then
                    bankFreeCount = bankFreeCount - 1
                    if (pendingWithdrawalCount > 0) then
                        shouldProcessBags = true
                    end
                end
                if (sourceSlot.IsEmpty) then
                    backpackFreeCount = backpackFreeCount + 1
                    pendingDepositCount = pendingDepositCount - 1
                end
            end
        end
        sourceBag = bankState
        targetBag = inventoryState
        for _,sourceSlot in pairs(pendingWithdrawals) do
            if (not sourceSlot.IsEmpty) then
                local countMoved, usedEmptySlot = TryMoveSourceSlotToTargetBag(sourceBag, sourceSlot, targetBag, "Withdrew")
                while (countMoved > 0 and not sourceSlot.IsEmpty) do
                    totalWithdrawals = totalWithdrawals + countMoved
                    countMoved, usedEmptySlot = TryMoveSourceSlotToTargetBag(sourceBag, sourceSlot, targetBag, "Withdrew")
                end
                totalWithdrawals = totalWithdrawals + countMoved
                if (usedEmptySlot) then
                    backpackFreeCount = backpackFreeCount - 1
                    if (pendingDepositCount > 0) then
                        shouldProcessBags = true
                    end
                end
                if (sourceSlot.IsEmpty) then
                    bankFreeCount = bankFreeCount + 1
                    pendingWithdrawalCount = pendingWithdrawalCount - 1
                end
            end
        end
    end

    inventoryState.FreeCount = backpackFreeCount
    bankState.FreeCount = bankFreeCount

    local message
    local inventoryFreeColor = X4D.Colors.Gold
    if (inventoryState.FreeCount < (inventoryState.SlotCount * 0.2)) then
        inventoryFreeColor = X4D.Colors.Red
    end
    local bankFreeColor = X4D.Colors.Gold
    if (bankState.FreeCount < (bankState.SlotCount * 0.2)) then
        bankFreeColor = X4D.Colors.Red
    end
    if (totalDeposits > 0 or totalWithdrawals > 0) then
        message = string.format("Bank Deposits: %s, Withdrawals: %s, Bank: %s/%s free, Backpack: %s/%s free",
            X4D.Colors.Gold .. totalDeposits .. X4D.Colors.X4D, X4D.Colors.Gold .. totalWithdrawals .. X4D.Colors.X4D, 
            bankFreeColor ..  bankState.FreeCount .. X4D.Colors.X4D, bankState.SlotCount,
            inventoryFreeColor .. inventoryState.FreeCount .. X4D.Colors.X4D, inventoryState.SlotCount)
    else
        message = string.format("Bank: %s/%s free, Backpack: %s/%s free",
            bankFreeColor ..  bankState.FreeCount .. X4D.Colors.X4D, bankState.SlotCount,
            inventoryFreeColor .. inventoryState.FreeCount .. X4D.Colors.X4D, inventoryState.SlotCount)
    end
    InvokeChatCallback(X4D.Colors.X4D, message)
end

local function OnOpenBank(eventCode)
    if (_nextAutoDepositTime <= GetGameTimeMilliseconds()) then
        _nextAutoDepositTime = GetGameTimeMilliseconds() + (X4D_Bank.Settings:Get("AutoDepositDowntime") * 1000)
        local availableAmount = TryDepositFixedAmount()
        TryDepositPercentage(availableAmount)
    end
    TryWithdrawReserveAmount()
    TryDepositsAndWithdrawals()
end

local function OnCloseBank()
    -- NOP
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
            name = "Reserve Amount",
            tooltip = "If non-zero, the specified amount of carried gold will never be auto-deposited.",
            min = 0,
            max = 10000,
            step = 100,
            getFunc = function() return X4D_Bank.Settings:Get("AutoDepositReserve") end,
            setFunc = function(v) X4D_Bank.Settings:Set("AutoDepositReserve", tonumber(tostring(v))) end,
        },
        [4] =
        {
            type = "checkbox",
            name = "Auto-Withdraw Reserve",
            tooltip = "When enabled, if you are carrying less than the specified reserve amount the difference will be withdrawn from the bank.",
            getFunc = function() return X4D_Bank.Settings:Get("AutoWithdrawReserve") end,
            setFunc = function() X4D_Bank.Settings:Set("AutoWithdrawReserve", not X4D_Bank.Settings:Get("AutoWithdrawReserve")) end,
        },
        [5] =
        {
            type = "slider",
            name = "Auto-Deposit Fixed Amount",
            tooltip = "If non-zero, will auto-deposit up to the configured amount when accessing the bank.",
            min = 0,
            max = 1000,
            step = 100,
            getFunc = function() return X4D_Bank.Settings:Get("AutoDepositFixedAmount") end,
            setFunc = function(v) X4D_Bank.Settings:Set("AutoDepositFixedAmount", tonumber(tostring(v))) end,
        },
        [6] =
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
        [7] =
        {
            type = "slider",
            name = "Auto-Deposit Down-Time",
            tooltip = "If non-zero, will wait specified time (in seconds) between bank interactions before auto-depositing again.",
            min = 0,
            max = 3600,
            step = 30,
            getFunc = function() return X4D_Bank.Settings:Get("AutoDepositDowntime") end,
            setFunc = function(v) X4D_Bank.Settings:Set("AutoDepositDowntime", tonumber(tostring(v))) end,
        },
        [8] =
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
        [9] =
        {
            type = "header",
            name = "Item Deposits and Withdrawals",
        },
    }

    -- LAM:AddCheckbox(cplId,
    -- "X4D_BANK_CHECK_START_NEW_STACKS", "Start New Stacks?",
    -- "When enabled, new stacks of items will be created in your bank after partial stacks are filled.",
    -- function() return X4D_Bank.Settings:Get("StartNewStacks") end,
    -- function() X4D_Bank.Settings:Set("StartNewStacks", not X4D_Bank.Settings:Get("StartNewStacks")) end)

    table.insert(panelControls, {
        type = "editbox",
        name = "Item Ignore List",
        tooltip = "Line-delimited list of items to ignore using 'lua patterns'. Ignored items will not be withdrawn, deposited nor restacked.\n|cFFFFFFSpecial patterns exist, such as: STOLEN, item qualities like TRASH, NORMAL, MAGIC, ARCANE, ARTIFACT, LEGENDARY, item types like BLACKSMITHING, CLOTHIER, MATERIALS, etc",
        isMultiline = true,
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
                        local v = X4D_Bank.Settings:Get(dropdownName) or 0
                        if (v == 1) then
                            return constDeposit
                        elseif (v == 2) then
                            return constWithdraw
                        else
                            return constLeaveAlone
                        end
                    end,
                    setFunc = function(v)
                        if (v == constDeposit) then
                            v = 1
                        elseif (v == constWithdraw) then
                            v = 2
                        else
                            v = 0
                        end
                        X4D_Bank.Settings:Set(dropdownName, v)
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
        name = "Item Type Settings",
        tooltip = "Use this to reset ALL item type settings to a specific value. This only exists to make reconfiguration a little less tedious.",
        choices = _itemTypeChoices,
        getFunc = function() 
            local v = 0
            if (v == 1) then
                return constDeposit
            elseif (v == 2) then
                return constWithdraw
            else
                return constLeaveAlone
            end
        end,
        setFunc = function(v)
            if (v == constDeposit) then
                v = 1
            elseif (v == constWithdraw) then
                v = 2
            else
                v = 0
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

    LAM:RegisterOptionControls(
        "X4D_BANK_CPL",
        panelControls
    )

end

local function formatnum(n)
    local left, num, right = string.match(n, "^([^%d]*%d)(%d*)(.-)$")
    return left ..(num:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. right
end

local _moneyUpdateReason = {
    [0] = { "Looted", "Stored" },
    [1] = { "Earned", "Spent" },
    [2] = { "Received", "Sent" },
    [4] = { "Gained", "Lost" },
    [5] = { "Earned", "Spent" },
    [19] = { "Gained", "Spent" },
    [28] = { "Gained", "Spent" },
    [29] = { "Gained", "Spent" },
    [42] = { "Withdrew", "Deposited" },
    [43] = { "Withdrew", "Deposited" },
}	

local function GetMoneyReason(reasonId)
    return _moneyUpdateReason[reasonId] or { "Gained", "Lost" }
end

local _goldIcon = " " .. X4D.Icons:CreateString("EsoUI/Art/currency/currency_gold.dds")

local function OnMoneyUpdate(eventId, newMoney, oldMoney, reasonId)
    if (not X4D.Bank.Settings:Get("DisplayMoneyUpdates")) then
        return
    end
    local reason = GetMoneyReason(reasonId)
    local amount = newMoney - oldMoney
    if (amount >= 0) then
        InvokeChatCallback(X4D_Bank.Colors.Gold, string.format("%s %s%s %s  (%s on-hand)", reason[1], formatnum(amount), _goldIcon, X4D_Bank.Colors.Subtext, formatnum(newMoney)))
    else
        InvokeChatCallback(X4D_Bank.Colors.Gold, string.format("%s %s%s %s  (%s on-hand)", reason[2], formatnum(math.abs(amount)), _goldIcon, X4D_Bank.Colors.Subtext, formatnum(newMoney)))
    end
end

local function OnAddOnLoaded(eventCode, addonName)
    if (addonName ~= X4D_Bank.NAME) then
        return
    end

    X4D_Bank.Settings = X4D.Settings(
        X4D_Bank.NAME .. "_SV",
        {
            SettingsAre = "Per-Character",
            AutoDepositDowntime = 300,
            AutoDepositReserve = 500,
            AutoDepositFixedAmount = 100,
            AutoDepositPercentage = 1,
            StartNewStacks = true,
            AutoWithdrawReserve = true,
            DisplayMoneyUpdates = true,
            IgnoredItemPatterns =
            {
                "STOLEN",
            }
        },
        2)

    InitializeSettingsUI()

    EVENT_MANAGER:RegisterForEvent(X4D_Bank.NAME, EVENT_OPEN_BANK, OnOpenBank)
    EVENT_MANAGER:RegisterForEvent(X4D_Bank.NAME, EVENT_CLOSE_BANK, OnCloseBank)
    if (X4D.Loot == nil) then
        EVENT_MANAGER:RegisterForEvent(X4D_Bank.NAME, EVENT_MONEY_UPDATE, OnMoneyUpdate)
    end
end

EVENT_MANAGER:RegisterForEvent(X4D_Bank.NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)