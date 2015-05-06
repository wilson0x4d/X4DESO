local X4D_Items = LibStub:NewLibrary("X4D_Items", 1001)
if (not X4D_Items) then
    return
end
local X4D = LibStub("X4D")
X4D.Items = X4D_Items

--region X4D_Item entity

local X4D_Item = {}

function X4D_Item:New(itemId, name)
    local normalizedName = name:lower()
    local item = {
        Id = tonumber(tostring(itemId)),
        Name = normalizedName,
        ItemType = nil,
        StackMax = nil,
        Icon58 = nil,
        SellPrice = nil, -- TODO: sell prices per-level
        LaunderPrice = nil, -- TODO: sell prices by per-level
        MarketPrice = nil, -- TODO: sell prices by per-level
    }
    setmetatable(item, { __index = X4D_Item })
    return item, itemId
end

setmetatable(X4D_Item, { __call = X4D_Item.New })

function X4D_Item:GetItemLink(quality, level, style, isCrafted, isBound, isStolen, condition, instanceData, enchantment1, enchantment2, enchantment3)
    if (quality == nil or type(quality) == "number") then
        quality = quality ~= nil and quality or 0
        level = level ~= nil and level or 0
        style = style ~= nil and style or 0
        isCrafted = (isCrafted ~= nil and isCrafted and 1) or 0
        isBound = (isBound ~= nil and isBound and 1) or 0
        isStolen = (isStolen ~= nil and isStolen and 1) or 0
        condition = condition ~= nil and condition or 0
        instanceData = instanceData ~= nil and instanceData or 0
        enchantment1 = enchantment1 ~= nil and enchantment1 or 0
        enchantment2 = enchantment2 ~= nil and enchantment2 or 0
        enchantment3 = enchantment3 ~= nil and enchantment3 or 0
        return string.format("|H1:item:%s:%s:%s:%s:%s:%s:0:0:0:0:0:0:0:0:0:%s:%s:%s:%s:%s:%s|h[%s]|h",
            self.Id, quality, level, enchantment1, enchantment2, enchantment3,
            style, isCrafted, isBound, isStolen, condition, instanceData,
            self.Name)
    else
        return string.format("|H1:item:%s|h[%s]|h",
            quality, -- this is assumed to contain a pre-constructed 'options' string, not a quality value
            self.Name)
    end
end

function X4D_Item:GetItemIconFilename()
    return X4D.Icons:FromIcon58(self.Icon58)
end

function X4D_Item:GetItemIcon()
    return X4D.Icons:CreateString58(self.Icon58)
end

--endregion

--region X4D_Items DB

EVENT_MANAGER:RegisterForEvent("X4D_Items.DB", EVENT_ADD_ON_LOADED, function(event, name)
    if (name == "X4D_Core") then
        X4D_Items.DB = X4D.DB:Open("X4D_Items.DB")
    end
end)

function X4D_Items:ParseLink(link)
    local options, name = link:match("|H1:item:(.-)|h[%[]*(.-)[%]]*|h")
    --d({link or 'no-link', options or 'no-options', name or 'no-name'})
    name = name:gsub("%^.*", ""):lower()
    if (options == nil) then
        options = ""
    end
    local
        itemId, itemQuality, levelReq, _4, _5, _6,
        _7, _8, _9, _10, _11, _12, _13, _14, _15, 
        style, isCrafted, isBound, isStolen, condition, instanceData 
            = self:ParseOptions(options)
    return name, options, 
        itemId, itemQuality, levelReq, _4, _5, _6,
        _7, _8, _9, _10, _11, _12, _13, _14, _15, 
        style, isCrafted, isBound, isStolen, condition, instanceData 
end

