local X4D_Items = LibStub:NewLibrary('X4D_Items', 1001)
if (not X4D_Items) then
	return
end

local _itemQualities = {
    [0] = {
        Level = 0,
        Name = 'Junk',
        Canonical = 'JUNK',
    },
    [1] = {
        Level = 1,
        Name = 'Normal',
        Canonical = 'NORMAL',
    },
    [2] = {
        Level = 2,
        Name = 'Fine',
        Canonical = 'FINE',
    },
    [3] = {
        Level = 3,
        Name = 'Superior',
        Canonical = 'SUPERIOR',
    },
    [4] = {
        Level = 4,
        Name = 'Epic',
        Canonical = 'EPIC',
    },
    [5] = {
        Level = 5,
        Name = 'Legendary',
        Canonical = 'LEGENDARY',
    }
}

function X4D_Items.ToQualityString(v)    
    return _itemQualities[v].Name
end

function X4D_Items.FromQualityString(v)
    local normalized = tostring(v):upper()
	for level,quality in pairs(_itemQualities) do
        if (quality.Canonical == normalized) then
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
        Id = ITEMTYPE_ADDITIVE,
        Canonical = 'ITEMTYPE_ADDITIVE',
        Name = 'Additives',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_ALCHEMY_BASE] = {
        Id = ITEMTYPE_ALCHEMY_BASE,
        Canonical = 'ITEMTYPE_ALCHEMY_BASE',
        Name = 'Bases',
        Tooltip = nil,
        Group = 'Alchemy'
    },
    [ITEMTYPE_ARMOR] = {
        Id = ITEMTYPE_ARMOR,
        Canonical = 'ITEMTYPE_ARMOR',
        Name = 'Armor',
        Tooltip = nil,
        Group = 'Armor'
    },
    [ITEMTYPE_ARMOR_BOOSTER] = {
        Id = ITEMTYPE_ARMOR_BOOSTER,
        Canonical = 'ITEMTYPE_ARMOR_BOOSTER',
        Name = 'Boosters',
        Tooltip = nil,
        Group = 'Armor'
    },
    [ITEMTYPE_ARMOR_TRAIT] = {
        Id = ITEMTYPE_ARMOR_TRAIT,
        Canonical = 'ITEMTYPE_ARMOR_TRAIT',
        Name = 'Trait',
        Tooltip = nil,
        Group = 'Armor'
    },
    [ITEMTYPE_AVA_REPAIR] = {
        Id = ITEMTYPE_AVA_REPAIR,
        Canonical = 'ITEMTYPE_AVA_REPAIR',
        Name = 'Repairs',
        Tooltip = nil,
        Group = 'AvA'
    },
    [ITEMTYPE_BLACKSMITHING_BOOSTER] = {
        Id = ITEMTYPE_BLACKSMITHING_BOOSTER,
        Canonical = 'ITEMTYPE_BLACKSMITHING_BOOSTER',
        Name = 'Boosters',
        Tooltip = nil,
        Group = 'Blacksmithing'
    },
    [ITEMTYPE_BLACKSMITHING_MATERIAL] = {
        Id = ITEMTYPE_BLACKSMITHING_MATERIAL,
        Canonical = 'ITEMTYPE_BLACKSMITHING_MATERIAL',
        Name = 'Materials',
        Tooltip = nil,
        Group = 'Blacksmithing'
    },
    [ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] = {
        Id = ITEMTYPE_BLACKSMITHING_RAW_MATERIAL,
        Canonical = 'ITEMTYPE_BLACKSMITHING_RAW_MATERIAL',
        Name = 'Raw Materials',
        Tooltip = nil,
        Group = 'Blacksmithing'
    },
    [ITEMTYPE_CLOTHIER_BOOSTER] = {
        Id = ITEMTYPE_CLOTHIER_BOOSTER,
        Canonical = 'ITEMTYPE_CLOTHIER_BOOSTER',
        Name = 'Boosters',
        Tooltip = nil,
        Group = 'Clothier'
    },
    [ITEMTYPE_CLOTHIER_MATERIAL] = {
        Id = ITEMTYPE_CLOTHIER_MATERIAL,
        Canonical = 'ITEMTYPE_CLOTHIER_MATERIAL',
        Name = 'Materials',
        Tooltip = nil,
        Group = 'Clothier'
    },
    [ITEMTYPE_CLOTHIER_RAW_MATERIAL] = {
        Id = ITEMTYPE_CLOTHIER_RAW_MATERIAL,
        Canonical = 'ITEMTYPE_CLOTHIER_RAW_MATERIAL',
        Name = 'Raw Materials',
        Tooltip = nil,
        Group = 'Clothier'
    },
    [ITEMTYPE_COLLECTIBLE] = {
        Id = ITEMTYPE_COLLECTIBLE,
        Canonical = 'ITEMTYPE_COLLECTIBLE',
        Name = 'Collectibles',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_CONTAINER] = {
        Id = ITEMTYPE_CONTAINER,
        Canonical = 'ITEMTYPE_CONTAINER',
        Name = 'Containers',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_COSTUME] = {
        Id = ITEMTYPE_COSTUME,
        Canonical = 'ITEMTYPE_COSTUME',
        Name = 'Costumes',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_DEPRECATED] = {
        Id = ITEMTYPE_DEPRECATED,
        Canonical = 'ITEMTYPE_DEPRECATED',
        Name = 'Deprecated',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_DISGUISE] = {
        Id = ITEMTYPE_DISGUISE,
        Canonical = 'ITEMTYPE_DISGUISE',
        Name = 'Disguises',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_DRINK] = {
        Id = ITEMTYPE_DRINK,
        Canonical = 'ITEMTYPE_DRINK',
        Name = 'Drinks',
        Tooltip = nil,
        Group = 'Consumables'
    },
    [ITEMTYPE_ENCHANTING_RUNE_ASPECT] = {
        Id = ITEMTYPE_ENCHANTING_RUNE_ASPECT,
        Canonical = 'ITEMTYPE_ENCHANTING_RUNE_ASPECT',
        Name = 'Aspect Runes',
        Tooltip = nil,
        Group = 'Enchanting'
    },
    [ITEMTYPE_ENCHANTING_RUNE_ESSENCE] = {
        Id = ITEMTYPE_ENCHANTING_RUNE_ESSENCE,
        Canonical = 'ITEMTYPE_ENCHANTING_RUNE_ESSENCE',
        Name = 'Essence Runes',
        Tooltip = nil,
        Group = 'Enchanting'
    },
    [ITEMTYPE_ENCHANTING_RUNE_POTENCY] = {
        Id = ITEMTYPE_ENCHANTING_RUNE_POTENCY,
        Canonical = 'ITEMTYPE_ENCHANTING_RUNE_POTENCY',
        Name = 'Potency Runes',
        Tooltip = nil,
        Group = 'Enchanting'
    },
    [ITEMTYPE_ENCHANTMENT_BOOSTER] = {
        Id = ITEMTYPE_ENCHANTMENT_BOOSTER,
        Canonical = 'ITEMTYPE_ENCHANTMENT_BOOSTER',
        Name = 'Boosters',
        Tooltip = nil,
        Group = 'Enchanting'
    },
    [ITEMTYPE_FLAVORING] = {
        Id = ITEMTYPE_FLAVORING,
        Canonical = 'ITEMTYPE_FLAVORING',
        Name = 'Flavors',
        Tooltip = nil,
        Group = 'Provisioning'
    },
    [ITEMTYPE_FOOD] = {
        Id = ITEMTYPE_FOOD,
        Canonical = 'ITEMTYPE_FOOD',
        Name = 'Food',
        Tooltip = nil,
        Group = 'Consumables'
    },
    [ITEMTYPE_GLYPH_ARMOR] = {
        Id = ITEMTYPE_GLYPH_ARMOR,
        Canonical = 'ITEMTYPE_GLYPH_ARMOR',
        Name = 'Armor Glyphs',
        Tooltip = nil,
        Group = 'Enchanting'
    },
    [ITEMTYPE_GLYPH_JEWELRY] = {
        Id = ITEMTYPE_GLYPH_JEWELRY,
        Canonical = 'ITEMTYPE_GLYPH_JEWELRY',
        Name = 'Jewelry Glyphs',
        Tooltip = nil,
        Group = 'Enchanting'
    },
    [ITEMTYPE_GLYPH_WEAPON] = {
        Id = ITEMTYPE_GLYPH_WEAPON,
        Canonical = 'ITEMTYPE_GLYPH_WEAPON',
        Name = 'Weapon Glyphs',
        Tooltip = nil,
        Group = 'Enchanting'
    },
    [ITEMTYPE_INGREDIENT] = {
        Id = ITEMTYPE_INGREDIENT,
        Canonical = 'ITEMTYPE_INGREDIENT',
        Name = 'Ingredients',
        Tooltip = nil,
        Group = 'Provisioning'
    },
    [ITEMTYPE_LOCKPICK] = {
        Id = ITEMTYPE_LOCKPICK,
        Canonical = 'ITEMTYPE_LOCKPICK',
        Name = 'Lockpicks',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_LURE] = {
        Id = ITEMTYPE_LURE,
        Canonical = 'ITEMTYPE_LURE',
        Name = 'Lures',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_MOUNT] = {
        Id = ITEMTYPE_MOUNT,
        Canonical = 'ITEMTYPE_MOUNT',
        Name = 'Mounts',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_NONE] = {
        Id = ITEMTYPE_NONE,
        Canonical = 'ITEMTYPE_NONE',
        Name = 'Unspecified',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_PLUG] = {
        Id = ITEMTYPE_PLUG,
        Canonical = 'ITEMTYPE_PLUG',
        Name = 'Plugs',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_POISON] = {
        Id = ITEMTYPE_POISON,
        Canonical = 'ITEMTYPE_POISON',
        Name = 'Poisons',
        Tooltip = nil,
        Group = 'Consumables'
    },
    [ITEMTYPE_POTION] = {
        Id = ITEMTYPE_POTION,
        Canonical = 'ITEMTYPE_POTION',
        Name = 'Potions',
        Tooltip = nil,
        Group = 'Consumables'
    },
    [ITEMTYPE_RACIAL_STYLE_MOTIF] = {
        Id = ITEMTYPE_RACIAL_STYLE_MOTIF,
        Canonical = 'ITEMTYPE_RACIAL_STYLE_MOTIF',
        Name = 'Motifs',
        Tooltip = nil,
        Group = 'Styles'
    },
    [ITEMTYPE_RAW_MATERIAL] = {
        Id = ITEMTYPE_RAW_MATERIAL,
        Canonical = 'ITEMTYPE_RAW_MATERIAL',
        Name = 'Raw Materials',
        Tooltip = nil,
        Group = 'Provisioning'
    },
    [ITEMTYPE_REAGENT] = {
        Id = ITEMTYPE_REAGENT,
        Canonical = 'ITEMTYPE_REAGENT',
        Name = 'Reagents',
        Tooltip = nil,
        Group = 'Alchemy'
    },
    [ITEMTYPE_RECIPE] = {
        Id = ITEMTYPE_RECIPE,
        Canonical = 'ITEMTYPE_RECIPE',
        Name = 'Recipes',
        Tooltip = nil,
        Group = 'Provisioning'
    },
    [ITEMTYPE_SIEGE] = {
        Id = ITEMTYPE_SIEGE,
        Canonical = 'ITEMTYPE_SIEGE',
        Name = 'Sieges',
        Tooltip = nil,
        Group = 'AvA'
    },
    [ITEMTYPE_SOUL_GEM] = {
        Id = ITEMTYPE_SOUL_GEM,
        Canonical = 'ITEMTYPE_SOUL_GEM',
        Name = 'Soul Gems',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_SPELLCRAFTING_TABLET] = {
        Id = ITEMTYPE_SPELLCRAFTING_TABLET,
        Canonical = 'ITEMTYPE_SPELLCRAFTING_TABLET',
        Name = 'Spellcrafting Tablets',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_SPICE] = {
        Id = ITEMTYPE_SPICE,
        Canonical = 'ITEMTYPE_SPICE',
        Name = 'Spices',
        Tooltip = nil,
        Group = 'Provisioning'
    },
    [ITEMTYPE_STYLE_MATERIAL] = {
        Id = ITEMTYPE_STYLE_MATERIAL,
        Canonical = 'ITEMTYPE_STYLE_MATERIAL',
        Name = 'Style Materials',
        Tooltip = nil,
        Group = 'Styles'
    },
    [ITEMTYPE_TABARD] = {
        Id = ITEMTYPE_TABARD,
        Canonical = 'ITEMTYPE_TABARD',
        Name = 'Tabards',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_TOOL] = {
        Id = ITEMTYPE_TOOL,
        Canonical = 'ITEMTYPE_TOOL',
        Name = 'Tools',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_TRASH] = {
        Id = ITEMTYPE_TRASH,
        Canonical = 'ITEMTYPE_TRASH',
        Name = 'Trash',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_TROPHY] = {
        Id = ITEMTYPE_TROPHY,
        Canonical = 'ITEMTYPE_TROPHY',
        Name = 'Trophies',
        Tooltip = nil,
        Group = 'Misc'
    },
    [ITEMTYPE_WEAPON] = {
        Id = ITEMTYPE_WEAPON,
        Canonical = 'ITEMTYPE_WEAPON',
        Name = 'Weapons',
        Tooltip = nil,
        Group = 'Blacksmithing'
    },
    [ITEMTYPE_WEAPON_BOOSTER] = {
        Id = ITEMTYPE_WEAPON_BOOSTER,
        Canonical = 'ITEMTYPE_WEAPON_BOOSTER',
        Name = 'Weapon Boosters',
        Tooltip = nil,
        Group = 'Blacksmithing'
    },
    [ITEMTYPE_WEAPON_TRAIT] = {
        Id = ITEMTYPE_WEAPON_TRAIT,
        Canonical = 'ITEMTYPE_WEAPON_TRAIT',
        Name = 'Weapon Traits',
        Tooltip = nil,
        Group = 'Blacksmithing'
    },
    [ITEMTYPE_WOODWORKING_BOOSTER] = {
        Id = ITEMTYPE_WOODWORKING_BOOSTER,
        Canonical = 'ITEMTYPE_WOODWORKING_BOOSTER',
        Name = 'Boosters',
        Tooltip = nil,
        Group = 'Woodworking'
    },
    [ITEMTYPE_WOODWORKING_MATERIAL] = {
        Id = ITEMTYPE_WOODWORKING_MATERIAL,
        Canonical = 'ITEMTYPE_WOODWORKING_MATERIAL',
        Name = 'Materials',
        Tooltip = nil,
        Group = 'Woodworking'
    },
    [ITEMTYPE_WOODWORKING_RAW_MATERIAL] = {
        Id = ITEMTYPE_WOODWORKING_RAW_MATERIAL,
        Canonical = 'ITEMTYPE_WOODWORKING_RAW_MATERIAL',
        Name = 'Raw Materials',
        Tooltip = nil,
        Group = 'Woodworking'
    },
}
