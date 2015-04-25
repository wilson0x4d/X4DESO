local X4D_Bags = LibStub:NewLibrary("X4D_Bags", 1000)
if (not X4D_Bags) then
	return
end
local X4D = LibStub("X4D")
X4D.Bags = X4D_Bags

X4D_Bags.NAME = "X4D_Bags"
X4D_Bags.VERSION = "1.0"

local _bags = X4D.DB:Create()

local X4D_Bag = {}

function X4D_Bag:New(bagId)
    local numSlots = GetBagSize(bagId)
    local bagState = {
        Id = bagId,
        SlotCount = numSlots,
        Slots = { },
        PartialSlotCount = 0,
        PartialSlots = { },
    }
    for slotIndex = 0,(bagState.SlotCount - 1) do
    	local itemLink, itemColor, itemQuality, item, slotStackCount, slotLocked, slotEquipType = X4D.Items:FromBagSlot(bagId, slotIndex)

        if (itemLink ~= nil and itemLink:len() > 0) then
            local _, itemOptions, _1, _2, itemLevel, enchantment1, enchantment2, enchantment3, _7, _8, _9, _10, _11, _12, _13, _14, _15, itemStyle, isCrafted, isBound, isStolen, condition, instanceId =
                    X4D.Items:ParseLink(itemLink)  
            --X4D.Debug:Warning{_, itemOptions, _1, _2, itemLevel, enchantment1, enchantment2, enchantment3, _7, _8, _9, _10, _11, _12, _13, _14, _15, itemStyle, isCrafted, isBound, isStolen, condition, instanceId}
            local slot = {
                Id = slotIndex,
                IsEmpty = false,
                Item = item,
                IsLocked = slotLocked == "1",
                ItemColor = itemColor,
                ItemQuality = tonumber(itemQuality or "0"),
                ItemLevel = tonumber(itemLevel or "0"),
                ItemStyle = tonumber(itemStyle or "0"),
                StackCount = tonumber(slotStackCount or "0"),
                IsStolen = isStolen == "1",
                IsCrafted = isCrafted == "1",
                IsBound = isBound == "1",
                Condition = tonumber(condition or "0"),
                InstanceId = instanceId,
                ItemOptions = itemOptions,
                --
                SellPrice = item.SellPrice,
                LaunderPrice = itemLink.LaunderPrice,
            }
            bagState.Slots[slotIndex] = slot
            if (item.StackMax ~= nil and slot.StackCount ~= nil and (item.StackMax > 0) and (slot.StackCount < item.StackMax) and (not slot.IsStolen)) then -- TODO: remove IsStolen constraint and perform check whenever doing stacking/merging slot selections
                bagState.PartialSlotCount = bagState.PartialSlotCount + 1
                table.insert(bagState.PartialSlots, slot)
            end
        else
            local slot = {
                Id = slotIndex,
                IsEmpty = true,
            }
            bagState.Slots[slotIndex] = slot
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
        slot.Item.SellPrice = slot.Item.SellPrice or item.data.sellPrice
        slot.Item.LaunderPrice = slot.Item.LaunderPrice or item.data.launderPrice
        --X4D.Debug:Verbose(slot)
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

function X4D_Bags:GetNormalizedString(slot)
    if (slot == nil or slot.IsEmpty) then
        return "ISEMPTY"
    end
    local itemQualityString = X4D.Items.ToQualityString(slot.ItemQuality)
    local itemType = X4D.Items.ItemTypes[slot.Item.ItemType]
    local normalized = ("L" .. slot.ItemLevel .. " " .. itemQualityString .. " " .. itemType.Canonical .. " "):upper() .. slot.Item.Name .. " " .. slot.Item:GetItemLink(slot.Options)
    if (slot.IsStolen) then
        normalized = "STOLEN " .. normalized
    end
    return normalized
end
