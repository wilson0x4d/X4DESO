local X4D_Vendors = LibStub:NewLibrary("X4D_Vendors", 1000)
if (not X4D_Vendors) then
	return
end
local X4D = LibStub("X4D")
X4D.Vendors = X4D_Vendors

X4D_Vendors.NAME = "X4D_Vendors"
X4D_Vendors.VERSION = "1.0"

EVENT_MANAGER:RegisterForEvent("X4D_Vendors.DB", EVENT_ADD_ON_LOADED, function(event, name)
    if (name == "X4D_Vendors") then
        X4D_Vendors.DB = X4D.DB("X4D_Vendors.DB")
    end
end)

--region X4D_Vendor 

local X4D_Vendor = {}

function X4D_Vendor:New(tag)
    local unitName = GetRawUnitName(tag)
    if (unitName == nil or unitName:len() == 0) then
        unitName = tag
    end
    local normalizedName = unitName:gsub("%^.*", "")
    local key = "$" .. base58(sha1(normalizedName):FromHex())
    local position = { GetMapPlayerPosition("player") }
    local proto = {
        Name = normalizedName,
        Position = { [1] = 0, [2] = 0, [3] = 0 },
        IsFence = false,
        --Items = {}, -- TODO: vendor search?
    }
	--setmetatable(proto, { __index = X4D_Vendor })
    return proto, key
end

setmetatable(X4D_Vendor, { __call = X4D_Vendor.New })

--endregion

--region Emit Callback

local function DefaultEmitCallback(color, text)
	d(color .. text)
end

X4D_Vendors.EmitCallback = DefaultEmitCallback

function X4D_Vendors:RegisterCallback(callback)
	if (callback ~= nil) then
		X4D_Vendors.EmitCallback = callback
	else
		X4D_Vendors.EmitCallback = DefaultEmitCallback
	end
end

function X4D_Vendors:UnregisterCallback(callback)
	if (X4D_Vendors.EmitCallback == callback) then
		self:RegisterCallback(nil)
	end
end

local function InvokeCallbackSafe(color, text)
	local callback = X4D_Vendors.EmitCallback
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

local function GetVendorAction(slot)
    local vendorAction = X4D_VENDORACTION_NONE
    if (not slot.IsEmpty) then
        local forKeepsPatterns = X4D_Vendors.Settings:Get("ForKeepsItemPatterns")
        for i = 1, #forKeepsPatterns do
            local pattern = forKeepsPatterns[i]
            if (not pcall( function()
                    if (slot.Normalized:find(pattern)) then
                        vendorAction = X4D_VENDORACTION_KEEP
                    end
                end )) then
                InvokeEmitCallbackSafe(X4D.Colors.SYSTEM, "(Vendors) Bad 'For Keeps' Item Pattern: |cFF7777" .. pattern)
            end
            if (vendorAction ~= X4D_VENDORACTION_NONE) then
                return vendorAction
            end
        end
        local forSalePatterns = X4D_Vendors.Settings:Get("ForSaleItemPatterns")
        for i = 1, #forSalePatterns do
            local pattern = forSalePatterns[i]
            if (not pcall( function()
                    if (slot.Normalized:find(pattern)) then
                        vendorAction = X4D_VENDORACTION_SELL
                    end
                end )) then
                InvokeEmitCallbackSafe(X4D.Colors.SYSTEM, "(Vendors) Bad 'For Sale' Item Pattern: |cFF7777" .. pattern)
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
local _goldIcon = X4D.Icons.Create("EsoUI/Art/currency/currency_gold.dds")

local function ConductTransactions(vendor)
    local bag = X4D.Bags:GetInventoryBag(true)
    if (bag ~= nil) then
        for _,slot in pairs(bag.Slots) do
            if (slot ~= nil and not slot.IsEmpty) then
                -- pattern match item names for sales
                local vendorAction = GetVendorAction(slot)
                if (vendorAction == X4D_VENDORACTION_KEEP) then
                    if (vendor.IsFence and slot.IsStolen) then
                        local laundersMax, laundersUsed = GetFenceLaunderTransactionInfo()
                        if (laundersUsed < laundersMax) then
                            LaunderItem(bag.Id, slot.Id, slot.StackCount)
                        end
                        slot.IsEmpty = false
                        local statement = ""
                        if (slot.LaunderPrice ~= nil) then
                            local totalPrice = (slot.LaunderPrice * slot.StackCount)
                            statement = X4D.Colors.Subtext .. " for " .. X4D.Colors.Red .. "(-" .. totalPrice .. _goldIcon .. ")"
                            _debits = _debits + totalPrice
                        end
	                    InvokeCallbackSafe(slot.ItemColor, "Laundered " .. slot.ItemIcon .. slot.ItemLink .. X4D.Colors.StackCount .. " x" .. slot.StackCount .. statement)
                    end
                elseif (vendorAction == X4D_VENDORACTION_SELL) then
                    if ((not (vendor.IsFence and slot.IsStolen)) or (vendor.IsFence and slot.IsStolen)) then
                        if (vendor.IsFence) then
                            if (slot.IsStolen) then
                                local sellsMax, sellsUsed = GetFenceSellTransactionInfo()
                                if (sellsUsed < sellsMax) then
                                    CallSecureProtected("PickupInventoryItem", bag.Id, slot.Id, slot.StackCount)
                                    CallSecureProtected("PlaceInStoreWindow")
                                end
                            end
                        else
                            CallSecureProtected("PickupInventoryItem", bag.Id, slot.Id, slot.StackCount)
                            CallSecureProtected("PlaceInStoreWindow")
                        end
                        slot.IsEmpty = true
                        slot.Normalized = "~ISEMPTY"
                        local statement = ""
                        if (slot.SellPrice ~= nil) then
                            local totalPrice = (slot.SellPrice * slot.StackCount)
                            statement = X4D.Colors.Subtext .. " for " .. X4D.Colors.Gold .. totalPrice .. _goldIcon
                            _credits = _credits + totalPrice
                        end
	                    InvokeCallbackSafe(slot.ItemColor, "Sold " .. slot.ItemIcon .. slot.ItemLink .. X4D.Colors.StackCount .. " x" .. slot.StackCount .. statement)
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
        InvokeCallbackSafe(X4D.Colors.X4D, "Vendor Debits: " .. X4D.Colors.Gold .. _debits .. _goldIcon .. X4D.Colors.X4D .. " Credits: " .. X4D.Colors.Gold .. _credits .. _goldIcon .. " " .. delta .. balance)
    end
