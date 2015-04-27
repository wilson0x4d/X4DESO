local X4D_Loot = LibStub:NewLibrary("X4D_Loot", 1011)
if (not X4D_Loot) then
	return
end
local X4D = LibStub("X4D")
X4D.Loot = X4D_Loot

X4D_Loot.NAME = "X4D_Loot"
X4D_Loot.VERSION = "1.11"

local _goldIcon = " " .. X4D.Icons:CreateString("EsoUI/Art/currency/currency_gold.dds")

X4D_Loot.Colors = {
	Gold = "|cFFD700",
	StackCount = "|cFFFFFF",
	BagSpaceLow = "|cFFd00b",
	BagSpaceFull = "|cAA0000",
	Subtext = "|c5C5C5C",
}

--region Money Reasons

-- TODO: relocate

X4D_Loot.MoneyUpdateReason = {
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
	return X4D_Loot.MoneyUpdateReason[reasonId] or { "Gained", "Lost" }
end

--endregion
--region Chat Callback

local function DefaultCallback(color, text)
	d(color .. text)
end

X4D_Loot.Callback = DefaultCallback

function X4D_Loot.RegisterCallback(self, callback)
	if (callback ~= nil) then
		X4D_Loot.Callback = callback
	else
		X4D_Loot.Callback = DefaultCallback
	end
end

function X4D_Loot.UnregisterCallback(self, callback)
	if (X4D_Loot.Callback == callback) then
		self:RegisterCallback(nil)
	end
end

local function InvokeCallbackSafe(color, text)
	local callback = X4D_Loot.Callback
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
--region Item Worth

local function GetWorthString(slot, stackCount)
    local worth = ""
    if (slot.SellPrice ~= nil and slot.SellPrice > 0) then 
        if (X4D.Loot.Settings:Get("DisplayLootWorth")) then
            worth = X4D.Colors.Subtext .. " worth " .. X4D.Colors.Gold .. (slot.SellPrice * stackCount) .. _goldIcon
        end
    end
    return worth
end

--endregion

--region Snapshots

local _snapshots

local function InitializeSnapshots()
    if (_snapshots == nil) then
	    local snapshots = {}
	    for bagId = 0, GetMaxBags() do
		    snapshots[bagId] = X4D.Bags:GetBag(bagId, true)
            --X4D.Bags:GetBag(bagId, true) -- NOTE: only calling this a second time to force the previously returned instance out of the cache (e.g. making a copy for future callers to use so 'our' version isn't tampered with by anyone else)
	    end
	    _snapshots = snapshots
    end
end

local function CheckBagForChange(bagId)
    local snapshot = _snapshots[bagId]
    local freeCount = 0
    if (snapshot == nil) then
		snapshot = X4D.Bags:GetBag(bagId, true)
        _snapshots[bagId] = snapshot
    else
        snapshot.SlotCount = GetBagSize(bagId)
		for slotIndex = 0, snapshot.SlotCount do
	        local current, previous = snapshot:PopulateSlot(slotIndex)
            if (current ~= nil and not current.IsEmpty) then
                if (current ~= previous and (previous == nil or current.InstanceId ~= previous.InstanceId)) then
                    -- slot contents are new
                    local stackChange = 0
                    if (current ~= nil and not current.IsEmpty) then
                        stackChange = current.StackCount
                    end
                    if (previous ~= nil and not previous.IsEmpty) then
                        stackChange = stackChange - previous.StackCount
                    end
		            if ((stackChange > 0) and (bagId == BAG_BACKPACK)) then
                        local message = zo_strformat("<<1>><<t:2>> <<3>> x<<4>><<5>>",
                            current.Item:GetItemIcon(), current.Item:GetItemLink(current.ItemOptions), X4D.Colors.StackCount, stackChange, GetWorthString(current, stackChange))
			            InvokeCallbackSafe(current.ItemColor, message)
		            end
                elseif (previous ~= nil and (current == previous or current.InstanceId == previous.InstanceId) and (current.StackCount ~= previous.StackCount)) then
                    -- slot contents are not new, but counts have changed
                    local stackChange = current.StackCount - previous.StackCount
		            if ((stackChange > 0) and (bagId == BAG_BACKPACK)) then
                        local message = zo_strformat("<<1>><<t:2>> <<3>> x<<4>><<5>>",
                            current.Item:GetItemIcon(), current.Item:GetItemLink(current.ItemOptions), X4D.Colors.StackCount, stackChange, GetWorthString(current, stackChange))
			            InvokeCallbackSafe(current.ItemColor, message)
		            end
                end
            end
            if (current == nil or current.IsEmpty) then
                freeCount = freeCount + 1
            end
        end
    end
    snapshot.FreeCount = freeCount
end

--TODO: not in use, and not tested.
--local function CheckSlotForChange(bagId, slotIndex)
--    local snapshot = _snapshots[bagId]
--    if (snapshot == nil) then
--	    snapshot = X4D.Bags:GetBag(bagId)
--        _snapshot[bagId] = snapshot
--    else
--	    local current, previous = snapshot:PopulateSlot(slotIndex)
--        if (current ~= nil and current ~= previous and current.InstanceId ~= previous.InstanceId) then
--            -- there are slot contents
--            if (previous == nil or previous.IsEmpty) then
--                -- slot was empty, now now is not free
--                snapshot.FreeCount = snapshot.FreeCount - 1
--            end
--            -- report details
--            local stackChange = 0
--            if (current ~= nil and not current.IsEmpty) then
--                stackChange = current.StackCount
--            end
--		    if ((stackChange > 0) and (bagId == BAG_BACKPACK)) then
--                local message = zo_strformat("<<1>><<t:2>> <<3>> x<<4>><<5>>",
--                    current.Item:GetItemIcon(), current.Item:GetItemLink(current.ItemOptions), X4D.Colors.StackCount, stackChange, GetWorthString(current, current.StackCount))
--			    InvokeCallbackSafe(current.ItemColor, message)
--		    end
--        elseif (current ~= nil and previous ~= nil and (current == previous or current.InstanceId == previous.InstanceId) and (current.StackCount ~= previous.StackCount)) then
--            -- slot contents are not new, but counts may have changed
--            local stackChange = current.StackCount - previous.StackCount
--		    if ((stackChange > 0) and (bagId == BAG_BACKPACK)) then
--                local message = zo_strformat("<<1>><<t:2>> <<3>> x<<4>><<5>>",
--                    current.Item:GetItemIcon(), current.Item:GetItemLink(current.ItemOptions), X4D.Colors.StackCount, stackChange, GetWorthString(current, current.StackCount))
--			    InvokeCallbackSafe(current.ItemColor, message)
--		    end
--        elseif ((current == nil or current.IsEmpty) and (previous ~= nil and not previous.IsEmpty)) then
--            -- slot was not empty, bus now is free
--            snapshot.FreeCount = snapshot.FreeCount + 1
--        end
--    end		
--end

--endregion
--region Quest Tools

local function AddQuestStepConditionInternal(quest, step, conditionIndex)
--    X4D.Debug:Information{"AddQuestStepConditionInternal",quest, step, conditionIndex}
	local conditionText, current, max, isFailCondition, isComplete, isCreditShared = GetJournalQuestConditionInfo(quest.Id, step.Id, conditionIndex)
	local iconFilename, stackCount, itemName = GetQuestItemInfo(quest.Id, step.Id, conditionIndex)
	if (iconFilename == nil or iconFilename:len() == 0) then
		iconFilename = "EsoUI/Art/Icons/icon_missing.dds"
	end
	if (itemName == nil or itemName:len() == 0) then
		itemName = conditionText
	end
	local condition = {
		Id = conditionIndex,
		ItemIcon = iconFilename,
		ItemLink = "[" .. itemName .. "]", -- TODO: can we link to quest? implement custom link handler?
		ItemColor = "|cFF6600", -- TODO: color by quest type?
		StackCount = stackCount,
		Current = current,
		Max = max,
		Text = conditionText,
		Complete = isComplete,
	}
	step.Conditions[conditionIndex] = condition
	return condition
end

local function AddQuestStepInternal(quest, stepIndex)
--    X4D.Debug:Information{"AddQuestStepInternal",quest, stepIndex}
	local stepText, visibility, stepType, trackerOverrideText, numConditions = GetJournalQuestStepInfo(quest.Id, stepIndex)
	local step = {
		Id = stepIndex,
		Text = stepText,
		Type = stepType,
		Conditions = {},
		ConditionCount = numConditions,
	}
	for conditionIndex = 0, numConditions do -- GetJournalQuestNumConditions(quest.Id, stepIndex) do
		AddQuestStepConditionInternal(quest, step, conditionIndex)
	end
	quest.Steps[stepIndex] = step
	return step
end

local function AddQuestToolInternal(quest, toolIndex)
	local iconFilename, stackCount, isUsable, toolName = GetQuestToolInfo(quest.Id, toolIndex)
--    X4D.Debug:Information{"AddQuestToolInternal",toolIndex,iconFilename, stackCount, isUsable, toolName}
	if (iconFilename == nil or iconFilename:len() == 0) then
		iconFilename = "EsoUI/Art/Icons/icon_missing.dds"
	end
	if (toolName == nil or toolName:len() == 0) then
		toolName = quest.CurrentStepText
	end
	local tool = {
		Id = toolIndex,
		ItemIcon = iconFilename,
		ItemLink = "[" .. toolName .. "]", -- TODO: can we link to quest? implement custom link handler?
		ItemColor = "|cFF6600", -- TODO: color by quest type?
		StackCount = stackCount,
		Usable = isUsable,
	}
	quest.Tools[toolIndex] = tool
	return tool
end

local _quests = {}

local function AddQuestInternal(questIndex)
    -- called when creating quests for updates (new quests)
--    X4D.Debug:Information{"AddQuestInternal",questIndex}
	local questName, backgroundText, activeStepText, activeStepType, activeStepTrackerOverrideText, isCompleted, tracked, questLevel, pushed, questType = GetJournalQuestInfo(questIndex)
	local quest = {
		Id = questIndex,
		Name = questName,
		Type = questType,
		Level = questLevel,
		Completed = isCompleted,
		QuestText = backgroundText,
		Steps = {},
		StepCount = 0,
		Tools = {},
		ToolCount = 0,
		CurrentStepText = activeStepText,
	}
	_quests[quest.Id] = quest
	return quest
end

local function PopulateQuestInternal(questIndex)
    -- called when populating quests for the first time
	local quest = AddQuestInternal(questIndex)
    quest.StepCount = GetJournalQuestNumSteps(questIndex)
    quest.ToolCount = GetQuestToolCount(questIndex)
	for stepIndex = 0, quest.StepCount do
		AddQuestStepInternal(quest, stepIndex)
	end
	for toolIndex = 0, quest.ToolCount do
		AddQuestToolInternal(quest, toolIndex)
	end
	_quests[quest.Id] = quest
	return quest
end

local function PopulateQuestsInternal()
--    X4D.Debug:Information{"PopulateQuestsInternal"}
	for questIndex = 0, GetNumJournalQuests() do
		PopulateQuestInternal(questIndex)
	end
end

local function UpdateQuestStepConditionInternal(quest, step, conditionIndex)
--    X4D.Debug:Information{"UpdateQuestStepConditionInternal",quest, step, conditionIndex}
	local wasChangeDetected = false
	local condition = step.Conditions[conditionIndex]
	if (condition == nil) then
		condition = AddQuestStepConditionInternal(quest, step, conditionIndex)
		wasChangeDetected = true
		if (condition ~= nil and condition.StackCount > 0) then
            local message = zo_strformat("<<1>><<t:2>> <<3>> x<<4>><<5>> (Quest Item)",
                X4D.Icons:CreateString(condition.ItemIcon), condition.ItemLink, X4D.Colors.StackCount, condition.StackCount, X4D_Loot.Colors.Subtext)
			InvokeCallbackSafe(condition.ItemColor, message)
		end
	else
		local iconFilename, stackCount, itemName = GetQuestItemInfo(quest.Id, step.Id, conditionIndex)
		if (iconFilename == nil or iconFilename:len() == 0) then
			iconFilename = "EsoUI/Art/Icons/icon_missing.dds"
		end
		condition.ItemIcon = iconFilename
		if (stackCount ~= condition.StackCount) then
        --X4D.Debug:Verbose{stackCount,condition.StackCount}
			local stackChange = stackCount - condition.StackCount
			if (stackChange > 0) then
				wasChangeDetected = true
                local message = zo_strformat("<<1>><<t:2>> <<3>> x<<4>><<5>> (Quest Item)",
                    X4D.Icons:CreateString(condition.ItemIcon), condition.ItemLink, X4D.Colors.StackCount, stackChange, X4D_Loot.Colors.Subtext)
			    InvokeCallbackSafe(condition.ItemColor, message)
			end
			condition.StackCount = stackCount
		end
	end
	return wasChangeDetected
end

local function UpdateQuestToolInternal(quest, toolIndex)
--    X4D.Debug:Information{"UpdateQuestToolInternal",quest, toolIndex}
	local wasChangeDetected = false

	local tool = quest.Tools[toolIndex]
	if (tool == nil) then
		tool = AddQuestToolInternal(quest, toolIndex)
		wasChangeDetected = true
		if (tool ~= nil and tool.StackCount > 0) then
			wasChangeDetected = true
            local message = zo_strformat("<<1>><<t:2>> <<3>> x<<4>><<5>> (Quest Item)",
                X4D.Icons:CreateString(tool.ItemIcon), tool.ItemLink, X4D.Colors.StackCount, stackChange, X4D_Loot.Colors.Subtext)
			InvokeCallbackSafe(tool.ItemColor, message)
		end
	else
		local iconFilename, stackCount, isUsable, toolName = GetQuestToolInfo(quest.Id, toolIndex)
		if (iconFilename == nil or iconFilename:len() == 0) then
			iconFilename = "EsoUI/Art/Icons/icon_missing.dds"
		end
		tool.ItemIcon = iconFilename
		if (tool.StackCount ~= stackCount) then
			local stackChange = stackCount - tool.StackCount
			if (stackChange > 0) then
				wasChangeDetected = true
                local message = zo_strformat("<<1>><<t:2>> <<3>> x<<4>><<5>> (Quest Item)",
                    X4D.Icons:CreateString(tool.ItemIcon), tool.ItemLink, X4D.Colors.StackCount, stackChange, X4D_Loot.Colors.Subtext)
			    InvokeCallbackSafe(tool.ItemColor, message)
			end
			tool.StackCount = stackCount
		end
	end

	return wasChangeDetected
end

local function UpdateQuestStepInternal(quest, stepIndex)
--    X4D.Debug:Information{"UpdateQuestStepInternal",quest, stepIndex}
	local wasChangeDetected = false
	local step = quest.Steps[stepIndex]
	if (step == nil) then
		AddQuestStepInternal(quest, stepIndex)
		wasChangeDetected = true
	else
		local stepText, visibility, stepType, trackerOverrideText, numConditions = GetJournalQuestStepInfo(quest.Id, stepIndex)
		if (step.ConditionCount ~= numConditions) then
			wasChangeDetected = true
			step.Conditions = {}
			step.ConditionCount = numConditions
		end
		for conditionIndex = 0, step.ConditionCount do
			if (UpdateQuestStepConditionInternal(quest, step, conditionIndex)) then
				wasChangeDetected = true
			end
		end
	end
	return wasChangeDetected
end

local function UpdateQuestInternal(questIndex)
--    X4D.Debug:Information{"UpdateQuestInternal",questIndex}
	local wasChangeDetected = false
	local quest = _quests[questIndex]
	if (quest == nil) then
		quest = AddQuestInternal(questIndex)
		wasChangeDetected = true
	end
	local numSteps = GetJournalQuestNumSteps(questIndex)
	local numTools = GetQuestToolCount(questIndex)
	if (quest.StepCount ~= numSteps) then
		wasChangeDetected = true
		quest.Steps = {}
		quest.StepCount = numSteps
	end
	if (quest.ToolCount ~= numTools) then
		wasChangeDetected = true
		quest.Tools = {}
		quest.ToolCount = numTools
	end
	for stepIndex = 0, quest.StepCount do
		if (UpdateQuestStepInternal(quest, stepIndex)) then
			wasChangeDetected = true
		end
	end
	for toolIndex = 0, quest.ToolCount do
		if (UpdateQuestToolInternal(quest, toolIndex)) then
			wasChangeDetected = true
		end
	end
	return wasChangeDetected
end

local function UpdateQuestsInternal()
--    X4D.Debug:Information{"UpdateQuestsInternal"}
	local wasChangeDetected = false
	for questIndex = 0, GetNumJournalQuests() do
		if (UpdateQuestInternal(questIndex)) then
			wasChangeDetected = true
		end
	end
	return wasChangeDetected
end

function X4D_Loot.OnQuestAdded(journalIndex, questName, objectiveName)
	UpdateQuestsInternal()
end

function X4D_Loot.OnQuestToolUpdated(journalIndex, questName)
	UpdateQuestsInternal()
end

--endregion Quest Tools

--region Bag Space Checking

local _nextInventoryCheckTime = 0
local _wasLow = false
local _wasFull = false

local function CheckInventorySpaceInternal()
	if (not CheckInventorySpaceSilently(10)) then
		if (not CheckInventorySpaceSilently(BAG_BACKPACK)) then
			if (_wasLow or _nextInventoryCheckTime <= GetGameTimeMilliseconds()) then
				_nextInventoryCheckTime = GetGameTimeMilliseconds() + 20000
				_wasLow = false
				_wasFull = true
				InvokeCallbackSafe(X4D_Loot.Colors.BagSpaceFull, "Out of Bag Space")
                --TODO: play sound
			end
		else
			if (_wasFull or _nextInventoryCheckTime <= GetGameTimeMilliseconds()) then
				_nextInventoryCheckTime = GetGameTimeMilliseconds() + 20000
				InvokeCallbackSafe(X4D_Loot.Colors.BagSpaceLow, "Low Bag Space")
                --TODO: play sound
				_wasLow = true
				_wasFull = false
			end
		end
	else
		_wasLow = false
		_wasFull = false
	end

end

function X4D_Loot.OnLootReceived(eventCode, receivedBy, objectName, stackCount, soundCategory, lootType, lootedBySelf)
    if (not lootedBySelf) then
        -- TODO: find a way to lookup item details without interrogating Bag API
        if (X4D.Loot.Settings:Get("DisplayPartyLoot")) then
            local receivingPlayer = X4D.Players:GetPlayer(receivedBy)
            local message = zo_strformat("<<1>>: <<t:2>> <<3>> x<<4>>",
                receivingPlayer, objectName, X4D.Colors.StackCount, stackCount)                
			InvokeCallbackSafe(X4D.Colors.XP, message) -- TODO: fix color to use item color or 'group chat' color
        end
    else
	    if (lootType == LOOT_TYPE_ITEM) then
            CheckBagForChange(BAG_BACKPACK)
			CheckInventorySpaceInternal()
	    elseif (lootType == LOOT_TYPE_QUEST_ITEM) then
		    if (UpdateQuestsInternal()) then
			    -- NOP
		    end
	    end
    end
end

function X4D_Loot.OnInventorySingleSlotUpdate(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason)
    if(bagId ~= BAG_BACKPACK or updateReason == INVENTORY_UPDATE_REASON_DURABILITY_CHANGE) then
    	return
    end
    --NOTE: this causes problems with Bank withdrawals, possibly other events
    --CheckSlotForChange(bagId, slotIndex)
end

--region Money Update

local function formatnum(n)
	local left, num, right = string.match(n,"^([^%d]*%d)(%d*)(.-)$")
	return left .. (num:reverse():gsub("(%d%d%d)","%1,"):reverse()) .. right
end

function X4D_Loot.OnMoneyUpdate(eventId, newMoney, oldMoney, reasonId)
    --d({eventId, newMoney, oldMoney, reasonId})
    if ((reasonId == 1 or reasonId == 60) and (X4D.Vendors ~= nil)) then
        -- leave display of income/expenses to Vendors Addon when present
        return
    end
    if (not X4D.Loot.Settings:Get("DisplayMoneyUpdates")) then
        return
    end
	local reason = GetMoneyReason(reasonId)
	local amount = newMoney - oldMoney
	if (amount >= 0) then
		InvokeCallbackSafe(X4D_Loot.Colors.Gold, string.format("%s %s%s %s  (%s total)", reason[1], formatnum(amount), _goldIcon, X4D_Loot.Colors.Subtext, formatnum(newMoney)))
	else
		InvokeCallbackSafe(X4D_Loot.Colors.Gold, string.format("%s %s%s %s  (%s remaining)", reason[2], formatnum(math.abs(amount)), _goldIcon, X4D_Loot.Colors.Subtext, formatnum(newMoney)))
	end
end

--endregion

local function InitializeSettingsUI()
	local LAM = LibStub("LibAddonMenu-2.0")
	local cplId = LAM:RegisterAddonPanel("X4D_LOOT_CPL", {
        type = "panel",
        name = "X4D |cFFAE19Loot",
    })

    local panelControls = { }

    table.insert(panelControls, {
            type = "checkbox",
            name = "Display Money Updates", 
            tooltip = "When enabled, money updates are displayed in the Chat Window.", 
            getFunc = function() 
                if (X4D.Bank ~= nil) then
                    return X4D.Bank.Settings:Get("DisplayMoneyUpdates")
                else
                    return X4D.Loot.Settings:Get("DisplayMoneyUpdates")
                end
            end,
            setFunc = function()
                X4D.Loot.Settings:Set("DisplayMoneyUpdates", not X4D.Loot.Settings:Get("DisplayMoneyUpdates")) 
                if (X4D.Bank ~= nil) then
                    X4D.Bank.Settings:Set("DisplayMoneyUpdates", X4D.Loot.Settings:Get("DisplayMoneyUpdates")) 
                end
            end,
        })

    table.insert(panelControls, {
            type = "checkbox",
            name = "Display Loot Worth", 
            tooltip = "When enabled, and when available, loot worth is displayed.", 
            getFunc = function() 
                return X4D.Loot.Settings:Get("DisplayLootWorth")
            end,
            setFunc = function()
                X4D.Loot.Settings:Set("DisplayLootWorth", not X4D.Loot.Settings:Get("DisplayLootWorth"))
            end,
        })

    table.insert(panelControls, {
            type = "checkbox",
            name = "[BETA] Display Party Loot", 
            tooltip = "When enabled, loot received by others is displayed in the Chat Window.", 
            getFunc = function() 
                return X4D.Loot.Settings:Get("DisplayPartyLoot")
            end,
            setFunc = function()
                X4D.Loot.Settings:Set("DisplayPartyLoot", not X4D.Loot.Settings:Get("DisplayPartyLoot"))
            end,
        })

    LAM:RegisterOptionControls(
        "X4D_LOOT_CPL",
        panelControls
    )
end


local function OnCraftCompleted(...)
    CheckBagForChange(BAG_BACKPACK)
    CheckInventorySpaceInternal()
end

function X4D_Loot.Register()
    -- TODO: EVENT_ALLIANCE_POINT_UPDATE
	EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_LOOT_RECEIVED, X4D_Loot.OnLootReceived)
	EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, X4D_Loot.OnInventorySingleSlotUpdate)
	EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_MONEY_UPDATE, X4D_Loot.OnMoneyUpdate)
	EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_QUEST_ADDED, X4D_Loot.OnQuestAdded)
	EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_QUEST_TOOL_UPDATED, X4D_Loot.OnQuestToolUpdated)
	EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_CRAFT_COMPLETED, OnCraftCompleted)
end

function X4D_Loot.Unregister()
end

local function OnPlayerActivated()
	InitializeSnapshots()
	PopulateQuestsInternal()
end

local function OnAddOnLoaded(event, addonName)
	if (addonName ~= X4D_Loot.NAME) then
		return
	end	

	X4D_Loot.Settings = X4D.Settings(
		X4D_Loot.NAME .. "_SV",
		{
            SettingsAre = "Account-Wide",
            DisplayMoneyUpdates = true,
			DisplayPartyLoot = false,
			DisplayLootWorth = true,
        }, 
        2)

    InitializeSettingsUI()

	X4D_Loot.Register()
end

EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
