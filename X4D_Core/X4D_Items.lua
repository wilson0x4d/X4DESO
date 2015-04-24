local X4D_Items = LibStub:NewLibrary("X4D_Items", 1001)
if (not X4D_Items) then
    return
end
local X4D = LibStub("X4D")
X4D.Items = X4D_Items

--region X4D_Item entity

local X4D_Item = {}

function X4D_Item:New(name, options)
    local normalizedName = name:lower()
    local item = {
        Name = normalizedName,
        Options = options,
        -- remainder of props are values we cannot obtain from 'options' and thus track separate
        ItemType = nil,
        SellPrice = 0, -- TODO: sell prices per-level
        LaunderPrice = 0, -- TODO: sell prices by level
        MarketPrice = 0, -- TODO: sell prices by level
        Icon58 = nil,
    }
    return item, normalizedName
end

setmetatable(X4D_Item, { __call = X4D_Item.New })

--endregion

--region X4D_Items DB

EVENT_MANAGER:RegisterForEvent("X4D_Items.DB", EVENT_ADD_ON_LOADED, function(event, name)
    if (name == "X4D_Core") then
        X4D_Items.DB = X4D.DB("X4D_Items.DB")
    end
end)

function X4D_Items:ParseLink(link)
    local options, name = link:match("|H1:item:(.-)|h[%[]*(.-)[%]]*|h")
    --d({link or 'no-link', options or 'no-options', name or 'no-name'})
    name = name:gsub("%^.*", ""):lower()
    if (options ~= nil) then
        local
            id, quality, levelReq, enchantType, 
            _5, _6, _7, _8,
            _9, _10, _11, _12,
            _13, _14, _15, style,
            isCraft, isBound, isStolen, condition,
            instanceData 
                = self:ParseOptions(options)
        return name, options, 
            id, quality, levelReq, enchantType, 
            _5, _6, _7, _8,
            _9, _10, _11, _12,
            _13, _14, _15, style,
            isCraft, isBound, isStolen, condition,
            instanceData
    end
    return name
end

function X4D_Items:ParseOptions(options)
    if (options == nil) then
        return nil
    else
        --[[
        local
            id, quality, levelReq, enchantType, 
            _5, _6, _7, _8,
            _9, _10, _11, _12,
            _13, _14, _15, style,
            isCraft, isBound, isStolen, condition,
            instanceData 
                = self:ParseOptions(options)
        ]]

        -- X4D.Debug:Verbose({options:match("(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-)")})
        return options:match("(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-):(.-)")
    end
end

function X4D_Items:FromLink(link)
    local name, options, itemId = self:ParseLink(link)
    if (itemId ~= nil) then
        local item = self.DB:Find(itemId)
        if (item == nil) then        
            item = X4D_Item(name, options)
            self.DB:Add(itemId, item)
        else
            if (options ~= nil) then
                if ((item.Options == nil) or (item.Options:len() < options:len())) then
                    item.Options = options
                end
            end
        end
    else
        return self:FromName(name)
    end
    return item, name
end

function X4D_Items:FromName(name)
    name = name:gsub("%^.*", ""):lower()    
    local item = self.DB
        :Where(function (item) return item.Name == name end)
        :FirstOrDefault()
    return item, name
end

function X4D_Items:FromBagSlot(bagId, slotIndex)
	local itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_BRACKETS)
    if (itemLink == nil or itemLink:len() == 0) then
        -- asked for empty slot, return nil
        return nil, nil, nil, nil
    end
    --itemLink = itemLink:gsub("(%[%l)", function(i) return i:upper() end):gsub("(%s%l)", function(i) return i:upper() end):gsub("%^[^%]]*", "")
    local itemColor, itemQuality = X4D.Colors:ExtractLinkColor(itemLink)
    --X4D.Debug:Warning({bagId, slotIndex, itemLink, itemColor, itemQuality})
	return itemLink, itemColor, itemQuality, self:FromLink(itemLink)
end

--endregion

