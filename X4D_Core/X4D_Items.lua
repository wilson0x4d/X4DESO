local X4D_Items = LibStub:NewLibrary('X4D_Items', 1001)
if (not X4D_Items) then
	return
end

local _itemQualities = {
    [0] = {
        Level = 0,
        Name = 'Junk',
        NormalizedName = 'JUNK',
    },
    [1] = {
        Level = 1,
        Name = 'Normal',
        NormalizedName = 'NORMAL',
    },
    [2] = {
        Level = 2,
        Name = 'Fine',
        NormalizedName = 'FINE',
    },
    [3] = {
        Level = 3,
        Name = 'Superior',
        NormalizedName = 'SUPERIOR',
    },
    [4] = {
        Level = 4,
        Name = 'Epic',
        NormalizedName = 'EPIC',
    },
    [5] = {
        Level = 5,
        Name = 'Legendary',
        NormalizedName = 'LEGENDARY',
    }
}

function X4D_Items.ToQualityString(v)    
    return _itemQualities[v].Name
end

function X4D_Items.FromQualityString(v)
    local normalized = tostring(v):upper()
	for level,quality in pairs(_itemQualities) do
        if (quality.NormalizedName == normalized) then
            return quality.Level
        end
    end
end

X4D_Items.ItemGroups = {
    'Alchemy',
    'Armor',
    'Blacksmithing',
    'Clothier',
    'Consumables',
    'Enchanting',
    'Provisioning',
    'Styles',
    'Woodworking',
    'Misc',
    'AvA',
}

