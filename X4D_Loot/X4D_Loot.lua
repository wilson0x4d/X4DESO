local X4D_Loot = LibStub:NewLibrary('X4D_Loot', 1.6)
if (not X4D_Loot) then
	return
end

X4D_Loot.NAME = 'X4D_Loot'
X4D_Loot.VERSION = 1.6

X4D_Loot.Settings = {}
X4D_Loot.Settings.SavedVars = {}
X4D_Loot.Settings.Defaults = {
	None = 'true',
}

X4D_Loot.Colors = {
	Gold = '|cFFD700',
	StackCount = '|cFFFFFF',
	BagSpaceLow = '|cFFd00b',
	BagSpaceFull = '|cAA0000',
	Subtext = '|c5C5C5C',
}

X4D_Loot.MoneyUpdateReason = {
	[0] = { 'Looted', 'Stored' },
	[1] = { 'Earned', 'Spent' },
	[2] = { 'Received', 'Sent' },
	[4] = { 'Gained', 'Lost' },
	[5] = { 'Earned', 'Spent' },
	[19] = { 'Gained', 'Spent' },
	[28] = { 'Gained', 'Spent' },
	[29] = { 'Gained', 'Spent' },
	[42] = { 'Withdrew', 'Deposited' },
	[43] = { 'Withdrew', 'Deposited' },
}	

local function GetMoneyReason(reasonId)
	return X4D_Loot.MoneyUpdateReason[reasonId] or { 'gained', 'lost' }
end

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
		color = '|cFF0000'
	end
	if (color:len() < 8) then
		color = '|cFF0000'
	end
	if (callback ~= nil) then	
		callback(color, text)
	end
end

local function CreateIcon(filename, width, height)	
	-- example: /zgoo EsoStrings[SI_BANK_GOLD_AMOUNT_BANKED]:gsub('%|', '!')
	-- gladly accepting gold donations in-game, thanks.
	return string.format('|t%u:%u:%s|t', width or 16, height or 16, filename)
end

local function GetItemLinkInternal(bagId, slotId)
	local itemLink = GetItemLink(bagId, slotId, LINK_STYLE_BRACKETS):gsub('(%[%l)', function (i) return i:upper() end):gsub('(%s%l)', function (i) return i:upper() end):gsub('%^[^%]]*', '')
	local itemColor = ''
	if (itemLink and itemLink:len() > 8) then
		itemColor = '|c' .. itemLink:sub(3, 8)	
	end
	return itemLink, itemColor
end

X4D_Loot.Bags = {}
X4D_Loot.Quests = {}

local function GetBagInternal(bagId)
	return X4D_Loot.Bags[bagId]
end

local function GetQuestInternal(questName)
	return X4D_Loot.Quests[questIndex]
end

--== Populate Bags ==--

local function AddBagSlotInternal(bag, slotIndex)
	local stack, maxStack = GetSlotStackSize(bag.Id, slotIndex)
	local itemLink, itemColor = GetItemLinkInternal(bag.Id, slotIndex)	
	local iconFilename, itemStack, sellPrice, meetsUsageRequirement, locked, equipType, itemStyle, quality = GetItemInfo(bag.Id, slotIndex)
	if (iconFilename == nil or iconFilename:len() == 0) then
		iconFilename = 'EsoUI/Art/Icons/icon_missing.dds'
	end
	local slot = {
		Id = slotIndex,
		ItemLink = itemLink,
		ItemColor = itemColor or '|cFF0000',
		ItemIcon = iconFilename,
		ItemId = GetItemInstanceId(bag.Id, slotIndex) or 0,
		Stack = stack,
		MaxStack = maxStack,
	}
	slot.IsEmpty = slot.ItemId == 0
	bag.Slots[slot.Id] = slot
	return slot
end

