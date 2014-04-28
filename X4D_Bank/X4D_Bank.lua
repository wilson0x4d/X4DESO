local X4D_Bank = LibStub:NewLibrary('X4D_Bank', 1.5);
if (not X4D_Bank) then
	return;
end

X4D_Bank.NAME = 'X4D_Bank';
X4D_Bank.VERSION = 1.5;

X4D_Bank.Options = {};
X4D_Bank.Options.Saved = {};
X4D_Bank.Options.Default = {
	SettingsAre = 'Account-Wide',
	AutoDepositDowntime = 300,
	AutoDepositReserve = 500,
	AutoDepositFixedAmount = 100,
	AutoDepositPercentage = 1,
	AutoDepositItems = true,
	StartNewStacks = true,
	AutoWithdrawReserve = true,
};

local function GetOption(name)
	local scope = 'Account-Wide';
	if (X4D_Bank.Options.Saved.SettingsAre and X4D_Bank.Options.Saved.SettingsAre ~= 'Account-Wide') then
		scope = GetUnitName("player");
	end
	local scoped = X4D_Bank.Options.Saved[scope];
	if (scoped == nil) then
		return X4D_Bank.Options.Default[name];
	end
	local value = scoped[name];
	if (value == nil) then
		value = X4D_Bank.Options.Default[name];
	end
	return value;
end

local function SetOption(name, value)
	local scope = 'Account-Wide';
	if (X4D_Bank.Options.Saved.SettingsAre and X4D_Bank.Options.Saved.SettingsAre ~= 'Account-Wide') then
		scope = GetUnitName("player");
	end
	local scoped = X4D_Bank.Options.Saved[scope];
	if (scoped == nil) then
		scoped = {};
		X4D_Bank.Options.Saved[scope] = scoped;
	end
	scoped[name] = value;
end

X4D_Bank.Colors = {
	X4D = '|cFFAE19',
	Gray = '|cC5C5C5',
	Gold = '|cFFD700',
	StackCount = '|cFFFFFF',
	BagSpaceLow = '|cFFd00b',
	BagSpaceFull = '|cAA0000',
	Subtext = '|c5C5C5C',
};


local _nextAutoDepositTime = 0;

local function GetItemLinkInternal(bagId, slotIndex)
	local itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_BRACKETS):gsub('(%[%l)', function (i) return i:upper() end):gsub('(%s%l)', function (i) return i:upper() end):gsub('%^[^%]]*', '');
	local itemColor = nil;
	if (itemLink) then
		itemColor = '|c' .. itemLink:sub(3, 8);
	end
	return itemLink, itemColor;
end

X4D_Bank.EmitCallback = DefaultEmitCallback;

function X4D_Bank.RegisterEmitCallback(self, callback)
	if (callback ~= nil) then
		X4D_Bank.EmitCallback = callback;
	else
		X4D_Bank.EmitCallback = DefaultEmitCallback;
	end
end

function X4D_Bank.UnregisterEmitCallback(self, callback)
	if (X4D_Bank.EmitCallback == callback) then
		self:RegisterEmiCallback(nil);
	end
end

local function InvokeCallbackSafe(color, text)
	local callback = X4D_Bank.EmitCallback;
	if (color == nil) then
		color = '|cFF0000';
	end
	if (color:len() < 8) then
		color = '|cFF0000';
	end
	if (callback ~= nil) then	
		callback(color, text);
	end
end


local function CreateIcon(filename, width, height)	
	-- example: /zgoo EsoStrings[SI_BANK_GOLD_AMOUNT_BANKED]:gsub('%|', '!')
	-- gladly accepting gold donations in-game, thanks.
	return string.format('|t%u:%u:%s|t', width or 16, height or 16, filename);
end

