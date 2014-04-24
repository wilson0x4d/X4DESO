local X4D_Bank = LibStub:NewLibrary('X4D_Bank', 1.1);
if (not X4D_Bank) then
	return;
end

X4D_Bank.NAME = 'X4D_Bank';
X4D_Bank.VERSION = 1.1;

X4D_Bank.Options = {};
X4D_Bank.Options.Saved = {};
X4D_Bank.Options.Default = {
	AutoDepositDowntime = 300,
	AutoDepositReserve = 500,
	AutoDepositFixedAmount = 100,
	AutoDepositPercentage = 1,
	AutoDepositItems = true,
	StartNewStacks = true,
	AutoWithdrawReserve = true,
};

X4D_Bank.Colors = {
	X4D = '|cFFAE19',
	Gray = '|cC5C5C5',
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

local function TryGetBagState(bagId)
	local bagIcon, numSlots = GetBagInfo(bagId);
	local bagState = {
		Id = bagId,
		Icon = bagIcon,
		SlotCount = numSlots,
		SlotsFree = 0,
		Slots = { },
	};
	for slotIndex = 1, bagState.SlotCount do
		local itemName = GetItemName(bagId, slotIndex);
		if (itemName ~= nil and itemName:len() > 0) then
			local stackCount, stackMax = GetSlotStackSize(bagId, slotIndex);
			local itemLink = GetItemLinkInternal(bagId, slotIndex);
			bagState.Slots[slotIndex] = {
				Id = slotIndex,
				IsEmpty = false,
				ItemName = itemName, 
				ItemLink = itemLink, 
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
	if (not X4D_Bank.Options.Saved.AutoDepositItems) then
		return;
	end

	local inventoryState = TryGetBagState(1);
	local bankState = TryGetBagState(2);

	for _,bankSlotInfo in pairs(bankState.Slots) do
		if (not bankSlotInfo.IsEmpty) then			
			for _,inventorySlotInfo in pairs(inventoryState.Slots) do
				if (not inventorySlotInfo.IsEmpty) then
					if (bankSlotInfo.ItemName == inventorySlotInfo.ItemName) then
						local stackRemaining = bankSlotInfo.StackMax - bankSlotInfo.StackCount;
						if (stackRemaining > 0) then
							-- protected?! *sigh* LAME!
							PickupInventoryItem(inventoryState.Id, inventorySlotInfo.Id, stackRemaining);
							PlaceInInventory(bankState.Id, bankSlotInfo.Id);
						end
					end
				end
			end
		end
	end

	if ((not X4D_Bank.Options.Saved.StartNewStacks) or (bankState.SlotsFree == 0)) then
		return;
	end

	local inventoryState = TryGetBagState(1);
	local bankState = TryGetBagState(2);
end

local function TryDepositFixedAmount()
	if (X4D_Bank.Options.Saved.AutoDepositFixedAmount <= 0) then
		return;
	end
	local carriedAmount = GetCurrentMoney();
	if (carriedAmount > X4D_Bank.Options.Saved.AutoDepositFixedAmount) then
		if ((carriedAmount - X4D_Bank.Options.Saved.AutoDepositFixedAmount) > X4D_Bank.Options.Saved.AutoDepositReserve) then
			DepositMoneyIntoBank(X4D_Bank.Options.Saved.AutoDepositFixedAmount);
		end
	end
end

local function TryDepositPercentage()
	if (X4D_Bank.Options.Saved.AutoDepositPercentage <= 0) then
		return;
	end
	local carriedAmount = GetCurrentMoney();
	local percentageOfCarried = (carriedAmount * (X4D_Bank.Options.Saved.AutoDepositPercentage / 100));
	if (percentageOfCarried > 0 and carriedAmount >= percentageOfCarried) then
		if ((carriedAmount - percentageOfCarried) > X4D_Bank.Options.Saved.AutoDepositReserve) then
			DepositMoneyIntoBank(percentageOfCarried);
		end
	end
end

local function TryWithdrawReserveAmount()
	if (not X4D_Bank.Options.Saved.AutoWithdrawReserve) then
		return;
	end
	local carriedAmount = GetCurrentMoney();
	local deficit = X4D_Bank.Options.Saved.AutoDepositReserve - carriedAmount;
	if (deficit > 0) then
		if (GetBankedMoney() > deficit) then
			WithdrawMoneyFromBank(deficit);
		end
	end
end

local function OnOpenBank(eventCode)
	if (_nextAutoDepositTime > GetGameTimeMilliseconds()) then
		return;
	end
	_nextAutoDepositTime = GetGameTimeMilliseconds() + (X4D_Bank.Options.Saved.AutoDepositDowntime * 1000);
	TryDepositFixedAmount();
	TryDepositPercentage();
	--TryDepositItems();
	TryWithdrawReserveAmount();
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

	LAM:AddSlider(cplId,
		'X4D_BANK_SLIDER_AUTODEPOSIT_RESERVE', 'Reserve Amount',
		'If non-zero, will NOT auto-deposit if it would drop you below the specified amount.',
		0, 10000, 100,
		function () return X4D_Bank.Options.Saved.AutoDepositReserve end,
		function (v) X4D_Bank.Options.Saved.AutoDepositReserve = tonumber(tostring(v)) end);

	LAM:AddCheckbox(cplId, 
		'X4D_BANK_CHECK_AUTOWITHDRAW_RESERVE', 'Auto-Withdraw Reserve', 
		'When enabled, if you are carrying less than your specified reserve the difference will be withdrawn from the bank.', 
		function() return X4D_Chat.Settings.SavedVars.AutoWithdrawReserve end,
		function() X4D_Chat.Settings.SavedVars.AutoWithdrawReserve = not X4D_Chat.Settings.SavedVars.AutoWithdrawReserve end);

	LAM:AddSlider(cplId,
		'X4D_BANK_SLIDER_AUTODEPOSIT_FIXED_AMOUNT', 'Auto-Deposit Fixed Amount',
		'If non-zero, will auto-deposit fixed amount when accessing the bank.',
		0, 1000, 100,
		function () return X4D_Bank.Options.Saved.AutoDepositFixedAmount end,
		function (v) X4D_Bank.Options.Saved.AutoDepositFixedAmount = tonumber(tostring(v)) end);

	LAM:AddSlider(cplId,
		'X4D_BANK_SLIDER_AUTODEPOSIT_PERCENTAGE', 'Auto-Deposit Percentage',
		'If non-zero, will auto-deposit percentage when accessing the bank.',
		0, 100, 1,
		function () return X4D_Bank.Options.Saved.AutoDepositPercentage end,
		function (v) X4D_Bank.Options.Saved.AutoDepositPercentage = tonumber(tostring(v)) end);

	LAM:AddSlider(cplId,
		'X4D_BANK_SLIDER_AUTODEPOSIT_DOWNTIME', 'Auto-Deposit Down-Time',
		'If non-zero, will wait specified time (in seconds) between bank interactions before auto-depositing again.',
		0, 3600, 30,
		function () return X4D_Bank.Options.Saved.AutoDepositDowntime end,
		function (v) X4D_Bank.Options.Saved.AutoDepositDowntime = tonumber(tostring(v)) end);

	--LAM:AddCheckbox(cplId, 
	--	'X4D_BANK_CHECK_AUTODEPOSIT_ITEMS', 'Auto-Deposit Items?', 
	--	'When enabled, partial stacks in the bank will be filled.', 
	--	function() return X4D_Bank.Options.Saved.AutoDepositItems end,
	--	function() X4D_Bank.Options.Saved.AutoDepositItems = not X4D_Bank.Options.Saved.AutoDepositItems end);

	--LAM:AddCheckbox(cplId, 
	--	'X4D_BANK_CHECK_START_NEW_STACKS', 'Start New Stacks?', 
	--	'When enabled, if partial stacks are filled, new stacks will be started.', 
	--	function() return X4D_Bank.Options.Saved.StartNewStacks end,
	--	function() X4D_Bank.Options.Saved.StartNewStacks = not X4D_Bank.Options.Saved.StartNewStacks end);

	ZO_PreHook("ZO_OptionsWindow_ChangePanels", function(panel)
			if (panel == cplId) then				
				ZO_OptionsWindowResetToDefaultButton:SetCallback(function ()
					if (ZO_OptionsWindowResetToDefaultButton:GetParent()['currentPanel'] == cplId) then

						SetSliderValue('X4D_BANK_SLIDER_AUTODEPOSIT_DOWNTIME', X4D_Bank.Options.Default.AutoDepositDowntime, 0, 3600);
						X4D_Bank.Options.Saved.AutoDepositDowntime = X4D_Bank.Options.Default.AutoDepositDowntime;

						SetSliderValue('X4D_BANK_SLIDER_AUTODEPOSIT_RESERVE', X4D_Bank.Options.Default.AutoDepositReserve, 0, 10000);
						X4D_Bank.Options.Saved.AutoDepositReserve = X4D_Bank.Options.Default.AutoDepositReserve;

						SetCheckboxValue('X4D_BANK_CHECK_AUTOWITHDRAW_RESERVE', X4D_Bank.Options.Default.AutoWithdrawReserve);
						X4D_Bank.Options.Saved.AutoWithdrawReserve = X4D_Bank.Options.Default.AutoWithdrawReserve;

						SetSliderValue('X4D_BANK_SLIDER_AUTODEPOSIT_FIXED_AMOUNT', X4D_Bank.Options.Default.AutoDepositFixedAmount, 0, 1000);
						X4D_Bank.Options.Saved.AutoDepositFixedAmount = X4D_Bank.Options.Default.AutoDepositFixedAmount;

						SetSliderValue('X4D_BANK_SLIDER_AUTODEPOSIT_PERCENTAGE', X4D_Bank.Options.Default.AutoDepositPercentage, 0, 100);
						X4D_Bank.Options.Saved.AutoDepositPercentage = X4D_Bank.Options.Default.AutoDepositPercentage;

--						SetCheckboxValue('X4D_BANK_CHECK_AUTODEPOSIT_ITEMS', X4D_Bank.Options.Default.AutoDepositItems);
--						X4D_Bank.Options.Saved.AutoDepositItems = X4D_Bank.Options.Default.AutoDepositItems;

--						SetCheckboxValue('X4D_BANK_CHECK_START_NEW_STACKS', X4D_Bank.Options.Default.StartNewStacks);
--						X4D_Bank.Options.Saved.StartNewStacks = X4D_Bank.Options.Default.StartNewStacks;
												
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