local function AddBagInternal(bags, bagId)
	local bagIcon, bagSlots = GetBagInfo(bagId)
	if (bagIcon == nil or bagIcon:len() == 0) then
		bagIcon = 'EsoUI/Art/Icons/icon_missing.dds'
	end
	local bag = {
		Id = bagId,
		Icon = bagIcon,
		Slots = {},
	}
	for slotId = 0, bagSlots do
		AddBagSlotInternal(bag, slotId)
	end
	bags[bag.Id] = bag
	return bag
end

local function PopulateBagsInternal()
	local bags = {}
	for bagId = 0, GetMaxBags() do
		AddBagInternal(bags, bagId)
	end
	X4D_Loot.Bags = bags
end

--== Update Bags ==--

local function UpdateBagSlotInternal(bag, slotId)
	local wasChangeDetected = false
	local slot = bag.Slots[slotId]
	if (slot == nil) then
		slot = AddBagSlotInternal(bag, slotId)
		if (bag.Id == 1) then
			wasChangeDetected = true
			if (slot.ItemColor ~= nil and slot.ItemColor:len() == 8 and slot.ItemLink ~= nil and slot.ItemLink:len() > 0) then
				InvokeCallbackSafe(slot.ItemColor, CreateIcon(slot.ItemIcon) .. slot.ItemLink .. X4D_Loot.Colors.StackCount .. ' x' .. slot.Stack)
			end
		end
	else	
		local itemId = GetItemInstanceId(bag.Id, slotId) or 0
		if (itemId ~= slot.ItemId) then
			slot.ItemId = itemId
			slot.IsEmpty = slot.ItemId == 0			
			if (itemId == 0) then
				slot.Stack = 0
				slot.MaxStack = 0
			else
				local stack, maxStack = GetSlotStackSize(bag.Id, slotId)
				slot.Stack = stack
				slot.MaxStack = maxStack
			end
			if (not slot.IsEmpty) then
				local itemLink, itemColor = GetItemLinkInternal(bag.Id, slotId)
				local iconFilename, itemStack, sellPrice, meetsUsageRequirement, locked, equipType, itemStyle, quality = GetItemInfo(bag.Id, slotId)
				if (iconFilename == nil or iconFilename:len() == 0) then
					iconFilename = 'EsoUI/Art/Icons/icon_missing.dds'
				end
				slot.ItemLink = itemLink
				slot.ItemColor = itemColor
				slot.ItemIcon = iconFilename
				if (bag.Id == 1) then
					wasChangeDetected = true
					InvokeCallbackSafe(slot.ItemColor, CreateIcon(slot.ItemIcon) .. slot.ItemLink .. X4D_Loot.Colors.StackCount .. ' x' .. slot.Stack)
				end
			end
		elseif (itemId > 0) then
			local stack, maxStack = GetSlotStackSize(bag.Id, slotId)
			local iconFilename, itemStack, sellPrice, meetsUsageRequirement, locked, equipType, itemStyle, quality = GetItemInfo(bag.Id, slotId)
			if (iconFilename == nil or iconFilename:len() == 0) then
				iconFilename = 'EsoUI/Art/Icons/icon_missing.dds'
			end
			slot.ItemIcon = iconFilename
			if (stack ~= slot.Stack) then
				local stackChange = stack - slot.Stack
				if (stackChange > 0) then
					if (bag.Id == 1) then
						wasChangeDetected = true
						InvokeCallbackSafe(slot.ItemColor, CreateIcon(slot.ItemIcon) .. slot.ItemLink .. X4D_Loot.Colors.StackCount .. ' x' .. stackChange)
					end
				end
				slot.Stack = stack
				slot.MaxStack = maxStack
			end
		end
	end
	return wasChangeDetected
end