local function TryGetBagState(bagId)
	local bagIcon, numSlots = GetBagInfo(bagId);
	local bagState = {
		Id = bagId,
		BagIcon = CreateIcon(bagIcon),
		SlotCount = numSlots,
		SlotsFree = 0,
		Slots = { },
	};
	for slotIndex = 0, bagState.SlotCount do
		local itemName = GetItemName(bagId, slotIndex);
		local iconFilename, itemStack, sellPrice, meetsUsageRequirement, locked, equipType, itemStyle, quality = GetItemInfo(bagId, slotIndex);
		if (itemName ~= nil and itemName:len() > 0) then
			local stackCount, stackMax = GetSlotStackSize(bagId, slotIndex);
			local itemLink, itemColor = GetItemLinkInternal(bagId, slotIndex);
			bagState.Slots[slotIndex] = {
				Id = slotIndex,
				IsEmpty = false,
				ItemIcon = CreateIcon(iconFilename),
				ItemName = itemName, 
				ItemLink = itemLink, 
				ItemColor = itemColor,
				StackCount = stackCount,
				StackMax = stackMax,
			};
		else
			bagState.SlotsFree = bagState.SlotsFree + 1;
			bagState.Slots[slotIndex] = {
				Id = slotIndex,
				IsEmpty = true,
			};
		end
	end
	return bagState;
end

local function TryDepositItems()
	if (not GetOption('AutoDepositItems')) then
		return;
	end

	local inventoryState = TryGetBagState(1);
	local bankState = TryGetBagState(2);

	local emptyBankSlotIndex = 0;
	local emptyBankSlots = {};

	for _,bankSlotInfo in pairs(bankState.Slots) do
		if (not bankSlotInfo.IsEmpty) then		
			for _,inventorySlotInfo in pairs(inventoryState.Slots) do
				if (not inventorySlotInfo.IsEmpty) then
					if (bankSlotInfo.ItemName == inventorySlotInfo.ItemName) then
						local stackRemaining = bankSlotInfo.StackMax - bankSlotInfo.StackCount;
						if (inventorySlotInfo.StackCount < stackRemaining) then
							stackRemaining = inventorySlotInfo.StackCount;
						end
						if (stackRemaining > 0) then
							CallSecureProtected("PickupInventoryItem", inventoryState.Id, inventorySlotInfo.Id, stackRemaining);
							CallSecureProtected("PlaceInInventory", bankState.Id, bankSlotInfo.Id);
							InvokeCallbackSafe(bankSlotInfo.ItemColor, 'Deposited ' .. bankSlotInfo.ItemIcon .. bankSlotInfo.ItemLink .. X4D_Bank.Colors.StackCount .. ' x' .. stackRemaining);
						end
					end
				end
			end
		else
			emptyBankSlots[emptyBankSlotIndex] = bankSlotInfo;
			emptyBankSlotIndex = emptyBankSlotIndex + 1;
		end
	end

	if ((not GetOption('StartNewStacks')) or (bankState.SlotsFree == 0)) then
		return;
	end

	zo_callLater(function()
		inventoryState = TryGetBagState(1);
		emptyBankSlotIndex = 0;
		for _,bankSlotInfo in pairs(bankState.Slots) do
			if (not bankSlotInfo.IsEmpty) then		
				for _,inventorySlotInfo in pairs(inventoryState.Slots) do
					if (not inventorySlotInfo.IsEmpty) then
						if (bankSlotInfo.ItemName == inventorySlotInfo.ItemName) then
							local stackRemaining = inventorySlotInfo.StackCount;
							if (stackRemaining > 0) then
								local emptyBankSlot = emptyBankSlots[emptyBankSlotIndex];
								if (emptyBankSlot ~= nil) then
									emptyBankSlotIndex = emptyBankSlotIndex + 1;
									CallSecureProtected("PickupInventoryItem", inventoryState.Id, inventorySlotInfo.Id, stackRemaining);
									CallSecureProtected("PlaceInInventory", bankState.Id, emptyBankSlot.Id);
									InvokeCallbackSafe(inventorySlotInfo.ItemColor, 'Deposited ' .. inventorySlotInfo.ItemIcon .. inventorySlotInfo.ItemLink .. X4D_Bank.Colors.StackCount .. ' x' .. stackRemaining);
								end
							end
						end
					end
				end
			end
		end
	end, 1500);
end

local function TryDepositFixedAmount()
	local availableAmount = GetCurrentMoney() - GetOption('AutoDepositReserve');
	local depositAmount = GetOption('AutoDepositFixedAmount');
	if (depositAmount > 0) then
		if (availableAmount < depositAmount) then
			depositAmount = availableAmount;
		end
		if (availableAmount >= depositAmount) then
			DepositMoneyIntoBank(depositAmount);
		end
	end
	return availableAmount - depositAmount;
end

local function TryDepositPercentage(availableAmount)
	local depositAmount = (availableAmount * (GetOption('AutoDepositPercentage') / 100));
	if (depositAmount > 0) then
		DepositMoneyIntoBank(depositAmount);
	end
	return availableAmount - depositAmount;
