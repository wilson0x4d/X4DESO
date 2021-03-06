local X4D_Vendors = LibStub:NewLibrary("X4D_Vendors", "0#VERSION#")
if (not X4D_Vendors) then
	return
end
local X4D = LibStub("X4D")
X4D.Vendors = X4D_Vendors

X4D_Vendors.NAME = "X4D_Vendors"
X4D_Vendors.VERSION = "#VERSION#"

X4D_VENDORACTION_NONE = 0
X4D_VENDORACTION_KEEP = 1
X4D_VENDORACTION_SELL = 2

local _currentMapId = nil
local _currentZoneIndex = nil

local constUnspecified = X4D.Colors.Gray .. "Unspecified"
local constKeep = X4D.Colors.Deposit .. "Keep"
local constSell = X4D.Colors.Withdraw .. "Sell"

local _itemTypeChoices = {
	constUnspecified,
	constKeep,
	constSell,
}

-- region Chat Callback

local function DefaultChatCallback(color, text)
	d(color .. text)
end

X4D_Vendors.ChatCallback = DefaultChatCallback

function X4D_Vendors:RegisterCallback(callback)
	if (callback ~= nil) then
		X4D_Vendors.ChatCallback = callback
	else
		X4D_Vendors.ChatCallback = DefaultChatCallback
	end
end

function X4D_Vendors:UnregisterCallback(callback)
	if (X4D_Vendors.ChatCallback == callback) then
		self:RegisterCallback(nil)
	end
end

local function InvokeChatCallback(color, text)
	local callback = X4D_Vendors.ChatCallback
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

-- endregion

local function IsSlotIgnoredItem(slot)
	if (not slot.IsEmpty) then
		local normalized = X4D.Bags:GetNormalizedString(slot)
		local patterns = X4D_Vendors.Settings:Get("IgnoredItemPatterns")
		for i = 1, #patterns do
			local pattern = patterns[i]
			local isIgnored = false
			if (not pcall( function()
					if (normalized:find(pattern)) then
						isIgnored = true
					end
				end)) then
				InvokeChatCallback(X4D.Colors.SYSTEM, "(Vendors) Bad Ignored Item Pattern: |cFF7777" .. pattern)
			end
			if (isIgnored) then
				return true
			end
		end
	end
	return false
end

--[[
    EVENT_BUY_RECEIPT= function(eventId, entryName, entryType, entryQuantity, money, specialCurrencyType1, specialCurrencyInfo1, specialCurrencyQuantity1, specialCurrencyType2, specialCurrencyInfo2, specialCurrencyQuantity2, itemSoundCategory)
    EVENT_SELL_RECEIPT= function(eventId, itemName, quantity, money)
    EVENT_BUYBACK_RECEIPT= function(eventId, itemName, itemQuantity, money, itemSoundCategory)
    EVENT_ITEM_REPAIR_FAILURE=function(eventId, reason)
    EVENT_ALLIANCE_POINT_UPDATE
    EVENT_COLLECTION_UPDATED
    EVENT_COLLECTIBLE_UPDATED
    EVENT_MONEY_UPDATE
    EVENT_ITEM_LAUNDER_RESULT= function(result)
    EVENT_INVENTORY_FULL_UPDATE
    EVENT_INVENTORY_SINGLE_SLOT_UPDATE
    EVENT_JUSTICE_FENCE_UPDATE

    INTERACTION_VENDOR
]]

local function GetPatternAction(slot)
	if (IsSlotIgnoredItem(slot)) then
		return X4D_VENDORACTION_NONE
	end
--	 X4D.Log:Verbose{"GetPatternAction", slot.Id, slot.Item.Name}
	local vendorAction = X4D_VENDORACTION_NONE
	if (not slot.IsEmpty) then
		local normalized = X4D.Bags:GetNormalizedString(slot)
		local forKeepsPatterns = X4D_Vendors.Settings:Get("ForKeepsItemPatterns")
		for i = 1, #forKeepsPatterns do
			local pattern = forKeepsPatterns[i]
			if (not pcall( function()
					if (normalized:find(pattern)) then
						vendorAction = X4D_VENDORACTION_KEEP
					end
				end)) then
				InvokeChatCallback(X4D.Colors.SYSTEM, "(Vendors) Bad 'For Keeps' Pattern: |cFF7777" .. pattern)
			end
			if (vendorAction ~= X4D_VENDORACTION_NONE) then
				return vendorAction
			end
		end
		local forSalePatterns = X4D_Vendors.Settings:Get("ForSaleItemPatterns")
		for i = 1, #forSalePatterns do
			local pattern = forSalePatterns[i]
			if (not pcall( function()
					if (normalized:find(pattern)) then
						vendorAction = X4D_VENDORACTION_SELL
					end
				end)) then
				InvokeChatCallback(X4D.Colors.SYSTEM, "(Vendors) Bad 'For Sale' Item Pattern: |cFF7777" .. pattern)
			end
			if (vendorAction ~= X4D_VENDORACTION_NONE) then
				return vendorAction
			end
		end
	end
	return vendorAction
end

local _debits = 0
local _credits = 0
local _goldIcon = " " .. X4D.Icons:CreateString("EsoUI/Art/currency/currency_gold.dds")

local function GetItemTypeActions()
	local itemTypeActions = { }
	for _, groupName in pairs(X4D.Items.ItemGroups) do
		for _, itemType in pairs(X4D.Items.ItemTypes) do
			if (itemType.Group == groupName) then
				local action = X4D_Vendors.Settings:Get(itemType.Id)
				if (action == constKeep or action == X4D_VENDORACTION_KEEP) then
					itemTypeActions[itemType.Id] = X4D_VENDORACTION_KEEP
				elseif (action == constSell or action == X4D_VENDORACTION_SELL) then
					itemTypeActions[itemType.Id] = X4D_VENDORACTION_SELL
				else
					itemTypeActions[itemType.Id] = X4D_VENDORACTION_NONE
				end
			end
		end
	end
	return itemTypeActions
end

-- TODO: refactor to leverage "transactionState" in the same way that X4D_Bank does -- but
--		 don't share MRL state (duplicate code, or wrap into instanced class, since Vendor
--		 MRL and Bank MRL may not be the same
local function ConductTransactions(vendor)
	if (vendor == nil) then
		X4D.Log:Error( { "Vendor reference is nil or invalid.", vendor }, "X4D_Vendors")
		return
	end
	local launderItemsWorthZeroGold = X4D_Vendors.Settings:Get("LaunderItemsWorth0Gold")
	-- TODO: add an option where once all fence laundering is exhausted, begin 
	--		 performing fence sales (or the other way around, based on user
	--		 selection) with this, also: re-order transactions based on user
	--		 setting ascending or descending.
	local laundersMax, laundersUsed = GetFenceLaunderTransactionInfo()
	local sellsMax, sellsUsed = GetFenceSellTransactionInfo()
	local itemTypeActions = GetItemTypeActions()
	local bag = X4D.Bags:GetBackpack(true)
	if (bag ~= nil) then
		for slotIndex = 0, bag.SlotCount do
			local slot = bag.Slots[slotIndex]
			if (slot ~= nil and not slot.IsEmpty) then
				if (not IsSlotIgnoredItem(slot)) then
					local vendorAction = GetPatternAction(slot) or X4D_VENDORACTION_NONE
					local itemTypeAction = itemTypeActions[slot.Item.ItemType] or X4D_VENDORACTION_NONE
					local dbg = ""
					if (X4D.Log:IsVerboseEnabled()) then
						local options, name = slot.Item.Id:match("|H1:item:(.-)|h[%[]*(.-)[%]]*|h")
						local normalized = X4D.Bags:GetNormalizedString(slot) or "nil"
						dbg = " ("..options.."//"..normalized.."//bound="..tostring(slot.IsBound).."//va="..vendorAction.."//ita="..itemTypeAction..")"
					end
					if ((vendor.IsFence and slot.IsStolen) 
						and ((vendorAction == X4D_VENDORACTION_KEEP or itemTypeAction == X4D_VENDORACTION_KEEP) 
							or (vendorAction == X4D_VENDORACTION_SELL and slot.LaunderPrice == 0 and launderItemsWorthZeroGold))) then
						if (laundersUsed < laundersMax) then
							if (slot.LaunderPrice ~= nil or slot.LaunderPrice == 0) then
								local totalPrice = (slot.LaunderPrice * slot.StackCount)
								if (totalPrice < GetCurrentMoney()) then
									laundersUsed = laundersUsed + 1 -- TODO: if transaction fails, we want to decrement this number, obviously
									LaunderItem(bag.Id, slot.Id, slot.StackCount)
									slot.IsEmpty = false
									slot.IsStolen = false
									local statement = X4D.Colors.Subtext .. " for " .. X4D.Colors.Red .. "(-" .. totalPrice .. _goldIcon .. ")"
									_debits = _debits + totalPrice
									local message = zo_strformat("<<1>> <<2>><<t:3>> <<4>>x<<5>><<6>>"..dbg,
									"Laundered", slot.Item:GetItemIcon(), slot.Item:GetItemLink(), X4D.Colors.StackCount, slot.StackCount, statement)
									InvokeChatCallback(slot.ItemColor, message)
								end
							end
						end
					elseif (vendorAction == X4D_VENDORACTION_SELL or (itemTypeAction == X4D_VENDORACTION_SELL and vendorAction ~= X4D_VENDORACTION_KEEP)) then
						if (vendor.IsFence == slot.IsStolen) then
							if ((not vendor.IsFence) or (sellsUsed <= sellsMax)) then
								sellsUsed = sellsUsed + 1 -- TODO: if transaction fails, we want to decrement this number, obviously
								CallSecureProtected("PickupInventoryItem", bag.Id, slot.Id, slot.StackCount)
								CallSecureProtected("PlaceInStoreWindow")
								slot.IsEmpty = true
								local statement = ""
								if (slot.SellPrice ~= nil) then
									local totalPrice = (slot.SellPrice * slot.StackCount)
									statement = X4D.Colors.Subtext .. " for " .. X4D.Colors.Gold .. totalPrice .. _goldIcon
									_credits = _credits + totalPrice
								end
								local message = zo_strformat("<<1>> <<2>><<t:3>> <<4>>x<<5>><<6>>"..dbg,
									"Sold", slot.Item:GetItemIcon(), slot.Item:GetItemLink(), X4D.Colors.StackCount, slot.StackCount, statement)
								InvokeChatCallback(slot.ItemColor, message)
							end
						end
					end
				end
			end
		end
	end
end

local function ReportEarnings()
	local delta = _credits - _debits
	if (delta ~= 0) then
		if (delta < 0) then
			delta = X4D.Colors.X4D .. "Total Losses: " .. X4D.Colors.Red .. "(" .. delta .. _goldIcon .. ")"
		else
			delta = X4D.Colors.X4D .. "Total Earnings: " .. X4D.Colors.Gold .. delta .. _goldIcon
		end
		local balance = ""
		-- TODO: report balance-on-hand? seems a little chatty at that point
		InvokeChatCallback(X4D.Colors.X4D, "Vendor Debits: " .. X4D.Colors.Gold .. _debits .. _goldIcon .. X4D.Colors.X4D .. " Credits: " .. X4D.Colors.Gold .. _credits .. _goldIcon .. " " .. delta .. balance)
	end
end

local function OnOpenFence()
	_debits = 0
	_credits = 0
	local fence = X4D.NPCs:GetOrCreate("interact")
	fence.IsFence = true
	X4D.NPCs:UpdatePosition(fence)
	X4D.NPCs.CurrentNPC(fence)
	if (X4D_Vendors.Settings:Get("EnableFenceInteraction")) then
		ConductTransactions(fence)
		ReportEarnings()
	end
end
local function OnCloseFence() 
	-- force update of bag snapshots on close
	local inventoryState = X4D.Bags:GetBackpack(true)
	local bankState, subscriberBankState = X4D.Bags:GetBank(true)
	X4D.NPCs.CurrentNPC(nil)
end

local function OnOpenStoreAsync(timer, state)
	local vendor = state
	timer:Stop()
	ConductTransactions(vendor)
	ReportEarnings()
end

local function OnOpenStore()
	_debits = 0
	_credits = 0
	local vendor = X4D.NPCs:GetOrCreate("interact")
	vendor.IsFence = false
	X4D.NPCs:UpdatePosition(vendor)
	X4D.NPCs.CurrentNPC(vendor)
	X4D.Async:CreateTimer(OnOpenStoreAsync):Start(337, vendor, "X4D_Vendors::ConductTransactions")
end
local function OnCloseStore() 
	-- force update of bag snapshots on close
	local inventoryState = X4D.Bags:GetBackpack(true)
	local bankState, subscriberBankState = X4D.Bags:GetBank(true)
	X4D.NPCs.CurrentNPC(nil)
end

local function OnOpenStable()
	local stablemaster = X4D.NPCs:GetOrCreate("interact")
	X4D.NPCs:UpdatePosition(stablemaster)
	X4D.NPCs.CurrentNPC(stablemaster)
end
local function OnCloseStable()
	X4D.NPCs.CurrentNPC(nil)
end

function X4D_Vendors:GetOrCreateVendor(tag)
	return X4D.NPCs:GetOrCreate(tag)
end

local function InitializeSettingsUI()
	local LAM = LibStub("LibAddonMenu-2.0")
	local cplId = LAM:RegisterAddonPanel("X4D_VENDORS_CPL", {
		type = "panel",
		name = "X4D |cFFAE19Vendors |c4D4D4D" .. X4D_Vendors.VERSION,
	})

	local panelControls = { }

	table.insert(panelControls, {
		type = "dropdown",
		name = "Settings Are..",
		tooltip = "Settings Scope",
		choices = { "Account-Wide", "Per-Character" },
		getFunc = function() return X4D_Vendors.Settings:Get("SettingsAre") or "Account-Wide" end,
		setFunc = function(v)
			if (X4D_Vendors.Settings:Get("SettingsAre") ~= v) then
				X4D_Vendors.Settings:Set("SettingsAre", v)
			end
		end,
	})

	-- region ItemType Options

	for _, groupName in pairs(X4D.Items.ItemGroups) do
		table.insert(panelControls, {
			type = "header",
			name = groupName,
		})
		for _, itemType in pairs(X4D.Items.ItemTypes) do
			if (itemType.Group == groupName) then
				table.insert(panelControls, {
					type = "dropdown",
					name = itemType.Name,
					tooltip = itemType.Tooltip or itemType.Canonical,
					choices = _itemTypeChoices,
					getFunc = function()
						local v = X4D_Vendors.Settings:Get(itemType.Id) or X4D_VENDORACTION_NONE
						if (v == X4D_VENDORACTION_KEEP) then
							return constKeep
						elseif (v == X4D_VENDORACTION_SELL) then
							return constSell
						else
							return constUnspecified
						end
					end,
					setFunc = function(v)
						if (v == constKeep) then
							v = X4D_VENDORACTION_KEEP
						elseif (v == constSell) then
							v = X4D_VENDORACTION_SELL
						else
							v = X4D_VENDORACTION_NONE
						end
						X4D_Vendors.Settings:Set(itemType.Id, v)
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
			if (v == constKeep) then
				v = X4D_VENDORACTION_KEEP
			elseif (v == constSell) then
				v = X4D_VENDORACTION_SELL
			else
				v = X4D_VENDORACTION_NONE
			end
			for _, itemType in pairs(X4D.Items.ItemTypes) do
				X4D_Vendors.Settings:Set(itemType.Id, v)
			end
			ReloadUI()
			-- only necessary because i have no way to force LibAddonMenu to re-get/refresh all options
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
		text = "This section provides advanced options which override the simple keep/sell settings above. Hover the mouse over each option to see a useful description of behavior."
	})

	table.insert(panelControls, {
		type = "editbox",
		name = "Keep/Launder",
		tooltip = "Line-delimited list of Lua patterns, items matching these patterns will NOT be sold, and they will be laundered if you visit a fence and they are stolen items.\n|cFFFFFFITEM NAMES ARE NO LONGER SUPPORTED BY THE GAME, USE ID+OPTIONS INSTEAD.\n",
		isMultiline = true,
		width = "half",
		getFunc = function()
			local patterns = X4D_Vendors.Settings:Get("ForKeepsItemPatterns")
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
			X4D_Vendors.Settings:Set("ForKeepsItemPatterns", result)
		end,
	})

	table.insert(panelControls, {
		type = "editbox",
		name = "Sell",
		tooltip = "Line-delimited list of Lua patterns, items matching these patterns WILL BE SOLD.\n|cFFFFFFITEM NAMES ARE NO LONGER SUPPORTED BY THE GAME, USE ID+OPTIONS INSTEAD.\n|cFFFFC7Note that the 'For Keeps' item list will take precedence over the 'For Sale' list.",
		isMultiline = true,
		width = "half",
		getFunc = function()
			local patterns = X4D_Vendors.Settings:Get("ForSaleItemPatterns")
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
			X4D_Vendors.Settings:Set("ForSaleItemPatterns", result)
		end,
	})

	table.insert(panelControls, {
		type = "editbox",
		name = "Ignore",
		tooltip = "Line-delimited list of Lua patterns, items mathching these patterns will be ignored. Ignored items will NOT be laundered nor sold regardless of any other setting.\n|cFFFFFFITEM NAMES ARE NO LONGER SUPPORTED BY THE GAME, USE ID+OPTIONS INSTEAD.\n|cC7C7C7Special patterns exist, such as: STOLEN, item qualities like TRASH, NORMAL, MAGIC, ARCANE, ARTIFACT, LEGENDARY, item types like BLACKSMITHING, CLOTHIER, MATERIALS, etc",
		isMultiline = true,
		width = "half",
		getFunc = function()
			local patterns = X4D_Vendors.Settings:Get("IgnoredItemPatterns")
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
			X4D_Vendors.Settings:Set("IgnoredItemPatterns", result)
		end,
	})

	table.insert(panelControls, {
		type = "checkbox",
		name = "Okay to launder items worth 0" .. _goldIcon .. "?",
		tooltip = "When enabled, any stolen 'For Sale' items worth 0" .. _goldIcon .. " will be 'Laundered' instead. Once laundered if you visit a merchant they will be sold where you have a buyback option if you actually wanted to keep the item. |cFFFFFFThis often includes recipes/materials/bases/etc. If you attempt to sell a 'worthless item' the game will treat it differently and generate an error, which in turn causes X4D to halt until resolved by the user- this option works around THAT problem, and it only matters when you've added a for-sale pattern that results in the sale of stolen items.",
		width = "full",
		getFunc = function()
			return X4D.Vendors.Settings:Get("LaunderItemsWorth0Gold")
		end,
		setFunc = function()
			X4D.Vendors.Settings:Set("LaunderItemsWorth0Gold", not X4D.Vendors.Settings:Get("LaunderItemsWorth0Gold"))
		end,
	})

	table.insert(panelControls, {
		type = "checkbox",
		name = "Disable Fencing/Laundering?",
		tooltip = "You can disable Fencing/Laundering and still use with regular Vendors. Enabled by default since all Fence sales are final.",
		width = "full",
		getFunc = function()
			return not X4D.Vendors.Settings:Get("EnableFenceInteraction")
		end,
		setFunc = function()
			X4D.Vendors.Settings:Set("EnableFenceInteraction", not X4D.Vendors.Settings:Get("EnableFenceInteraction"))
		end,
	})


	LAM:RegisterOptionControls(
		"X4D_VENDORS_CPL",
		panelControls)
end

local function Register()
	EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnOpenStore", EVENT_OPEN_STORE, OnOpenStore)
	EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnCloseStore", EVENT_CLOSE_STORE, OnCloseStore)
	EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnOpenFence", EVENT_OPEN_FENCE, OnOpenFence)
	EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnCloseFence", EVENT_Close_FENCE, OnCloseFence)
	EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnOpenStable", EVENT_STABLE_INTERACT_START, OnOpenStable)
	EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnCloseStable", EVENT_STABLE_INTERACT_END, OnCloseStable)
end

EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnLoaded", EVENT_ADD_ON_LOADED, function(eventCode, addonName)
	if (addonName ~= X4D_Vendors.NAME) then
		return
	end
	local stopwatch = X4D.Stopwatch:StartNew()
	X4D.Log:Debug( { "OnAddonLoaded", eventCode, addonName }, X4D_Vendors.NAME)
	X4D_Vendors.DB = X4D.NPCs

	X4D_Vendors.Settings = X4D.Settings:Open(
	X4D_Vendors.NAME .. "_SV", {
		SettingsAre = "Per-Character",
		EnableFenceInteraction = true,
		LaunderItemsWorth0Gold = false, -- this no longer defaults to true, this results in less confusion for users
		ForKeepsItemPatterns =
		{
			-- items matching a "Launder" pattern will not be sold to a fence, and if they are stolen and you have visited a fence these items will be automatically laundered
			"lockpick",
			"MOTIF",
			"LEGENDARY",
			"ARTIFACT",
			"ARCANE",
		},
		ForSaleItemPatterns =
		{
			-- items matching a "for sale" pattern WILL BE SOLD without confirmation, this includes STOLEN items while at a vendor
			-- laundering (or "Launder") takes precedence over "for sale"
			"TRASH",
		},
		IgnoredItemPatterns =
		{
			-- items matching an "ignored" pattern will be left alone regardless of any other pattern or setting, consider this a "safety list" if you will
		}
	})

	InitializeSettingsUI()

	Register()

	X4D_Vendors.Took = stopwatch.ElapsedMilliseconds()
end)