local function UpdateBagInternal(bags, bagId)
	local wasChangeDetected = false
	local bag = bags[bagId]
	if (bag == nil) then
		bag = AddBagInternal(bags, bagId)
		if (bagId == 1) then
			wasChangeDetected = true
		end
	else
		local bagIcon, numSlots = GetBagInfo(bagId)
		for slotIndex = 0, numSlots do
			if (UpdateBagSlotInternal(bag, slotIndex) and bagId == 1) then
				wasChangeDetected = true
			end
		end
	end
	return wasChangeDetected
end

local function UpdateBagsInternal()
	local wasChangeDetected = false
	local bags = X4D_Loot.Bags
	for bagId = 0, GetMaxBags() do
		if (UpdateBagInternal(bags, bagId) and bagId == 1) then
			wasChangeDetected = true
		end
	end
	return wasChangeDetected
end

--== Populate Quest Tools ==--

local function AddQuestStepConditionInternal(quest, step, conditionIndex)
	local conditionText, current, max, isFailCondition, isComplete, isCreditShared = GetJournalQuestConditionInfo(quest.Id, step.Id, conditionIndex)
	local iconFilename, stackCount, itemName = GetQuestItemInfo(quest.Id, step.Id, conditionIndex)
	if (iconFilename == nil or iconFilename:len() == 0) then
		iconFilename = 'EsoUI/Art/Icons/icon_missing.dds'
	end
	if (itemName == nil or itemName:len() == 0) then
		itemName = conditionText
	end
	local condition = {
		Id = conditionIndex,
		ItemIcon = iconFilename,
		ItemLink = '[' .. itemName .. ']', -- TODO: can we link to quest? implement custom link handler?
		ItemColor = '|cFF6600', -- TODO: color by quest type?
		Stack = stackCount,
		Current = current,
		Max = max,
		Text = conditionText,
		Complete = isComplete,
	}
	step.Conditions[conditionIndex] = condition
	return condition
end

local function AddQuestStepInternal(quest, stepIndex)
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
	if (iconFilename == nil or iconFilename:len() == 0) then
		iconFilename = 'EsoUI/Art/Icons/icon_missing.dds'
	end
	if (toolName == nil or toolName:len() == 0) then
		toolName = quest.CurrentStepText
	end
	local tool = {
		Id = toolIndex,
		ItemIcon = iconFilename,
		ItemLink = '[' .. toolName .. ']', -- TODO: can we link to quest? implement custom link handler?
		ItemColor = '|cFF6600', -- TODO: color by quest type?
		Stack = stackCount,
		Usable = isUsable,
	}
	quest.Tools[toolIndex] = tool
	return tool
end

local function AddQuestInternal(quests, questIndex)
	local questName, backgroundText, activeStepText, activeStepType, activeStepTrackerOverrideText, isCompleted, tracked, questLevel, pushed, questType = GetJournalQuestInfo(questIndex)
	local numSteps = GetJournalQuestNumSteps(questIndex)
	local numTools = GetQuestToolCount(questIndex)
	local quest = {
		Id = questIndex,
		Name = questName,
		Type = questType,
		Level = questLevel,
		Completed = isCompleted,
		QuestText = backgroundText,
		Steps = {},
		StepCount = numSteps,
		Tools = {},
		ToolCount = numTools,
		CurrentStepText = activeStepText,
	}
	for stepIndex = 0, quest.StepCount do
		AddQuestStepInternal(quest, stepIndex)
	end
	for toolIndex = 0, quest.ToolCount do
		AddQuestToolInternal(quest, toolIndex)
	end
	quests[quest.Id] = quest
	return quest
end

local function PopulateQuestsInternal()
	local quests = {}
	for questIndex = 0, GetNumJournalQuests() do
		AddQuestInternal(quests, questIndex)
	end
	X4D_Loot.Quests = quests
end

--== Update Quest Tools ==--

