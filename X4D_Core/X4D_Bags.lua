local X4D_Bags = LibStub:NewLibrary("X4D_Bags", 1020)
if (not X4D_Bags) then
	return
end
local X4D = LibStub("X4D")
X4D.Bags = X4D_Bags

X4D_Bags.NAME = "X4D_Bags"
X4D_Bags.VERSION = "1.9"

local _bags = X4D.DB:Open()
local function InvalidateBags(...)
    -- reset state on player activate, ensure clean bag state on player login/out and zone change, other relevant events listed below
    _bags = X4D.DB:Open()
end

EVENT_MANAGER:RegisterForEvent(X4D_Bags.NAME, EVENT_PLAYER_ACTIVATED, InvalidateBags)
EVENT_MANAGER:RegisterForEvent(X4D_Bags.NAME, EVENT_INVENTORY_BAG_CAPACITY_CHANGED, InvalidateBags)

local X4D_Bag = {}

function X4D_Bag:New(bagId)
    local bag = {
        Id = bagId,
        SlotCount = GetBagSize(bagId),
        FreeCount = 0,
        Slots = { },
        PartialStackCount = 0,
        PartialStacks = { },
    }
    setmetatable(bag, { __call = nil, __index = X4D_Bag })
    local freeCount = 0
    for slotIndex = 0, (bag.SlotCount - 1) do
        local current = bag:PopulateSlot(slotIndex)
        if (current == nil or current.IsEmpty) then
            freeCount = freeCount + 1
        end
    end
    bag.FreeCount = freeCount
    return bag, bagId
end

function X4D_Bag:PopulateSlot(slotIndex)
    local previous = self.Slots[slotIndex]
    local slot
    local itemLink, itemColor, itemQuality, item, slotStackCount, slotLocked, slotEquipType = X4D.Items:FromBagSlot(self.Id, slotIndex)
    if (itemLink ~= nil and itemLink:len() > 0 and itemQuality ~= nil) then
        local _1, _2, itemLevel, enchantment1, enchantment2, enchantment3, _7, _8, _9, _10, _11, _12, _13, _14, _15, itemStyle, isCrafted, isBound, isStolen, condition, instanceData =
                X4D.Items:ParseLink(itemLink)  
        local instanceId = GetItemInstanceId(self.Id, slotIndex) or 0
        slot = {
            Id = slotIndex,
            IsEmpty = item == nil,
            Item = item,
            IsLocked = slotLocked == "1",
            ItemColor = itemColor,
            ItemQuality = tonumber(itemQuality or "0"),
            ItemLevel = tonumber(itemLevel or "0"),
            ItemStyle = tonumber(itemStyle or "0"),
            StackCount = tonumber(slotStackCount or "1") or 0,
            IsStolen = isStolen == "1",
            IsCrafted = isCrafted == "1",
            IsBound = isBound == "1",
            Condition = tonumber(condition or "0"),
            InstanceId = instanceId,
            ItemOptions = itemOptions,
            --
            SellPrice = item.SellPrice,
            LaunderPrice = item.LaunderPrice,
        }
        self.Slots[slotIndex] = slot
        if ((item.StackMax > 0) and (slot.StackCount < item.StackMax) and (not slot.IsStolen)) then -- TODO: remove IsStolen constraint and perform check whenever doing stacking/merging slot selections
            self.PartialStackCount = self.PartialStackCount + 1
            table.insert(self.PartialStacks, slot) -- TODO: remove partial stacks (loot addon) from this list when they are filled
        end
    else
        slot = {
            Id = slotIndex,
            IsEmpty = true,
        }
        self.Slots[slotIndex] = slot
    end
    if (slot.IsEmpty and not (previous == nil or previous.IsEmpty)) then
        self.FreeCount = self.FreeCount + 1
    elseif ((previous ~= nil and previous.IsEmpty) and not slot.IsEmpty) then
        self.FreeCount = self.FreeCount - 1
    end
    return slot, previous
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
        if (slot ~= nil) then
            if (slot.Item ~= nil) then
                slot.Item.SellPrice = item.data.sellPrice or slot.Item.SellPrice
                slot.Item.LaunderPrice = item.data.launderPrice or slot.Item.LaunderPrice
            end
            slot.SellPrice = item.data.sellPrice or slot.SellPrice
            slot.LaunderPrice = item.data.launderPrice or slot.LaunderPrice
        end
--        X4D.Log:Verbose(slot)
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

function X4D_Bags:GetBackpack(refresh)
    return self:GetBag(BAG_BACKPACK, refresh)
end

function X4D_Bags:GetBank(refresh)
    if (IsESOPlusSubscriber()) then
        return self:GetBag(BAG_BANK, refresh), self:GetBag(BAG_SUBSCRIBER_BANK, refresh)
    else
        return self:GetBag(BAG_BANK, refresh), nil
    end
end

function X4D_Bags:GetGuildBank(refresh)
    return self:GetBag(BAG_GUILDBANK, refresh)
end

function X4D_Bags:GetVirtual(refresh)
    return self:GetBag(BAG_VIRTUAL, refresh)
end

function X4D_Bags:GetNormalizedString(slot)
    if (slot == nil or slot.IsEmpty or slot.Item == nil) then
        return ""
    end
    local itemQualityString = X4D.Items.ToQualityString(slot.ItemQuality)
    local itemType = X4D.Items.ItemTypes[slot.Item.ItemType]
    local canonicalName
    if (itemType ~= nil and itemType.Canonical ~= nil and itemType.Canonical:len() > 0) then
        canonicalName = itemType.Canonical
    else
        canonicalName = "ITEMTYPE_NONE"
    end
    local normalized = string.format("L%02d %s %s/%s",
        slot.ItemLevel, itemQualityString:upper(), canonicalName, slot.Item.Id)
    if (slot.IsStolen) then
        normalized = "STOLEN " .. normalized
    end
    return normalized
end

--[[
TODO:

* EVENT_JUSTICE_STOLEN_ITEMS_REMOVED

* EVENT_INVENTORY_BAG_CAPACITY_CHANGED (*integer* _previousCapacity_, *integer* _currentCapacity_, *integer* _previousUpgrade_, *integer* _currentUpgrade_)
* EVENT_INVENTORY_BANK_CAPACITY_CHANGED (*integer* _previousCapacity_, *integer* _currentCapacity_, *integer* _previousUpgrade_, *integer* _currentUpgrade_)

* EVENT_INVENTORY_ITEMS_AUTO_TRANSFERRED_TO_CRAFT_BAG
* EVENT_INVENTORY_ITEM_DESTROYED (*[ItemUISoundCategory|#ItemUISoundCategory]* _itemSoundCategory_)
* EVENT_INVENTORY_ITEM_USED (*[ItemUISoundCategory|#ItemUISoundCategory]* _itemSoundCategory_)
* EVENT_INVENTORY_SINGLE_SLOT_UPDATE (*[Bag|#Bag]* _bagId_, *integer* _slotId_, *bool* _isNewItem_, *[ItemUISoundCategory|#ItemUISoundCategory]* _itemSoundCategory_, *integer* _inventoryUpdateReason_, *integer* _stackCountChange_)
* EVENT_INVENTORY_SLOT_LOCKED (*[Bag|#Bag]* _bagId_, *integer* _slotId_)
* EVENT_INVENTORY_SLOT_UNLOCKED (*[Bag|#Bag]* _bagId_, *integer* _slotId_)


-- TODO: when stacks are split, nothing is logged to chat until some other interaction coerces a refresh; prob missing an event handler
-- TODO: when items are destroyed, nothing is logged to chat, even after other interaction nothing appears in chat; hm..


]]
