local X4D_Bags = LibStub:NewLibrary("X4D_Bags", 1000)
if (not X4D_Bags) then
	return
end
local X4D = LibStub("X4D")
X4D.Bags = X4D_Bags

X4D_Bags.NAME = "X4D_Bags"
X4D_Bags.VERSION = "1.0"

local _bags = X4D.DB()

local X4D_Bag = {}

local function GetSlotItemLink(bagId, slotId)
    local itemLink = GetItemLink(bagId, slotId, LINK_STYLE_BRACKETS):gsub("(%[%l)", function(i) return i:upper() end):gsub("(%s%l)", function(i) return i:upper() end):gsub("%^[^%]]*", "")
    local itemColor, itemQuality = X4D.Colors:ExtractLinkColor(itemLink)
    return itemLink, itemColor, itemQuality
end

function X4D_Bag:New(bagId)
    local numSlots = GetBagSize(bagId)
    local bagState = {
        Id = bagId,
        SlotCount = numSlots,
        Slots = { },
        FreeSlotCount = 0,
        FreeSlots = { },
        PartialSlotCount = 0,
        PartialSlots = { },
    }
    for slotId = 0,(bagState.SlotCount - 1) do
        local itemName = GetItemName(bagId, slotId)
        local iconFilename, itemStack, sellPrice, meetsUsageRequirement, locked, equipType, itemStyle, itemQuality = GetItemInfo(bagId, slotId)
        if (itemName ~= nil and itemName:len() > 0) then
            local stackCount, stackMax = GetSlotStackSize(bagId, slotId)
            local itemLink, itemColor, itemQuality = GetSlotItemLink(bagId, slotId)
            local itemQualityString = X4D.Items.ToQualityString(itemQuality)
            local itemType = X4D.Items.ItemTypes[GetItemType(bagId, slotId)] or X4D.Items.ItemTypes[ITEMTYPE_NONE]
            local itemLevel = GetItemLevel(bagId, slotId)
            local isStolen = IsItemStolen(bagId, slotId)

            local normalizedItemData = (" L" .. itemLevel .. " " .. itemQualityString .. " T" .. itemType.Id .. " " .. itemType.Canonical .. " "):upper() .. itemName:lower() .. " " .. itemLink
            if (isStolen) then
                normalizedItemData = " STOLEN" .. normalizedItemData
                -- TODO: handler for when "stolen" state of an item changes
            end
            local slot = {
                Id = slotId,
                IsEmpty = false,
                ItemIcon = X4D.Icons.Create(iconFilename),
                ItemName = itemName,
                ItemLink = itemLink,
                ItemColor = itemColor,
                ItemQuality = itemQuality,
                ItemLevel = itemLevel,
                ItemType = itemType,
                StackCount = stackCount,
                StackMax = stackMax,
                IsStolen = isStolen,
                Normalized = normalizedItemData
            }
            bagState.Slots[slotId] = slot
            if ((stackMax > 0) and(stackCount < stackMax) and(not isStolen)) then
                bagState.PartialSlotCount = bagState.PartialSlotCount + 1
                table.insert(bagState.PartialSlots, slot)
            end
        else
            bagState.FreeSlotCount = bagState.FreeSlotCount + 1
            local slot = {
                Id = slotId,
                IsEmpty = true,
                Normalized = "~ISEMPTY"
            }
            bagState.Slots[slotId] = slot
            table.insert(bagState.FreeSlots, slot)
        end
    end
    return bagState, bagId
end

setmetatable(X4D_Bag, { __call = X4D_Bag.New })

local _requiresRefresh = true
local function OnRefreshVisible(control, data, scrollList)
    if (not _requiresRefresh) then
        return
    end
    _requiresRefresh = true
    for _,item in pairs(scrollList.data) do
        local bag = X4D.Bags:GetBag(item.data.bagId)
        local slot = bag.Slots[item.data.slotIndex]
        slot.SellPrice = item.data.sellPrice
        slot.LaunderPrice = item.data.launderPrice
        X4D.Debug:Verbose(slot)
    end
end

function X4D_Bags:GetBag(bagId, refresh)
    if (bagId == nil) then
        return nil
    end
    local bag = nil
    if (not refresh) then 
        bag = _bags:Find(bagId)
    end
    if (bag == nil) then
        bag = X4D_Bag(bagId)
        _bags:Add(bag)
        ZO_ScrollList_RefreshVisible(ZO_PlayerInventoryBackpack, nil, OnRefreshVisible)
    end
    return bag
end

function X4D_Bags:GetInventoryBag(refresh)
    return X4D_Bags:GetBag(BAG_BACKPACK, refresh)
end

function X4D_Bags:GetBankBag(refresh)
    return X4D_Bags:GetBag(BAG_BANK, refresh)
end