local function UpdateQuestStepConditionInternal(quest, step, conditionIndex)
	local wasChangeDetected = false
	local condition = step.Conditions[conditionIndex]
	if (condition == nil) then
		condition = AddQuestStepConditionInternal(quest, step, conditionIndex)
		wasChangeDetected = true
		if (condition ~= nil and condition.Stack > 0) then
			InvokeCallbackSafe(condition.ItemColor, CreateIcon(condition.ItemIcon) .. condition.ItemLink .. X4D_Loot.Colors.StackCount .. ' x' .. condition.Stack .. X4D_Loot.Colors.Subtext .. ' (Quest Item)')
		end
	else
		local iconFilename, stackCount, itemName = GetQuestItemInfo(quest.Id, step.Id, conditionIndex)
		if (iconFilename == nil or iconFilename:len() == 0) then
			iconFilename = 'EsoUI/Art/Icons/icon_missing.dds'
		end
		condition.ItemIcon = iconFilename
		if (stackCount ~= condition.Stack) then
			local stackChange = stackCount - condition.Stack
			if (stackChange > 0) then
				wasChangeDetected = true
				InvokeCallbackSafe(condition.ItemColor, CreateIcon(condition.ItemIcon) .. condition.ItemLink .. X4D_Loot.Colors.StackCount .. ' x' .. stackChange .. X4D_Loot.Colors.Subtext .. ' (Quest Item)')
			end
			condition.Stack = stackCount
		end
	end
	return wasChangeDetected
end

local function UpdateQuestToolInternal(quest, toolIndex)
	local wasChangeDetected = false

	local tool = quest.Tools[toolIndex]
	if (tool == nil) then
		tool = AddQuestToolInternal(quest, toolIndex)
		wasChangeDetected = true
		if (tool ~= nil and tool.Stack > 0) then
			wasChangeDetected = true
			InvokeCallbackSafe(tool.ItemColor, CreateIcon(tool.ItemIcon) .. tool.ItemLink .. X4D_Loot.Colors.StackCount .. ' x' .. tool.Stack .. X4D_Loot.Colors.Subtext .. ' (Quest Item)')
		end
	else
		local iconFilename, stackCount, isUsable, toolName = GetQuestToolInfo(quest.Id, toolIndex)
		if (iconFilename == nil or iconFilename:len() == 0) then
			iconFilename = 'EsoUI/Art/Icons/icon_missing.dds'
		end
		tool.ItemIcon = iconFilename
		if (tool.Stack ~= stackCount) then
			local stackChange = stackCount - tool.Stack
			if (stackChange > 0) then
				wasChangeDetected = true
				InvokeCallbackSafe(tool.ItemColor, CreateIcon(tool.ItemIcon) .. tool.ItemLink .. X4D_Loot.Colors.StackCount .. ' x' .. stackChange .. X4D_Loot.Colors.Subtext .. ' (Quest Item)')
			end
			tool.Stack = stackCount
		end
	end

	return wasChangeDetected
end

local function UpdateQuestStepInternal(quest, stepIndex)
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

local function UpdateQuestInternal(quests, questIndex)
	local wasChangeDetected = false
	local quest = quests[questIndex]
	if (quest == nil) then
		quest = AddQuestInternal(quests, questIndex)
		wasChangeDetected = true
	else
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
	end
	return wasChangeDetected
end

local function UpdateQuestsInternal()
	local wasChangeDetected = false
	local quests = X4D_Loot.Quests
	for questIndex = 0, GetNumJournalQuests() do
		if (UpdateQuestInternal(quests, questIndex)) then
			wasChangeDetected = true
		end
	end
	return wasChangeDetected
end

--== Inventory Checks ==--

local _nextInventoryCheckTime = 0
local _wasLow = false
local _wasFull = false