X4D_Items.ItemQualities = {
    [ITEM_QUALITY_TRASH] = {
        Level = ITEM_QUALITY_TRASH,
        Name = "Trash",
        Canonical = "ITEM_QUALITY_TRASH",
    },
    [ITEM_QUALITY_NORMAL] = {
        Level = ITEM_QUALITY_NORMAL,
        Name = "Normal",
        Canonical = "ITEM_QUALITY_NORMAL",
    },
    [ITEM_QUALITY_MAGIC] = {
        Level = ITEM_QUALITY_MAGIC,
        Name = "Magic",
        Canonical = "ITEM_QUALITY_MAGIC",
    },
    [ITEM_QUALITY_ARCANE] = {
        Level = ITEM_QUALITY_ARCANE,
        Name = "Arcane",
        Canonical = "ITEM_QUALITY_ARCANE",
    },
    [ITEM_QUALITY_ARTIFACT] = {
        Level = ITEM_QUALITY_ARTIFACT,
        Name = "Artifact",
        Canonical = "ITEM_QUALITY_ARTIFACT",
    },
    [ITEM_QUALITY_LEGENDARY] = {
        Level = ITEM_QUALITY_LEGENDARY,
        Name = "Legendary",
        Canonical = "ITEM_QUALITY_LEGENDARY",
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
    "Alchemy",
    "Blacksmithing",
    "Clothing",
    "Consumables",
    "Enchanting",
    "Provisioning",
    "Styles",
    "Woodworking",
    "Misc",
    "AvA",
}

X4D_Items.ItemTypes = {
    [ITEMTYPE_ADDITIVE] = {
        Id = ITEMTYPE_ADDITIVE,
        Canonical = "ITEMTYPE_ADDITIVE",
        Name = "Additives",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_ALCHEMY_BASE] = {
        Id = ITEMTYPE_ALCHEMY_BASE,
        Canonical = "ITEMTYPE_ALCHEMY_BASE",
        Name = "Bases",
        Tooltip = nil,
        Group = "Alchemy"
    },
    [ITEMTYPE_ARMOR] = {
        Id = ITEMTYPE_ARMOR,
        Canonical = "ITEMTYPE_ARMOR",
        Name = "Armor",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_ARMOR_BOOSTER] = {
        Id = ITEMTYPE_ARMOR_BOOSTER,
        Canonical = "ITEMTYPE_ARMOR_BOOSTER",
        Name = "Armor Boosters",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_ARMOR_TRAIT] = {
        Id = ITEMTYPE_ARMOR_TRAIT,
        Canonical = "ITEMTYPE_ARMOR_TRAIT",
        Name = "Armor Traits",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_AVA_REPAIR] = {
        Id = ITEMTYPE_AVA_REPAIR,
        Canonical = "ITEMTYPE_AVA_REPAIR",
        Name = "Repairs",
        Tooltip = nil,
        Group = "AvA"
    },
    [ITEMTYPE_BLACKSMITHING_BOOSTER] = {
        Id = ITEMTYPE_BLACKSMITHING_BOOSTER,
        Canonical = "ITEMTYPE_BLACKSMITHING_BOOSTER",
        Name = "Boosters",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_BLACKSMITHING_MATERIAL] = {
        Id = ITEMTYPE_BLACKSMITHING_MATERIAL,
        Canonical = "ITEMTYPE_BLACKSMITHING_MATERIAL",
        Name = "Materials",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] = {
        Id = ITEMTYPE_BLACKSMITHING_RAW_MATERIAL,
        Canonical = "ITEMTYPE_BLACKSMITHING_RAW_MATERIAL",
        Name = "Raw Materials",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_CLOTHIER_BOOSTER] = {
        Id = ITEMTYPE_CLOTHIER_BOOSTER,
        Canonical = "ITEMTYPE_CLOTHIER_BOOSTER",
        Name = "Boosters",
        Tooltip = nil,
        Group = "Clothing"
    },
    [ITEMTYPE_CLOTHIER_MATERIAL] = {
        Id = ITEMTYPE_CLOTHIER_MATERIAL,
        Canonical = "ITEMTYPE_CLOTHIER_MATERIAL",
        Name = "Materials",
        Tooltip = nil,
        Group = "Clothing"
    },
    [ITEMTYPE_CLOTHIER_RAW_MATERIAL] = {
        Id = ITEMTYPE_CLOTHIER_RAW_MATERIAL,
        Canonical = "ITEMTYPE_CLOTHIER_RAW_MATERIAL",
        Name = "Raw Materials",
        Tooltip = nil,
        Group = "Clothing"
    },
    [ITEMTYPE_COLLECTIBLE] = {
        Id = ITEMTYPE_COLLECTIBLE,
        Canonical = "ITEMTYPE_COLLECTIBLE",
        Name = "Collectibles",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_CONTAINER] = {
        Id = ITEMTYPE_CONTAINER,
        Canonical = "ITEMTYPE_CONTAINER",
        Name = "Containers",
        Tooltip = nil,
        Group = nil -- will not appear in "Bank" list (as it results in errors)
    },
    [ITEMTYPE_COSTUME] = {
        Id = ITEMTYPE_COSTUME,
        Canonical = "ITEMTYPE_COSTUME",
        Name = "Costumes",
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
        Name = "Disguises",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_DRINK] = {
        Id = ITEMTYPE_DRINK,
        Canonical = "ITEMTYPE_DRINK",
        Name = "Drinks",
        Tooltip = nil,
        Group = "Consumables"
    },
    [ITEMTYPE_ENCHANTING_RUNE_ASPECT] = {
        Id = ITEMTYPE_ENCHANTING_RUNE_ASPECT,
        Canonical = "ITEMTYPE_ENCHANTING_RUNE_ASPECT",
        Name = "Aspect Runes",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_ENCHANTING_RUNE_ESSENCE] = {
        Id = ITEMTYPE_ENCHANTING_RUNE_ESSENCE,
        Canonical = "ITEMTYPE_ENCHANTING_RUNE_ESSENCE",
        Name = "Essence Runes",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_ENCHANTING_RUNE_POTENCY] = {
        Id = ITEMTYPE_ENCHANTING_RUNE_POTENCY,
        Canonical = "ITEMTYPE_ENCHANTING_RUNE_POTENCY",
        Name = "Potency Runes",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_ENCHANTMENT_BOOSTER] = {
        Id = ITEMTYPE_ENCHANTMENT_BOOSTER,
        Canonical = "ITEMTYPE_ENCHANTMENT_BOOSTER",
        Name = "Boosters",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_FLAVORING] = {
        Id = ITEMTYPE_FLAVORING,
        Canonical = "ITEMTYPE_FLAVORING",
        Name = "Flavors",
        Tooltip = nil,
        Group = "Provisioning"
    },
    [ITEMTYPE_FOOD] = {
        Id = ITEMTYPE_FOOD,
        Canonical = "ITEMTYPE_FOOD",
        Name = "Food",
        Tooltip = nil,
        Group = "Consumables"
    },
    [ITEMTYPE_GLYPH_ARMOR] = {
        Id = ITEMTYPE_GLYPH_ARMOR,
        Canonical = "ITEMTYPE_GLYPH_ARMOR",
        Name = "Armor Glyphs",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_GLYPH_JEWELRY] = {
        Id = ITEMTYPE_GLYPH_JEWELRY,
        Canonical = "ITEMTYPE_GLYPH_JEWELRY",
        Name = "Jewelry Glyphs",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_GLYPH_WEAPON] = {
        Id = ITEMTYPE_GLYPH_WEAPON,
        Canonical = "ITEMTYPE_GLYPH_WEAPON",
        Name = "Weapon Glyphs",
        Tooltip = nil,
        Group = "Enchanting"
    },
    [ITEMTYPE_INGREDIENT] = {
        Id = ITEMTYPE_INGREDIENT,
        Canonical = "ITEMTYPE_INGREDIENT",
        Name = "Ingredients",
        Tooltip = nil,
        Group = "Provisioning"
    },
    [ITEMTYPE_LOCKPICK] = {
        Id = ITEMTYPE_LOCKPICK,
        Canonical = "ITEMTYPE_LOCKPICK",
        Name = "Lockpicks",
        Tooltip = nil,
        Group = nil -- will not appear in "Bank" list (as it doesn"t do anything)
    },
    [ITEMTYPE_LURE] = {
        Id = ITEMTYPE_LURE,
        Canonical = "ITEMTYPE_LURE",
        Name = "Lures",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_MOUNT] = {
        Id = ITEMTYPE_MOUNT,
        Canonical = "ITEMTYPE_MOUNT",
        Name = "Mounts",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_NONE] = {
        Id = ITEMTYPE_NONE,
        Canonical = "ITEMTYPE_NONE",
        Name = "Unspecified",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_PLUG] = {
        Id = ITEMTYPE_PLUG,
        Canonical = "ITEMTYPE_PLUG",
        Name = "Plugs",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_POISON] = {
        Id = ITEMTYPE_POISON,
        Canonical = "ITEMTYPE_POISON",
        Name = "Poisons",
        Tooltip = nil,
        Group = "Consumables"
    },
    [ITEMTYPE_POTION] = {
        Id = ITEMTYPE_POTION,
        Canonical = "ITEMTYPE_POTION",
        Name = "Potions",
        Tooltip = nil,
        Group = "Consumables"
    },
    [ITEMTYPE_RACIAL_STYLE_MOTIF] = {
        Id = ITEMTYPE_RACIAL_STYLE_MOTIF,
        Canonical = "ITEMTYPE_RACIAL_STYLE_MOTIF",
        Name = "Motifs",
        Tooltip = nil,
        Group = "Styles"
    },
    [ITEMTYPE_RAW_MATERIAL] = {
        Id = ITEMTYPE_RAW_MATERIAL,
        Canonical = "ITEMTYPE_RAW_MATERIAL",
        Name = "Raw Materials",
        Tooltip = nil,
        Group = "Provisioning"
    },
    [ITEMTYPE_REAGENT] = {
        Id = ITEMTYPE_REAGENT,
        Canonical = "ITEMTYPE_REAGENT",
        Name = "Reagents",
        Tooltip = nil,
        Group = "Alchemy"
    },
    [ITEMTYPE_RECIPE] = {
        Id = ITEMTYPE_RECIPE,
        Canonical = "ITEMTYPE_RECIPE",
        Name = "Recipes",
        Tooltip = nil,
        Group = "Provisioning"
    },
    [ITEMTYPE_SIEGE] = {
        Id = ITEMTYPE_SIEGE,
        Canonical = "ITEMTYPE_SIEGE",
        Name = "Sieges",
        Tooltip = nil,
        Group = "AvA"
    },
    [ITEMTYPE_SOUL_GEM] = {
        Id = ITEMTYPE_SOUL_GEM,
        Canonical = "ITEMTYPE_SOUL_GEM",
        Name = "Soul Gems",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_SPELLCRAFTING_TABLET] = {
        Id = ITEMTYPE_SPELLCRAFTING_TABLET,
        Canonical = "ITEMTYPE_SPELLCRAFTING_TABLET",
        Name = "Spellcrafting Tablets",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_SPICE] = {
        Id = ITEMTYPE_SPICE,
        Canonical = "ITEMTYPE_SPICE",
        Name = "Spices",
        Tooltip = nil,
        Group = "Provisioning"
    },
    [ITEMTYPE_STYLE_MATERIAL] = {
        Id = ITEMTYPE_STYLE_MATERIAL,
        Canonical = "ITEMTYPE_STYLE_MATERIAL",
        Name = "Style Materials",
        Tooltip = nil,
        Group = "Styles"
    },
    [ITEMTYPE_TABARD] = {
        Id = ITEMTYPE_TABARD,
        Canonical = "ITEMTYPE_TABARD",
        Name = "Tabards",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_TOOL] = {
        Id = ITEMTYPE_TOOL,
        Canonical = "ITEMTYPE_TOOL",
        Name = "Tools",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_TRASH] = {
        Id = ITEMTYPE_TRASH,
        Canonical = "ITEMTYPE_TRASH",
        Name = "Trash",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_TROPHY] = {
        Id = ITEMTYPE_TROPHY,
        Canonical = "ITEMTYPE_TROPHY",
        Name = "Trophies",
        Tooltip = nil,
        Group = "Misc"
    },
    [ITEMTYPE_WEAPON] = {
        Id = ITEMTYPE_WEAPON,
        Canonical = "ITEMTYPE_WEAPON",
        Name = "Weapons",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_WEAPON_BOOSTER] = {
        Id = ITEMTYPE_WEAPON_BOOSTER,
        Canonical = "ITEMTYPE_WEAPON_BOOSTER",
        Name = "Weapon Boosters",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_WEAPON_TRAIT] = {
        Id = ITEMTYPE_WEAPON_TRAIT,
        Canonical = "ITEMTYPE_WEAPON_TRAIT",
        Name = "Weapon Traits",
        Tooltip = nil,
        Group = "Blacksmithing"
    },
    [ITEMTYPE_WOODWORKING_MATERIAL] = {
        Id = ITEMTYPE_WOODWORKING_MATERIAL,
        Canonical = "ITEMTYPE_WOODWORKING_MATERIAL",
        Name = "Materials",
        Tooltip = nil,
        Group = "Woodworking"
    },
    [ITEMTYPE_WOODWORKING_RAW_MATERIAL] = {
        Id = ITEMTYPE_WOODWORKING_RAW_MATERIAL,
        Canonical = "ITEMTYPE_WOODWORKING_RAW_MATERIAL",
        Name = "Raw Materials",
        Tooltip = nil,
        Group = "Woodworking"
    },
    [ITEMTYPE_WOODWORKING_BOOSTER] = {
        Id = ITEMTYPE_WOODWORKING_BOOSTER,
        Canonical = "ITEMTYPE_WOODWORKING_BOOSTER",
        Name = "Boosters",
        Tooltip = nil,
        Group = "Woodworking"
    },
}