X4D_Items.ItemTypes = {
    [ITEMTYPE_ADDITIVE] = {
        ItemType = ITEMTYPE_ADDITIVE,
        NormalizedName = 'ITEMTYPE_ADDITIVE',
        Name = 'Additives',
        Group = 'Misc'
    },
    [ITEMTYPE_ALCHEMY_BASE] = {
        ItemType = ITEMTYPE_ALCHEMY_BASE,
        NormalizedName = 'ITEMTYPE_ALCHEMY_BASE',
        Name = 'Bases',
        Group = 'Alchemy'
    },
    [ITEMTYPE_ARMOR] = {
        ItemType = ITEMTYPE_ARMOR,
        NormalizedName = 'ITEMTYPE_ARMOR',
        Name = 'Armor',
        Group = 'Armor'
    },
    [ITEMTYPE_ARMOR_BOOSTER] = {
        ItemType = ITEMTYPE_ARMOR_BOOSTER,
        NormalizedName = 'ITEMTYPE_ARMOR_BOOSTER',
        Name = 'Boosters',
        Group = 'Armor'
    },
    [ITEMTYPE_ARMOR_TRAIT] = {
        ItemType = ITEMTYPE_ARMOR_TRAIT,
        NormalizedName = 'ITEMTYPE_ARMOR_TRAIT',
        Name = 'Trait',
        Group = 'Armor'
    },
    [ITEMTYPE_AVA_REPAIR] = {
        ItemType = ITEMTYPE_AVA_REPAIR,
        NormalizedName = 'ITEMTYPE_AVA_REPAIR',
        Name = 'Repairs',
        Group = 'AvA'
    },
    [ITEMTYPE_BLACKSMITHING_BOOSTER] = {
        ItemType = ITEMTYPE_BLACKSMITHING_BOOSTER,
        NormalizedName = 'ITEMTYPE_BLACKSMITHING_BOOSTER',
        Name = 'Boosters',
        Group = 'Blacksmithing'
    },
    [ITEMTYPE_BLACKSMITHING_MATERIAL] = {
        ItemType = ITEMTYPE_BLACKSMITHING_MATERIAL,
        NormalizedName = 'ITEMTYPE_BLACKSMITHING_MATERIAL',
        Name = 'Materials',
        Group = 'Blacksmithing'
    },
    [ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] = {
        ItemType = ITEMTYPE_BLACKSMITHING_RAW_MATERIAL,
        NormalizedName = 'ITEMTYPE_BLACKSMITHING_RAW_MATERIAL',
        Name = 'Raw Materials',
        Group = 'Blacksmithing'
    },
    [ITEMTYPE_CLOTHIER_BOOSTER] = {
        ItemType = ITEMTYPE_CLOTHIER_BOOSTER,
        NormalizedName = 'ITEMTYPE_CLOTHIER_BOOSTER',
        Name = 'Boosters',
        Group = 'Clothier'
    },
    [ITEMTYPE_CLOTHIER_MATERIAL] = {
        ItemType = ITEMTYPE_CLOTHIER_MATERIAL,
        NormalizedName = 'ITEMTYPE_CLOTHIER_MATERIAL',
        Name = 'Materials',
        Group = 'Clothier'
    },
    [ITEMTYPE_CLOTHIER_RAW_MATERIAL] = {
        ItemType = ITEMTYPE_CLOTHIER_RAW_MATERIAL,
        NormalizedName = 'ITEMTYPE_CLOTHIER_RAW_MATERIAL',
        Name = 'Raw Materials',
        Group = 'Clothier'
    },
    [ITEMTYPE_COLLECTIBLE] = {
        ItemType = ITEMTYPE_COLLECTIBLE,
        NormalizedName = 'ITEMTYPE_COLLECTIBLE',
        Name = 'Collectibles',
        Group = 'Misc'
    },
    [ITEMTYPE_CONTAINER] = {
        ItemType = ITEMTYPE_CONTAINER,
        NormalizedName = 'ITEMTYPE_CONTAINER',
        Name = 'Containers',
        Group = 'Misc'
    },
    [ITEMTYPE_COSTUME] = {
        ItemType = ITEMTYPE_COSTUME,
        NormalizedName = 'ITEMTYPE_COSTUME',
        Name = 'Costumes',
        Group = 'Misc'
    },
    [ITEMTYPE_DEPRECATED] = {
        ItemType = ITEMTYPE_DEPRECATED,
        NormalizedName = 'ITEMTYPE_DEPRECATED',
        Name = 'Deprecated',
        Group = 'Misc'
    },
    [ITEMTYPE_DISGUISE] = {
        ItemType = ITEMTYPE_DISGUISE,
        NormalizedName = 'ITEMTYPE_DISGUISE',
        Name = 'Disguises',
        Group = 'Misc'
    },
    [ITEMTYPE_DRINK] = {
        ItemType = ITEMTYPE_DRINK,
        NormalizedName = 'ITEMTYPE_DRINK',
        Name = 'Drinks',
        Group = 'Consumables'
    },
    [ITEMTYPE_ENCHANTING_RUNE_ASPECT] = {
        ItemType = ITEMTYPE_ENCHANTING_RUNE_ASPECT,
        NormalizedName = 'ITEMTYPE_ENCHANTING_RUNE_ASPECT',
        Name = 'Aspect Runes',
        Group = 'Enchanting'
    },
    [ITEMTYPE_ENCHANTING_RUNE_ESSENCE] = {
        ItemType = ITEMTYPE_ENCHANTING_RUNE_ESSENCE,
        NormalizedName = 'ITEMTYPE_ENCHANTING_RUNE_ESSENCE',
        Name = 'Essence Runes',
        Group = 'Enchanting'
    },
    [ITEMTYPE_ENCHANTING_RUNE_POTENCY] = {
        ItemType = ITEMTYPE_ENCHANTING_RUNE_POTENCY,
        NormalizedName = 'ITEMTYPE_ENCHANTING_RUNE_POTENCY',
        Name = 'Potency Runes',
        Group = 'Enchanting'
    },
    [ITEMTYPE_ENCHANTMENT_BOOSTER] = {
        ItemType = ITEMTYPE_ENCHANTMENT_BOOSTER,
        NormalizedName = 'ITEMTYPE_ENCHANTMENT_BOOSTER',
        Name = 'Boosters',
        Group = 'Enchanting'
    },
    [ITEMTYPE_FLAVORING] = {
        ItemType = ITEMTYPE_FLAVORING,
        NormalizedName = 'ITEMTYPE_FLAVORING',
        Name = 'Flavors',
        Group = 'Provisioning'
    },
    [ITEMTYPE_FOOD] = {
        ItemType = ITEMTYPE_FOOD,
        NormalizedName = 'ITEMTYPE_FOOD',
        Name = 'Food',
        Group = 'Consumables'
    },
    [ITEMTYPE_GLYPH_ARMOR] = {
        ItemType = ITEMTYPE_GLYPH_ARMOR,
        NormalizedName = 'ITEMTYPE_GLYPH_ARMOR',
        Name = 'Armor Glyphs',
        Group = 'Enchanting'
    },
    [ITEMTYPE_GLYPH_JEWELRY] = {
        ItemType = ITEMTYPE_GLYPH_JEWELRY,
        NormalizedName = 'ITEMTYPE_GLYPH_JEWELRY',
        Name = 'Jewelry Glyphs',
        Group = 'Enchanting'
    },
    [ITEMTYPE_GLYPH_WEAPON] = {
        ItemType = ITEMTYPE_GLYPH_WEAPON,
        NormalizedName = 'ITEMTYPE_GLYPH_WEAPON',
        Name = 'Weapon Glyphs',
        Group = 'Enchanting'
    },
    [ITEMTYPE_INGREDIENT] = {
        ItemType = ITEMTYPE_INGREDIENT,
        NormalizedName = 'ITEMTYPE_INGREDIENT',
        Name = 'Ingredients',
        Group = 'Provisioning'
    },
    [ITEMTYPE_LOCKPICK] = {
        ItemType = ITEMTYPE_LOCKPICK,
        NormalizedName = 'ITEMTYPE_LOCKPICK',
        Name = 'Lockpicks',
        Group = 'Misc'
    },
    [ITEMTYPE_LURE] = {
        ItemType = ITEMTYPE_LURE,
        NormalizedName = 'ITEMTYPE_LURE',
        Name = 'Lures',
        Group = 'Misc'
    },
    [ITEMTYPE_MOUNT] = {
        ItemType = ITEMTYPE_MOUNT,
        NormalizedName = 'ITEMTYPE_MOUNT',
        Name = 'Mounts',
        Group = 'Misc'
    },
    [ITEMTYPE_NONE] = {
        ItemType = ITEMTYPE_NONE,
        NormalizedName = 'ITEMTYPE_NONE',
        Name = 'Unspecified',
        Group = 'Misc'
    },
    [ITEMTYPE_PLUG] = {
        ItemType = ITEMTYPE_PLUG,
        NormalizedName = 'ITEMTYPE_PLUG',
        Name = 'Plugs',
        Group = 'Misc'
    },
    [ITEMTYPE_POISON] = {
        ItemType = ITEMTYPE_POISON,
        NormalizedName = 'ITEMTYPE_POISON',
        Name = 'Poisons',
        Group = 'Consumables'
    },
    [ITEMTYPE_POTION] = {
        ItemType = ITEMTYPE_POTION,
        NormalizedName = 'ITEMTYPE_POTION',
        Name = 'Potions',
        Group = 'Consumables'
    },
    [ITEMTYPE_RACIAL_STYLE_MOTIF] = {
        ItemType = ITEMTYPE_RACIAL_STYLE_MOTIF,
        NormalizedName = 'ITEMTYPE_RACIAL_STYLE_MOTIF',
        Name = 'Motifs',
        Group = 'Styles'
    },
    [ITEMTYPE_RAW_MATERIAL] = {
        ItemType = ITEMTYPE_RAW_MATERIAL,
        NormalizedName = 'ITEMTYPE_RAW_MATERIAL',
        Name = 'Raw Materials',
        Group = 'Provisioning'
    },
    [ITEMTYPE_REAGENT] = {
        ItemType = ITEMTYPE_REAGENT,
        NormalizedName = 'ITEMTYPE_REAGENT',
        Name = 'Reagents',
        Group = 'Alchemy'
    },
    [ITEMTYPE_RECIPE] = {
        ItemType = ITEMTYPE_RECIPE,
        NormalizedName = 'ITEMTYPE_RECIPE',
        Name = 'Recipes',
        Group = 'Provisioning'
    },
    [ITEMTYPE_SIEGE] = {
        ItemType = ITEMTYPE_SIEGE,
        NormalizedName = 'ITEMTYPE_SIEGE',
        Name = 'Sieges',
        Group = 'AvA'
    },
    [ITEMTYPE_SOUL_GEM] = {
        ItemType = ITEMTYPE_SOUL_GEM,
        NormalizedName = 'ITEMTYPE_SOUL_GEM',
        Name = 'Soul Gems',
        Group = 'Misc'
    },
    [ITEMTYPE_SPELLCRAFTING_TABLET] = {
        ItemType = ITEMTYPE_SPELLCRAFTING_TABLET,
        NormalizedName = 'ITEMTYPE_SPELLCRAFTING_TABLET',
        Name = 'Spellcrafting Tablets',
        Group = 'Misc'
    },
    [ITEMTYPE_SPICE] = {
        ItemType = ITEMTYPE_SPICE,
        NormalizedName = 'ITEMTYPE_SPICE',
        Name = 'Spices',
        Group = 'Provisioning'
    },
    [ITEMTYPE_STYLE_MATERIAL] = {
        ItemType = ITEMTYPE_STYLE_MATERIAL,
        NormalizedName = 'ITEMTYPE_STYLE_MATERIAL',
        Name = 'Style Materials',
        Group = 'Styles'
    },
    [ITEMTYPE_TABARD] = {
        ItemType = ITEMTYPE_TABARD,
        NormalizedName = 'ITEMTYPE_TABARD',
        Name = 'Tabards',
        Group = 'Misc'
    },
    [ITEMTYPE_TOOL] = {
        ItemType = ITEMTYPE_TOOL,
        NormalizedName = 'ITEMTYPE_TOOL',
        Name = 'Tools',
        Group = 'Misc'
    },
    [ITEMTYPE_TRASH] = {
        ItemType = ITEMTYPE_TRASH,
        NormalizedName = 'ITEMTYPE_TRASH',
        Name = 'Trash',
        Group = 'Misc'
    },
    [ITEMTYPE_TROPHY] = {
        ItemType = ITEMTYPE_TROPHY,
        NormalizedName = 'ITEMTYPE_TROPHY',
        Name = 'Trophies',
        Group = 'Misc'
    },
    [ITEMTYPE_WEAPON] = {
        ItemType = ITEMTYPE_WEAPON,
        NormalizedName = 'ITEMTYPE_WEAPON',
        Name = 'Weapons',
        Group = 'Blacksmithing'
    },
    [ITEMTYPE_WEAPON_BOOSTER] = {
        ItemType = ITEMTYPE_WEAPON_BOOSTER,
        NormalizedName = 'ITEMTYPE_WEAPON_BOOSTER',
        Name = 'Weapon Boosters',
        Group = 'Blacksmithing'
    },
    [ITEMTYPE_WEAPON_TRAIT] = {
        ItemType = ITEMTYPE_WEAPON_TRAIT,
        NormalizedName = 'ITEMTYPE_WEAPON_TRAIT',
        Name = 'Weapon Traits',
        Group = 'Blacksmithing'
    },
    [ITEMTYPE_WOODWORKING_BOOSTER] = {
        ItemType = ITEMTYPE_WOODWORKING_BOOSTER,
        NormalizedName = 'ITEMTYPE_WOODWORKING_BOOSTER',
        Name = 'Boosters',
        Group = 'Woodworking'
    },
    [ITEMTYPE_WOODWORKING_MATERIAL] = {
        ItemType = ITEMTYPE_WOODWORKING_MATERIAL,
        NormalizedName = 'ITEMTYPE_WOODWORKING_MATERIAL',
        Name = 'Materials',
        Group = 'Woodworking'
    },
    [ITEMTYPE_WOODWORKING_RAW_MATERIAL] = {
        ItemType = ITEMTYPE_WOODWORKING_RAW_MATERIAL,
        NormalizedName = 'ITEMTYPE_WOODWORKING_RAW_MATERIAL',
        Name = 'Raw Materials',
        Group = 'Woodworking'
    },
}