local function CheckInventorySpaceInternal()
	if (not CheckInventorySpaceSilently(10)) then
		if (not CheckInventorySpaceSilently(1)) then
			if (_wasLow or _nextInventoryCheckTime <= GetGameTimeMilliseconds()) then
				_nextInventoryCheckTime = GetGameTimeMilliseconds() + 20000
				_wasLow = false
				_wasFull = true
				InvokeCallbackSafe(X4D_Loot.Colors.BagSpaceFull, 'Out of Bag Space')
			end
		else
			if (_wasFull or _nextInventoryCheckTime <= GetGameTimeMilliseconds()) then
				_nextInventoryCheckTime = GetGameTimeMilliseconds() + 20000
				InvokeCallbackSafe(X4D_Loot.Colors.BagSpaceLow, 'Low Bag Space')
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
    	return
    end
	if (lootType == LOOT_TYPE_ITEM) then
		if (UpdateBagsInternal()) then
			CheckInventorySpaceInternal()
		end
	elseif (lootType == LOOT_TYPE_QUEST_ITEM) then
		if (UpdateQuestsInternal()) then
			-- NOP
		end
	end
end

function X4D_Loot.OnInventorySingleSlotUpdate(eventCode, bagId, slotId, isNewItem, itemSoundCategory, updateReason)
    if(updateReason == INVENTORY_UPDATE_REASON_DURABILITY_CHANGE) then
    	return
    end
	if (not isNewItem) then
		local bag = GetBagInternal(bagId)
		if (bag == nil) then
			local bags = X4D_Loot.Bags
			bag = AddBagInternal(bags, bagId)
		else
			AddBagSlotInternal(bag, slotId)
		end		
	end
end

local function formatnum(n)
	local left, num, right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left .. (num:reverse():gsub('(%d%d%d)','%1,'):reverse()) .. right
end

function X4D_Loot.OnMoneyUpdate(eventId, newMoney, oldMoney, reasonId)
	local icon = CreateIcon('EsoUI/Art/currency/currency_gold.dds')
	local reason = GetMoneyReason(reasonId)
	local amount = newMoney - oldMoney
	if (amount >= 0) then
		InvokeCallbackSafe(X4D_Loot.Colors.Gold, string.format('%s %s%s %s  (%s total)', reason[1], formatnum(amount), icon, X4D_Loot.Colors.Subtext, formatnum(newMoney)))
	else
		InvokeCallbackSafe(X4D_Loot.Colors.Gold, string.format('%s %s%s %s  (%s remaining)', reason[2], formatnum(math.abs(amount)), icon, X4D_Loot.Colors.Subtext, formatnum(newMoney)))
	end
end

function X4D_Loot.OnQuestAdded(journalIndex, questName, objectiveName)
	UpdateQuestsInternal()
end

function X4D_Loot.OnQuestToolUpdated(journalIndex, questName)
	UpdateQuestsInternal()
end

function X4D_Loot.OnAddOnLoaded(event, addonName)
	if (addonName ~= X4D_Loot.NAME) then
		return
	end	
	X4D_Loot.Settings.SavedVars = ZO_SavedVars:NewAccountWide(X4D_Loot.NAME .. '_SV', 1.0, nil, X4D_Loot.Settings.Defaults)
	X4D_Loot.Register()
end

local function OnCraftCompleted(...)
	PopulateBagsInternal()	
end

function X4D_Loot.Register()		
	EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_LOOT_RECEIVED, X4D_Loot.OnLootReceived)
	EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, X4D_Loot.OnInventorySingleSlotUpdate)
	EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_MONEY_UPDATE, X4D_Loot.OnMoneyUpdate)
	EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_QUEST_ADDED, X4D_Loot.OnQuestAdded)
	EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_QUEST_TOOL_UPDATED, X4D_Loot.OnQuestToolUpdated)
	EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_CRAFT_COMPLETED, OnCraftCompleted)
end

function X4D_Loot.Unregister()
end

function X4D_Loot.OnPlayerActivated()
	PopulateBagsInternal()
	PopulateQuestsInternal()
end

EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_ADD_ON_LOADED, X4D_Loot.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(X4D_Loot.NAME, EVENT_PLAYER_ACTIVATED, X4D_Loot.OnPlayerActivated)