end

local function TryWithdrawReserveAmount()
	if (not GetOption('AutoWithdrawReserve')) then
		return;
	end
	local carriedAmount = GetCurrentMoney();
	local deficit = GetOption('AutoDepositReserve') - carriedAmount;
	if (deficit > 0) then
		if (GetBankedMoney() > deficit) then
			WithdrawMoneyFromBank(deficit);
		end
	end
end

local function OnOpenBank(eventCode)
	if (_nextAutoDepositTime <= GetGameTimeMilliseconds()) then
		_nextAutoDepositTime = GetGameTimeMilliseconds() + (GetOption('AutoDepositDowntime') * 1000);
		local availableAmount = TryDepositFixedAmount();
		TryDepositPercentage(availableAmount);
	end
	TryWithdrawReserveAmount();
	TryDepositItems();
end

local function SetComboboxValue(controlName, value)
	local combobox = _G[controlName];
	local dropmenu = ZO_ComboBox_ObjectFromContainer(GetControl(combobox, "Dropdown"));
	local items = dropmenu:GetItems();
	for k,v in pairs(items) do
		if (v.name == value) then
			dropmenu:SetSelectedItem(v.name);
		end
	end
end

local function SetCheckboxValue(controlName, value)
	local checkbox = _G[controlName]:GetNamedChild('Checkbox');
	checkbox:SetState(value and 1 or 0);
	checkbox:toggleFunction(value);
end

local function SetSliderValue(controlName, value, minValue, maxValue)
	local range = maxValue - minValue
	local slider = _G[controlName];
	local slidercontrol = slider:GetNamedChild("Slider");
	local slidervalue = slider:GetNamedChild("ValueLabel");
	slidercontrol:SetValue((value - minValue)/range);
	slidervalue:SetText(tostring(value));
end