end

local function OnOpenFence()
    _debits = 0
    _credits = 0
    local vendor = X4D_Vendors:GetVendor("interact")
    vendor.IsFence = true
    vendor.Position = { GetMapPlayerPosition("player") }
    X4D.Debug:Verbose(vendor)
    ConductTransactions(vendor)
    ReportEarnings()
end

local function OnOpenStore()
    _debits = 0
    _credits = 0
    local vendor = X4D_Vendors:GetVendor("interact")
    vendor.IsFence = false
    vendor.Position = { GetMapPlayerPosition("player") }
    X4D.Debug:Verbose(vendor)
    ConductTransactions(vendor)
    ReportEarnings()
end

local function OnCloseStore()
end

local function OnItemBuy(eventId, entryName, entryType, entryQuantity, money, specialCurrencyType1, specialCurrencyInfo1, specialCurrencyQuantity1, specialCurrencyType2, specialCurrencyInfo2, specialCurrencyQuantity2, itemSoundCategory)
    -- TODO: need items db to implement this properly, needs more time
    --X4D.Debug:Verbose({eventId, entryName, entryType, entryQuantity, money, specialCurrencyType1, specialCurrencyInfo1, specialCurrencyQuantity1, specialCurrencyType2, specialCurrencyInfo2, specialCurrencyQuantity2, itemSoundCategory})
end

local function OnItemBuyBack(eventId, itemName, itemQuantity, money, itemSoundCategory)
    -- TODO: need items db to implement this properly, needs more time
    --X4D.Debug:Verbose({ eventId, itemName, itemQuantity, money, itemSoundCategory })
end

local function OnItemSale(eventId, itemName, quantity, money)
    -- TODO: need items db to implement this properly, needs more time
    -- X4D.Debug:Verbose({eventId, itemName, quantity, money})
end


function X4D_Vendors:GetVendor(tag)
    local unitName = GetRawUnitName(tag)
    if (unitName == nil or unitName:len() == 0) then
        unitName = tag
    end
    local normalizedName = unitName:gsub("%^.*", "")
    local key = "$" .. base58(sha1(normalizedName):FromHex())
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
        name = "X4D |cFFAE19Vendors",
    })

    local panelControls = { }

    table.insert(panelControls, {
        type = "editbox",
        name = "For Keeps",
        tooltip = "Line-delimited list of 'For Keeps' items using 'lua patterns'. 'For Keeps' items will not be sold, and if you visit a fence and they are stolen items they will be laundered for you.",
        isMultiline = true,
        width = "full",
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
        name = "For Sale",
        tooltip = "Line-delimited list of 'For Sale' items using 'lua patterns'. 'For Sale' items WILL BE SOLD. |cC7C7C7Note that the 'For Keeps' list takes precedence over 'For Sale' list.",
        isMultiline = true,
        width = "full",
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

    LAM:RegisterOptionControls(
        "X4D_VENDORS_CPL",
        panelControls
    )
end

local function Register()
    EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnOpenStore", EVENT_OPEN_STORE, OnOpenStore)
    EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnOpenFence", EVENT_OPEN_FENCE, OnOpenFence)
    --EVENT_MANAGER:RegisterForEvent("X4D_Vendors_OnCloseStore", EVENT_CLOSE_STORE, OnCloseStore)
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
            SettingsAre = "Account-Wide",
            ForKeepsItemPatterns =
            {
                -- items matching a "for keeps" pattern will not be sold, and if they are stolen and you have visited a fence these items will be automatically laundered                
                "lockpick",
                "LEGENDARY",
                "ARTIFACT",
                "ARCANE",
                "STOLEN",
            },
            ForSaleItemPatterns =
            {
                -- items matching a "for sale" pattern WILL BE SOLD without confirmation, this includes STOLEN items while at a vendor
                -- laundering (or "for keeps") takes precedence over "for sale"
                "TRASH",
                "ITEMTYPE_NONE",
            },
        })

    InitializeSettingsUI()

    Register()
end)