function X4D_Items:ParseOptions(options)
    if (options == nil) then
        return nil
    else
        --[[
        local
            itemId, itemQuality, levelReq, _4, _5, _6,
            _7, _8, _9, _10, _11, _12, _13, _14, _15, 
            style, isCrafted, isBound, isStolen, condition, instanceData 
                = self:ParseOptions(options)
        ]]

        return options:match("(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-)")
    end
end

function X4D_Items:FromLink(link)
    local item
    local name, options, itemId = self:ParseLink(link)
    if (itemId ~= nil) then
        item = self.DB:Find(itemId)
        if (item == nil) then        
            item = X4D_Item(itemId, name)
            self.DB:Add(itemId, item)
        end
    elseif (name ~= nil) then
        item = self:FromName(name)
    end
    if (item ~= nil) then
        setmetatable(item, { __index = X4D_Item })
    end
    return item, name
end

function X4D_Items:FromName(name)
    name = name:gsub("%^.*", ""):lower()
    local item = self.DB
        :Where(function (item) return item.Name == name end)
        :FirstOrDefault()
    if (item ~= nil) then
        setmetatable(item, { __index = X4D_Item })
    end
    return item, name
end

function X4D_Items:FromBagSlot(bagId, slotIndex)
	local itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_BRACKETS)
    if (itemLink == nil or itemLink:len() == 0) then
        -- ask for empty slot, get nil values
        return nil, nil, nil, nil, nil, nil, nil
    end
    local itemColor, itemQuality = X4D.Colors:ExtractLinkColor(itemLink)
    local item, itemName = self:FromLink(itemLink)
    if (item.ItemType == nil) then
        item.ItemType = GetItemType(bagId, slotIndex) or ITEMTYPE_NONE
    end
    if (item.StackMax == nil) then
        local stack, stackMax = GetSlotStackSize(bagId, slotIndex)
        item.StackMax = stackMax
    end
	local iconFilename, slotStackCount, sellPrice, meetsUsageRequirement, slotLocked, slotEquipType, itemStyle, quality = GetItemInfo(bagId, slotIndex)
    item.SellPrice = item.SellPrice or sellPrice or nil
    if (item.Icon58 == nil) then
        item.Icon58 = X4D.Icons:ToIcon58(iconFilename)
    end
    if (item ~= nil) then
        setmetatable(item, { __index = X4D_Item })
    end
	return itemLink, itemColor, itemQuality, item, slotStackCount, slotLocked, slotEquipType
end

--endregion

X4D_Items.ItemQualities = {
    [ITEM_QUALITY_TRASH] = {
        Level = ITEM_QUALITY_TRASH,
        Name = GetString(SI_ITEMQUALITY0),
        Canonical = "ITEM_QUALITY_TRASH",
        Color = X4D.Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_QUALITY_TRASH)):UnpackRGBA()),
    },
    [ITEM_QUALITY_NORMAL] = {
        Level = ITEM_QUALITY_NORMAL,
        Name = GetString(SI_ITEMQUALITY1),
        Canonical = "ITEM_QUALITY_NORMAL",
        Color = X4D.Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_QUALITY_NORMAL)):UnpackRGBA()),
    },
    [ITEM_QUALITY_MAGIC] = {
        Level = ITEM_QUALITY_MAGIC,
        Name = GetString(SI_ITEMQUALITY2),
        Canonical = "ITEM_QUALITY_MAGIC",
        Color = X4D.Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_QUALITY_MAGIC)):UnpackRGBA()),
    },
    [ITEM_QUALITY_ARCANE] = {
        Level = ITEM_QUALITY_ARCANE,
        Name = GetString(SI_ITEMQUALITY3),
        Canonical = "ITEM_QUALITY_ARCANE",
        Color = X4D.Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_QUALITY_ARCANE)):UnpackRGBA()),
    },
    [ITEM_QUALITY_ARTIFACT] = {
        Level = ITEM_QUALITY_ARTIFACT,
        Name = GetString(SI_ITEMQUALITY4),
        Canonical = "ITEM_QUALITY_ARTIFACT",
        Color = X4D.Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_QUALITY_ARTIFACT)):UnpackRGBA()),
    },
    [ITEM_QUALITY_LEGENDARY] = {
        Level = ITEM_QUALITY_LEGENDARY,
        Name = GetString(SI_ITEMQUALITY5),
        Canonical = "ITEM_QUALITY_LEGENDARY",
        Color = X4D.Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_QUALITY_LEGENDARY)):UnpackRGBA()),
    }
}

function X4D_Items.ToQualityString(v)    
    return X4D_Items.ItemQualities[v].Name
end

function X4D_Items.FromQualityString(v)
    local normalized = tostring(v):upper()
	for level,quality in pairs(X4D_Items.ItemQualities) do
        if (quality.Canonical:EndsWith(normalized)) then
            return quality.Level
        end
    end
end

X4D_Items.ItemGroups = {
    "Equipment",
    "Consumables",
    "Alchemy",
    "Blacksmithing",
    "Clothing",
    "Enchanting",
    "Provisioning",
    "Woodworking",
    "Styles",
    "Misc",
    "AvA",
}

X4D_Items.ItemTypes = {
    [ITEMTYPE_ADDITIVE] = {
        Id = ITEMTYPE_ADDITIVE,
        Canonical = "ITEMTYPE_ADDITIVE",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_ADDITIVE), --"Additives",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_ALCHEMY_BASE] = {
        Id = ITEMTYPE_ALCHEMY_BASE,
        Canonical = "ITEMTYPE_ALCHEMY_BASE",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_ALCHEMY_BASE), --"Bases",
        Tooltip = nil,
        Group = "Alchemy"
    },
    [ITEMTYPE_ARMOR] = {
        Id = ITEMTYPE_ARMOR,
        Canonical = "ITEMTYPE_ARMOR",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_ARMOR), --"Armor",
        Tooltip = nil,
        Group = "Equipment"
    },
    [ITEMTYPE_ARMOR_BOOSTER] = {
        Id = ITEMTYPE_ARMOR_BOOSTER,
        Canonical = "ITEMTYPE_ARMOR_BOOSTER",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_ARMOR_BOOSTER), --"Armor Boosters",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_ARMOR_TRAIT] = {
        Id = ITEMTYPE_ARMOR_TRAIT,
        Canonical = "ITEMTYPE_ARMOR_TRAIT",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_ARMOR_TRAIT), --"Armor Traits",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_AVA_REPAIR] = {
        Id = ITEMTYPE_AVA_REPAIR,
        Canonical = "ITEMTYPE_AVA_REPAIR",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_AVA_REPAIR), --"Siege Repairs",
        Tooltip = nil,
        Group = "AvA"
    },
    [ITEMTYPE_BLACKSMITHING_BOOSTER] = {
        Id = ITEMTYPE_BLACKSMITHING_BOOSTER,
        Canonical = "ITEMTYPE_BLACKSMITHING_BOOSTER",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_BLACKSMITHING_BOOSTER), --"Boosters",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_BLACKSMITHING_MATERIAL] = {
        Id = ITEMTYPE_BLACKSMITHING_MATERIAL,
        Canonical = "ITEMTYPE_BLACKSMITHING_MATERIAL",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_BLACKSMITHING_MATERIAL), --"Materials",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] = {
        Id = ITEMTYPE_BLACKSMITHING_RAW_MATERIAL,
        Canonical = "ITEMTYPE_BLACKSMITHING_RAW_MATERIAL",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_BLACKSMITHING_RAW_MATERIAL), --"Raw Materials",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_CLOTHIER_BOOSTER] = {
        Id = ITEMTYPE_CLOTHIER_BOOSTER,
        Canonical = "ITEMTYPE_CLOTHIER_BOOSTER",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_CLOTHIER_BOOSTER), --"Boosters",
        Tooltip = nil,
        Group = "Clothing"
    },
    [ITEMTYPE_CLOTHIER_MATERIAL] = {
        Id = ITEMTYPE_CLOTHIER_MATERIAL,
        Canonical = "ITEMTYPE_CLOTHIER_MATERIAL",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_CLOTHIER_MATERIAL), --"Materials",
        Tooltip = nil,
        Group = "Clothing"
    },
    [ITEMTYPE_CLOTHIER_RAW_MATERIAL] = {
        Id = ITEMTYPE_CLOTHIER_RAW_MATERIAL,
        Canonical = "ITEMTYPE_CLOTHIER_RAW_MATERIAL",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_CLOTHIER_RAW_MATERIAL), --"Raw Materials",
        Tooltip = nil,
        Group = "Clothing"
    },
    [ITEMTYPE_COLLECTIBLE] = {
        Id = ITEMTYPE_COLLECTIBLE,
        Canonical = "ITEMTYPE_COLLECTIBLE",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_COLLECTIBLE), --"Collectibles",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_CONTAINER] = {
        Id = ITEMTYPE_CONTAINER,
        Canonical = "ITEMTYPE_CONTAINER",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_CONTAINER), --"Containers",
        Tooltip = nil,
        Group = nil -- will not appear in "Bank" list (as it results in errors)
    },
    [ITEMTYPE_COSTUME] = {
        Id = ITEMTYPE_COSTUME,
        Canonical = "ITEMTYPE_COSTUME",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_COSTUME), --"Costumes",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_DEPRECATED] = {
        Id = ITEMTYPE_DEPRECATED,
        Canonical = "ITEMTYPE_DEPRECATED",
        Name = "Deprecated",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_DISGUISE] = {
        Id = ITEMTYPE_DISGUISE,
        Canonical = "ITEMTYPE_DISGUISE",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_DISGUISE), --"Disguises",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_DRINK] = {
        Id = ITEMTYPE_DRINK,
        Canonical = "ITEMTYPE_DRINK",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_DRINK), --"Drinks",
        Tooltip = nil,
        Group = "Consumables"
    },
    [ITEMTYPE_ENCHANTING_RUNE_ASPECT] = {
        Id = ITEMTYPE_ENCHANTING_RUNE_ASPECT,
        Canonical = "ITEMTYPE_ENCHANTING_RUNE_ASPECT",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_ENCHANTING_RUNE_ASPECT), --"Aspect Runes",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_ENCHANTING_RUNE_ESSENCE] = {
        Id = ITEMTYPE_ENCHANTING_RUNE_ESSENCE,
        Canonical = "ITEMTYPE_ENCHANTING_RUNE_ESSENCE",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_ENCHANTING_RUNE_ESSENCE), --"Essence Runes",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_ENCHANTING_RUNE_POTENCY] = {
        Id = ITEMTYPE_ENCHANTING_RUNE_POTENCY,
        Canonical = "ITEMTYPE_ENCHANTING_RUNE_POTENCY",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_ENCHANTING_RUNE_POTENCY), --"Potency Runes",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_ENCHANTMENT_BOOSTER] = {
        Id = ITEMTYPE_ENCHANTMENT_BOOSTER,
        Canonical = "ITEMTYPE_ENCHANTMENT_BOOSTER",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_ENCHANTMENT_BOOSTER), --"Boosters",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_FLAVORING] = {
        Id = ITEMTYPE_FLAVORING,
        Canonical = "ITEMTYPE_FLAVORING",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_FLAVORING), --"Flavors",
        Tooltip = nil,
        Group = "Provisioning"
    },
    [ITEMTYPE_FISH] = {
        Id = ITEMTYPE_FISH,
        Canonical = "ITEMTYPE_FISH",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_FISH), --"Fish",
        Tooltip = nil,
        Group = "Provisioning"
    },
    [ITEMTYPE_FOOD] = {
        Id = ITEMTYPE_FOOD,
        Canonical = "ITEMTYPE_FOOD",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_FOOD), --"Food",
        Tooltip = nil,
        Group = "Consumables"
    },
    [ITEMTYPE_GLYPH_ARMOR] = {
        Id = ITEMTYPE_GLYPH_ARMOR,
        Canonical = "ITEMTYPE_GLYPH_ARMOR",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_GLYPH_ARMOR), --"Armor Glyphs",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_GLYPH_JEWELRY] = {
        Id = ITEMTYPE_GLYPH_JEWELRY,
        Canonical = "ITEMTYPE_GLYPH_JEWELRY",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_GLYPH_JEWELRY), --"Jewelry Glyphs",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_GLYPH_WEAPON] = {
        Id = ITEMTYPE_GLYPH_WEAPON,
        Canonical = "ITEMTYPE_GLYPH_WEAPON",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_GLYPH_WEAPON), --"Weapon Glyphs",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_INGREDIENT] = {
        Id = ITEMTYPE_INGREDIENT,
        Canonical = "ITEMTYPE_INGREDIENT",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_INGREDIENT), --"Ingredients",
        Tooltip = nil,
        Group = "Provisioning"
    },
    [ITEMTYPE_LOCKPICK] = {
        Id = ITEMTYPE_LOCKPICK,
        Canonical = "ITEMTYPE_LOCKPICK",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_LOCKPICK), --"Lockpicks",
        Tooltip = nil,
        Group = nil -- will not appear in "Bank" list (as it doesn"t do anything)
    },
    [ITEMTYPE_LURE] = {
        Id = ITEMTYPE_LURE,
        Canonical = "ITEMTYPE_LURE",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_LURE), --"Lures",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_MOUNT] = {
        Id = ITEMTYPE_MOUNT,
        Canonical = "ITEMTYPE_MOUNT",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_MOUNT), --"Mounts",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_NONE] = {
        Id = ITEMTYPE_NONE,
        Canonical = "ITEMTYPE_NONE",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_NONE), --"Unspecified",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_PLUG] = {
        Id = ITEMTYPE_PLUG,
        Canonical = "ITEMTYPE_PLUG",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_PLUG), --"Plugs",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_POISON] = {
        Id = ITEMTYPE_POISON,
        Canonical = "ITEMTYPE_POISON",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_POISON), --"Poisons",
        Tooltip = nil,
        Group = "Consumables"
    },
    [ITEMTYPE_POTION] = {
        Id = ITEMTYPE_POTION,
        Canonical = "ITEMTYPE_POTION",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_POTION), --"Potions",
        Tooltip = nil,
        Group = "Consumables"
    },
    [ITEMTYPE_RACIAL_STYLE_MOTIF] = {
        Id = ITEMTYPE_RACIAL_STYLE_MOTIF,
        Canonical = "ITEMTYPE_RACIAL_STYLE_MOTIF",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_RACIAL_STYLE_MOTIF), --"Motifs",
        Tooltip = nil,
        Group = "Styles"
    },
    [ITEMTYPE_RAW_MATERIAL] = {
        Id = ITEMTYPE_RAW_MATERIAL,
        Canonical = "ITEMTYPE_RAW_MATERIAL",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_RAW_MATERIAL), --"Raw Materials",
        Tooltip = nil,
        Group = "Provisioning"
    },
    [ITEMTYPE_REAGENT] = {
        Id = ITEMTYPE_REAGENT,
        Canonical = "ITEMTYPE_REAGENT",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_REAGENT), --"Reagents",
        Tooltip = nil,
        Group = "Alchemy"
    },
    [ITEMTYPE_RECIPE] = {
        Id = ITEMTYPE_RECIPE,
        Canonical = "ITEMTYPE_RECIPE",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_RECIPE), --"Recipes",
        Tooltip = nil,
        Group = "Provisioning"
    },
    [ITEMTYPE_SIEGE] = {
        Id = ITEMTYPE_SIEGE,
        Canonical = "ITEMTYPE_SIEGE",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_SIEGE), --"Sieges",
        Tooltip = nil,
        Group = "AvA"
    },
    [ITEMTYPE_SOUL_GEM] = {
        Id = ITEMTYPE_SOUL_GEM,
        Canonical = "ITEMTYPE_SOUL_GEM",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_SOUL_GEM), --"Soul Gems",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_SPELLCRAFTING_TABLET] = {
        Id = ITEMTYPE_SPELLCRAFTING_TABLET,
        Canonical = "ITEMTYPE_SPELLCRAFTING_TABLET",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_SPELLCRAFTING_TABLET), --"Spellcrafting Tablets",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_SPICE] = {
        Id = ITEMTYPE_SPICE,
        Canonical = "ITEMTYPE_SPICE",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_SPICE), --"Spices",
        Tooltip = nil,
        Group = "Provisioning"
    },
    [ITEMTYPE_STYLE_MATERIAL] = {
        Id = ITEMTYPE_STYLE_MATERIAL,
        Canonical = "ITEMTYPE_STYLE_MATERIAL",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_STYLE_MATERIAL), --"Style Materials",
        Tooltip = nil,
        Group = "Styles"
    },
    [ITEMTYPE_TABARD] = {
        Id = ITEMTYPE_TABARD,
        Canonical = "ITEMTYPE_TABARD",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_TABARD), --"Tabards",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_TOOL] = {
        Id = ITEMTYPE_TOOL,
        Canonical = "ITEMTYPE_TOOL",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_TOOL), --"Tools",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_TRASH] = {
        Id = ITEMTYPE_TRASH,
        Canonical = "ITEMTYPE_TRASH",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_TRASH), --"Trash",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_TROPHY] = {
        Id = ITEMTYPE_TROPHY,
        Canonical = "ITEMTYPE_TROPHY",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_TROPHY), --"Trophies",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_WEAPON] = {
        Id = ITEMTYPE_WEAPON,
        Canonical = "ITEMTYPE_WEAPON",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_WEAPON), --"Weapons",
        Tooltip = nil,
        Group = "Equipment"
    },
    [ITEMTYPE_WEAPON_BOOSTER] = {
        Id = ITEMTYPE_WEAPON_BOOSTER,
        Canonical = "ITEMTYPE_WEAPON_BOOSTER",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_WEAPON_BOOSTER), --"Weapon Boosters",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_WEAPON_TRAIT] = {
        Id = ITEMTYPE_WEAPON_TRAIT,
        Canonical = "ITEMTYPE_WEAPON_TRAIT",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_WEAPON_TRAIT), --"Weapon Traits",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_WOODWORKING_MATERIAL] = {
        Id = ITEMTYPE_WOODWORKING_MATERIAL,
        Canonical = "ITEMTYPE_WOODWORKING_MATERIAL",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_WOODWORKING_MATERIAL), --"Materials",
        Tooltip = nil,
        Group = "Woodworking"
    },
    [ITEMTYPE_WOODWORKING_RAW_MATERIAL] = {
        Id = ITEMTYPE_WOODWORKING_RAW_MATERIAL,
        Canonical = "ITEMTYPE_WOODWORKING_RAW_MATERIAL",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_WOODWORKING_RAW_MATERIAL), --"Raw Materials",
        Tooltip = nil,
        Group = "Woodworking"
    },
    [ITEMTYPE_WOODWORKING_BOOSTER] = {
        Id = ITEMTYPE_WOODWORKING_BOOSTER,
        Canonical = "ITEMTYPE_WOODWORKING_BOOSTER",
        Name = GetString("SI_ITEMTYPE", ITEMTYPE_WOODWORKING_BOOSTER), --"Boosters",
        Tooltip = nil,
        Group = "Woodworking"
    },
}