local function InitializeOptionsUI()
	local LAM = LibStub('LibAddonMenu-1.0');
	local cplId = LAM:CreateControlPanel('X4D_BANK_CPL', 'X4D |cFFAE19Bank');

	LAM:AddHeader(cplId, 
		'X4D_BANK_HEADER', 'Settings');

	LAM:AddDropdown(cplId, 'X4D_CHAT_OPTION_SETTINGSARE', 'Settings Are..',
		'Settings Option', {'Account-Wide', 'Per-Character'},
		function() return X4D_Bank.Options.Saved.SettingsAre or 'Account-Wide' end,
		function(option)
			X4D_Bank.Options.Saved.SettingsAre = option;
		end);

	LAM:AddSlider(cplId,
		'X4D_BANK_SLIDER_AUTODEPOSIT_RESERVE', 'Reserve Amount',
		'If non-zero, the specified amount of carried gold will never be auto-deposited.',
		0, 10000, 100,
		function () return GetOption('AutoDepositReserve') end,
		function (v) SetOption('AutoDepositReserve', tonumber(tostring(v))) end);

	LAM:AddCheckbox(cplId, 
		'X4D_BANK_CHECK_AUTOWITHDRAW_RESERVE', 'Auto-Withdraw Reserve', 
		'When enabled, if you are carrying less than your specified reserve the difference will be withdrawn from the bank.', 
		function() return GetOption('AutoWithdrawReserve') end,
		function() SetOption('AutoWithdrawReserve', not GetOption('AutoWithdrawReserve')) end);

	LAM:AddSlider(cplId,
		'X4D_BANK_SLIDER_AUTODEPOSIT_FIXED_AMOUNT', 'Auto-Deposit Fixed Amount',
		'If non-zero, will auto-deposit up to the configured amount when accessing the bank.',
		0, 1000, 100,
		function () return GetOption('AutoDepositFixedAmount') end,
		function (v) SetOption('AutoDepositFixedAmount', tonumber(tostring(v))) end);

	LAM:AddSlider(cplId,
		'X4D_BANK_SLIDER_AUTODEPOSIT_PERCENTAGE', 'Auto-Deposit Percentage',
		'If non-zero, will auto-deposit percentage of non-reserve gold when accessing the bank.',
		0, 100, 1,
		function () return GetOption('AutoDepositPercentage') end,
		function (v) SetOption('AutoDepositPercentage', tonumber(tostring(v))) end);

	LAM:AddSlider(cplId,
		'X4D_BANK_SLIDER_AUTODEPOSIT_DOWNTIME', 'Auto-Deposit Down-Time',
		'If non-zero, will wait specified time (in seconds) between bank interactions before auto-depositing again.',
		0, 3600, 30,
		function () return GetOption('AutoDepositDowntime') end,
		function (v) SetOption('AutoDepositDowntime', tonumber(tostring(v))) end);

	LAM:AddCheckbox(cplId, 
		'X4D_BANK_CHECK_AUTODEPOSIT_ITEMS', 'Auto-Deposit Items?', 
		'When enabled, partial stacks in the bank will be filled from your inventory.', 
		function() return GetOption('AutoDepositItems') end,
		function() SetOption('AutoDepositItems', not GetOption('AutoDepositItems')) end);

	LAM:AddCheckbox(cplId, 
		'X4D_BANK_CHECK_START_NEW_STACKS', 'Start New Stacks?', 
		'When enabled, when partial stacks are filled, new stacks of those item types will be created from your inventory.', 
		function() return GetOption('StartNewStacks') end,
		function() SetOption('StartNewStacks', not GetOption('StartNewStacks')) end);

	ZO_PreHook("ZO_OptionsWindow_ChangePanels", function(panel)
			if (panel == cplId) then				
				ZO_OptionsWindowResetToDefaultButton:SetCallback(function ()
					if (ZO_OptionsWindowResetToDefaultButton:GetParent()['currentPanel'] == cplId) then

						SetComboboxValue('X4D_CHAT_OPTION_SETTINGSARE', X4D_Bank.Options.Saved.SettingsAre);
						X4D_Bank.Options.Saved.SettingsAre = X4D_Bank.Options.Default.SettingsAre;

						SetSliderValue('X4D_BANK_SLIDER_AUTODEPOSIT_DOWNTIME', X4D_Bank.Options.Default.AutoDepositDowntime, 0, 3600);
						SetOption('AutoDepositDowntime', X4D_Bank.Options.Default.AutoDepositDowntime);

						SetSliderValue('X4D_BANK_SLIDER_AUTODEPOSIT_RESERVE', X4D_Bank.Options.Default.AutoDepositReserve, 0, 10000);
						SetOption('AutoDepositReserve', X4D_Bank.Options.Default.AutoDepositReserve);

						SetCheckboxValue('X4D_BANK_CHECK_AUTOWITHDRAW_RESERVE', X4D_Bank.Options.Default.AutoWithdrawReserve);
						SetOption('AutoWithdrawReserve', X4D_Bank.Options.Default.AutoWithdrawReserve);

						SetSliderValue('X4D_BANK_SLIDER_AUTODEPOSIT_FIXED_AMOUNT', X4D_Bank.Options.Default.AutoDepositFixedAmount, 0, 1000);
						SetOption('AutoDepositFixedAmount', X4D_Bank.Options.Default.AutoDepositFixedAmount);

						SetSliderValue('X4D_BANK_SLIDER_AUTODEPOSIT_PERCENTAGE', X4D_Bank.Options.Default.AutoDepositPercentage, 0, 100);
						SetOption('AutoDepositPercentage', X4D_Bank.Options.Default.AutoDepositPercentage);

						SetCheckboxValue('X4D_BANK_CHECK_AUTODEPOSIT_ITEMS', X4D_Bank.Options.Default.AutoDepositItems);
						SetOption('AutoDepositItems', X4D_Bank.Options.Default.AutoDepositItems);

						SetCheckboxValue('X4D_BANK_CHECK_START_NEW_STACKS', X4D_Bank.Options.Default.StartNewStacks);
						SetOption('StartNewStacks', X4D_Bank.Options.Default.StartNewStacks);												
					end
				end);
			end
		end);		

end

local function OnAddOnLoaded(eventCode, addonName)
	if (addonName ~= X4D_Bank.NAME) then
		return;
	end	
	X4D_Bank.Options.Saved = ZO_SavedVars:NewAccountWide(X4D_Bank.NAME .. '_SV', 1.0, nil, X4D_Bank.Options.Default);
	InitializeOptionsUI();
	EVENT_MANAGER:RegisterForEvent(X4D_Bank.NAME, EVENT_OPEN_BANK, OnOpenBank)
end

EVENT_MANAGER:RegisterForEvent(X4D_Bank.NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded);