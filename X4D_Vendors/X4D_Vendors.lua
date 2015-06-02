local X4D_Vendors = LibStub:NewLibrary("X4D_Vendors", 1007)
if (not X4D_Vendors) then
	return
end
local X4D = LibStub("X4D")
X4D.Vendors = X4D_Vendors

X4D_Vendors.NAME = "X4D_Vendors"
X4D_Vendors.VERSION = "1.7"

local constUnspecified = X4D.Colors.Gray .. "Unspecified"
local constKeep = X4D.Colors.Deposit .. "Keep"
local constSell = X4D.Colors.Withdraw .. "Sell"

local _itemTypeChoices = {
    constUnspecified,
    constKeep,
    constSell,
}

EVENT_MANAGER:RegisterForEvent("X4D_Vendors.DB", EVENT_ADD_ON_LOADED, function(event, name)
    local stopwatch = X4D.Stopwatch:StartNew()
    if (name == "X4D_Vendors") then
        X4D_Vendors.DB = X4D.DB:Open("X4D_Vendors.DB")
    end
    X4D_Vendors.Took = stopwatch.ElapsedMilliseconds()
end)

--region X4D_Vendor 

local X4D_Vendor = {}

function X4D_Vendor:New(tag, salt)
    if (salt == nil) then 
        salt = ""
    end
    local unitName = GetRawUnitName(tag)
    if (unitName == nil or unitName:len() == 0) then
        unitName = tag
    end
    local key = "$" .. base58(sha1(unitName .. salt):FromHex())
    local position = { X4D.Cartography.PlayerX(), X4D.Cartography.PlayerY() }
    local proto = {
        Name = unitName,
        Position = { [1] = 0, [2] = 0, [3] = 0 },
        IsFence = false,
        --Items = {}, -- TODO: vendor search?
    }
	--setmetatable(proto, { __index = X4D_Vendor })
    return proto, key
end

setmetatable(X4D_Vendor, { __call = X4D_Vendor.New })

--endregion

--region Chat Callback

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

--endregion

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
                end )) then
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

X4D_VENDORACTION_NONE = 0
X4D_VENDORACTION_KEEP = 1
X4D_VENDORACTION_SELL = 2

local function GetPatternAction(slot)
    if (IsSlotIgnoredItem(slot)) then
        return X4D_VENDORACTION_NONE
    end
    --X4D.Log:Verbose{"GetPatternAction", slot.Id, slot.Item.Name}
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
                end )) then
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
    for _,groupName in pairs(X4D.Items.ItemGroups) do
        for _,itemType in pairs(X4D.Items.ItemTypes) do
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

local function ConductTransactions(vendor)
    -- TODO: add an option where once all fence laundering is exhausted, begin performing fence sales (or the other way around, based on user selection) with this, also: re-order transactions based on user setting ascending or descending.
    local laundersMax, laundersUsed = GetFenceLaunderTransactionInfo()
    local sellsMax, sellsUsed = GetFenceSellTransactionInfo()
    local itemTypeActions = GetItemTypeActions()
    local bag = X4D.Bags:GetBackpackBag(true)
    if (bag ~= nil) then
        for slotIndex = 0, bag.SlotCount do
            local slot = bag.Slots[slotIndex]
                --if (slot ~= nil and slot.Item ~= nil) then
                --    X4D.Log:Verbose{"ConductTransactions", slot.Id, X4D.Bags:GetNormalizedString(slot)}
                --end
            if (slot ~= nil and not slot.IsEmpty) then
                if (not IsSlotIgnoredItem(slot)) then
                    local vendorAction = GetPatternAction(slot)
                    local itemTypeAction = itemTypeActions[slot.Item.ItemType]
                    if ((vendorAction == X4D_VENDORACTION_KEEP or itemTypeAction == X4D_VENDORACTION_KEEP) or (slot.IsStolen and (vendorAction == X4D_VENDORACTION_SELL) and (slot.LaunderPrice == 0) and X4D_Vendors.Settings:Get("LaunderItemsWorth0Gold"))) then
                        --X4D.Log:Verbose({"Launder Codes for "..slot.Item:GetItemLink(slot.ItemOptions), vendorAction, itemTypeAction, (slot.IsStolen and (vendorAction == X4D_VENDORACTION_SELL) and (slot.LaunderPrice == 0) and X4D_Vendors.Settings:Get("LaunderItemsWorth0Gold"))}, "X4D_Vendors")
                        if (vendor.IsFence and slot.IsStolen) then
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
                                        local message = zo_strformat("<<1>> <<2>><<t:3>> <<4>>x<<5>><<6>>",
                                            "Laundered", slot.Item:GetItemIcon(), slot.Item:GetItemLink(slot.ItemOptions), X4D.Colors.StackCount, slot.StackCount, statement)
			                            InvokeChatCallback(slot.ItemColor, message)
                                    end
                                end
                            end
                        end
                    elseif (vendorAction == X4D_VENDORACTION_SELL or itemTypeAction == X4D_VENDORACTION_SELL) then
                        if (vendor.IsFence == slot.IsStolen) then
                            if ((not vendor.IsFence) or (vendor.IsFence and (sellsUsed <= sellsMax))) then
                                --X4D.Log:Verbose({"Sales Codes for "..slot.Item:GetItemLink(slot.ItemOptions), vendorAction, itemTypeAction, ((vendorAction == X4D_VENDORACTION_SELL) and (slot.LaunderPrice == 0) and X4D_Vendors.Settings:Get("LaunderItemsWorth0Gold"))}, "X4D_Vendors")
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
                                local message = zo_strformat("<<1>> <<2>><<t:3>> <<4>>x<<5>><<6>>",
                                    "Sold", slot.Item:GetItemIcon(), slot.Item:GetItemLink(slot.ItemOptions), X4D.Colors.StackCount, slot.StackCount, statement)
			                    InvokeChatCallback(slot.ItemColor, message)
                            end
                        end
                    --else
                        --X4D.Log:Verbose({"NonAction Codes for "..slot.Item:GetItemLink(slot.ItemOptions), vendorAction, itemTypeAction, ((vendorAction == X4D_VENDORACTION_SELL) and (slot.LaunderPrice == 0) and X4D_Vendors.Settings:Get("LaunderItemsWorth0Gold"))}, "X4D_Vendors")
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
        local balance = "" -- TODO: report balance-on-hand? seems a little chatty at that point
        InvokeChatCallback(X4D.Colors.X4D, "Vendor Debits: " .. X4D.Colors.Gold .. _debits .. _goldIcon .. X4D.Colors.X4D .. " Credits: " .. X4D.Colors.Gold .. _credits .. _goldIcon .. " " .. delta .. balance)
    end
end

local function UpdateVendorPositionData(vendor)
    vendor.MapId = X4D.Cartography.MapIndex()
    vendor.ZoneIndex = X4D.Cartography.ZoneIndex()
    vendor.Position = { X4D.Cartography.PlayerX(), X4D.Cartography.PlayerY() }
    X4D.Log:Verbose(vendor)
end

local function OnOpenFence()
    _debits = 0
    _credits = 0
    local vendor = X4D_Vendors:GetVendor("interact", tostring(X4D.Cartography.ZoneIndex()))
    vendor.IsFence = true
    UpdateVendorPositionData(vendor)
    ConductTransactions(vendor)
    ReportEarnings()
end

local function OnOpenStore()
    _debits = 0
    _credits = 0
    local vendor = X4D_Vendors:GetVendor("interact", tostring(X4D.Cartography.ZoneIndex()))
    vendor.IsFence = false
    UpdateVendorPositionData(vendor)
    X4D.Async:CreateTimer(function (timer, state)
        timer:Stop()
        ConductTransactions(vendor)
        ReportEarnings()
    end):Start(337, {}, "X4D_Vendors::ConductTransactions")
end

local function OnCloseStore()
    -- force update of bag snapshots on close
    local inventoryState = X4D.Bags:GetBackpackBag(true)
    local bankState = X4D.Bags:GetBankBag(true)
end

local function OnItemBuy(eventId, entryName, entryType, entryQuantity, money, specialCurrencyType1, specialCurrencyInfo1, specialCurrencyQuantity1, specialCurrencyType2, specialCurrencyInfo2, specialCurrencyQuantity2, itemSoundCategory)
    -- TODO: need items db to implement this properly, needs more time
    --X4D.Log:Verbose({eventId, entryName, entryType, entryQuantity, money, specialCurrencyType1, specialCurrencyInfo1, specialCurrencyQuantity1, specialCurrencyType2, specialCurrencyInfo2, specialCurrencyQuantity2, itemSoundCategory})
end

local function OnItemBuyBack(eventId, itemName, itemQuantity, money, itemSoundCategory)
    -- TODO: need items db to implement this properly, needs more time
    --X4D.Log:Verbose({ eventId, itemName, itemQuantity, money, itemSoundCategory })
end

local function OnItemSale(eventId, itemName, quantity, money)
    -- TODO: need items db to implement this properly, needs more time
    -- X4D.Log:Verbose({eventId, itemName, quantity, money})
end


function X4D_Vendors:GetVendor(tag)
    local unitName = GetRawUnitName(tag)
    if (unitName == nil or unitName:len() == 0) then
        unitName = tag
    end
    local key = "$" .. base58(sha1(unitName):FromHex())
    local vendor = self.DB:Find(key)
    if (vendor == nil) then
        vendor = X4D_Vendor(tag)
        self.DB:Add(key, vendor)
    end
    return vendor, key
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


    table.insert(panelControls, {
        type = "editbox",
        name = "'For Keeps' Items",
        tooltip = "Line-delimited list of 'For Keeps' patterns, items matching these patterns will NOT be sold, and they will be laundered if you visit a fence and they are stolen items. |cFFFFFFItem names should be all lower-case, special tokens should be all upper-case.",
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
        name = "'For Sale' Items",
        tooltip = "Line-delimited list of 'For Sale' item patterns, items matching these patterns WILL BE SOLD. |cFFFFFFItem names should be all lower-case, special tokens should be all upper-case. |cFFFFC7Note that the 'For Keeps' item list will take precedence over the 'For Sale' list.",
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
        name = "'Ignored' Items",
        tooltip = "Line-delimited list of items to ignore using 'lua patterns'case. Ignored items will NOT be laundered nor sold regardless of any other setting. |cFFFFFFItem names should be all lower-case, special tokens should be all upper-case. \n |cC7C7C7Special patterns exist, such as: STOLEN, item qualities like TRASH, NORMAL, MAGIC, ARCANE, ARTIFACT, LEGENDARY, item types like BLACKSMITHING, CLOTHIER, MATERIALS, etc",
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
        name = "Launder any 'For Sale' worth 0" .. _goldIcon, 
        tooltip = "When enabled, any stolen 'For Sale' items worth 0" .. _goldIcon .. " will be laundered instead. Once laundered if you visit a merchant they will be sold where you have a buyback option if you actually wanted the item. |cFFFFFFThis often includes recipes/materials/bases/etc. If you attempt to sell a 'worthless item' the game will treat it differently and generate an error, which in turn causes X4D to halt until resolved by the user- this option works around THAT problem, and it only matters when you've added a for-sale pattern that results in the sale of stolen items.", 
        width = "half",
        getFunc = function() 
            return X4D.Vendors.Settings:Get("LaunderItemsWorth0Gold")
        end,
        setFunc = function()
            X4D.Vendors.Settings:Set("LaunderItemsWorth0Gold", not X4D.Vendors.Settings:Get("LaunderItemsWorth0Gold")) 
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
                table.insert(panelControls, {
                    type = "dropdown",
                    name = itemType.Name,
                    tooltip = itemType.Tooltip or itemType.Canonical,
                    choices = _itemTypeChoices,
                    getFunc = function() 
                        local v = X4D_Vendors.Settings:Get(itemType.Id) or 0
                        if (v == 1) then
                            return constLaunder
                        elseif (v == 2) then
                            return constSell
                        else
                            return constUnspecified
                        end
                    end,
                    setFunc = function(v)
                        if (v == constLaunder) then
                            v = 1
                        elseif (v == constSell) then
                            v = 2
                        else
                            v = 0
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
        tooltip = "Use this to reset ALL item type settings to a specific value. This only exists to make reconfiguration a little less tedious.",
        choices = _itemTypeChoices,
        getFunc = function() 
            local v = 0
            if (v == 1) then
                return constLaunder
            elseif (v == 2) then
                return constSell
            else
                return constUnspecified
            end
        end,
        setFunc = function(v)
            if (v == constLaunder) then
                v = 1
            elseif (v == constSell) then
                v = 2
            else
                v = 0
            end
            for _,itemType in pairs(X4D.Items.ItemTypes) do
                X4D_Vendors.Settings:Set(itemType.Id, v)
            end
            ReloadUI() -- only necessary because i have no way to force LibAddonMenu to re-get/refresh all options
        end,
        width = "half",
    })

    -- endregion

    LAM:RegisterOptionControls(
        "X4D_VENDORS_CPL",
        panelControls
    )
end

local function Register()
    EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnOpenStore", EVENT_OPEN_STORE, OnOpenStore)
    EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnOpenFence", EVENT_OPEN_FENCE, OnOpenFence)
    EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnCloseStore", EVENT_CLOSE_STORE, OnCloseStore)
    --TODO: EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnItemBuy", EVENT_BUY_RECEIPT, OnItemBuy)
    --TODO: EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnItemBuyBack", EVENT_BUYBACK_RECEIPT, OnItemBuyBack)
    --TODO: EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnItemSale", EVENT_SELL_RECEIPT, OnItemSale)
end

EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnLoaded", EVENT_ADD_ON_LOADED, function(event, name)
	if (name ~= X4D_Vendors.NAME) then
		return
	end	

	X4D_Vendors.Settings = X4D.Settings(
		X4D_Vendors.NAME .. "_SV",
		{
            SettingsAre = "Per-Character",
            LaunderItemsWorth0Gold = true,
            ForKeepsItemPatterns =
            {
                -- items matching a "Launder" pattern will not be sold, and if they are stolen and you have visited a fence these items will be automatically laundered                
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
                "ITEMTYPE_NONE",
            },
            IgnoredItemPatterns = 
            {
                -- items matching an "ignored" pattern will be left alone regardless of any other pattern or setting, consider this a "safety list" if you will
            },
        })

    InitializeSettingsUI()

    Register()
end)
