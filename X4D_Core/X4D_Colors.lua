local X4D_Colors = LibStub:NewLibrary("X4D_Colors", 1001)
if (not X4D_Colors) then
	return
end
local X4D = LibStub("X4D")
X4D.Colors = X4D_Colors

X4D_Colors.X4D = "|cFFAE19"

X4D_Colors.Deposit = "|cFFAE19"
X4D_Colors.Withdraw = "|cAA33FF"

X4D_Colors.SYSTEM = "|cFFFF00"
X4D_Colors.TRACE_VERBOSE = "|cC0C0C0"
X4D_Colors.TRACE_INFORMATION = "|c6666FF"
X4D_Colors.TRACE_WARNING = "|cCC6600"
X4D_Colors.TRACE_ERROR = "|c990000"
X4D_Colors.TRACE_CRITICAL = "|cFF0033"

X4D_Colors.BagSpaceLow = "|cFFd00b"
X4D_Colors.BagSpaceFull = "|cAA0000"
X4D_Colors.StackCount = "|cFFFFFF"

X4D_Colors.Subtext = "|c5C5C5C"

X4D_Colors.VP = "|cAA33FF"
X4D_Colors.XP = "|cAA33FF"
X4D_Colors.AP = "|cAA33FF"

X4D_Colors.Red = "|cFF3333"
X4D_Colors.Green = "|c33FF33"
X4D_Colors.Blue = "|c3333FF"

X4D_Colors.Yellow = "|cFFFF00"
X4D_Colors.Cyan = "|c00FFFF"
X4D_Colors.Magenta = "|cFF00FF"

X4D_Colors.Orange = "|cFF9900"

X4D_Colors.White = "|cFFFFFF"
X4D_Colors.Gray = "|cC5C5C5"
X4D_Colors.Black = "|c000000"



function X4D_Colors:Create(r, g, b, a)
	return "|c" .. X4D.Convert.DEC2HEX(r * 255) .. X4D.Convert.DEC2HEX(g * 255) .. X4D.Convert.DEC2HEX(b * 255)
end

function X4D_Colors:Parse(color)
	return (X4D.Convert.HEX2DEC(color, 3) / 255), (X4D.Convert.HEX2DEC(color, 5) / 255), (X4D.Convert.HEX2DEC(color, 7) / 255), 1
end

function X4D_Colors:Lerp(colorFrom, colorTo, percent)
	if (percent == nil) then
		percent = 50
	end
    if (colorTo == nil) then
        colorTo = "|cFFFFFF" -- White
    end
    if (colorFrom == nil) then
        colorFrom = X4D_Colors.SYSTEM
    end
	local factor = (percent / 100)
	local rFrom, gFrom, bFrom, aFrom = X4D_Colors:Parse(colorFrom)
	local rTo, gTo, bTo, aTo = X4D_Colors:Parse(colorTo)
    local r = rFrom + ((rTo - rFrom) * factor)
    local g = gFrom + ((gTo - gFrom) * factor)
    local b = bFrom + ((bTo - bFrom) * factor)
    local a = aFrom + ((aTo - aFrom) * factor)
    if (r > 1) then
        r = 1
    elseif (r < 0) then
        r = 0
    end
    if (g > 1) then
        g = 1
    elseif (g < 0) then
        g = 0
    end
    if (b > 1) then
        b = 1
    elseif (b < 0) then
        b = 0
    end
    if (a > 1) then
        a = 1
    elseif (a < 0) then
        a = 0
    end
	return X4D_Colors:Create(r, g, b)
end

function X4D_Colors:DeriveHighlight(color)
    if (color == nil) then
        d("color is nil")
    end
	return X4D_Colors:Lerp(color, "|cFFFFFF", 50)
end

local _itemQualityColors = {
    [0] = X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 0)):UnpackRGBA()),
    [1] = X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 1)):UnpackRGBA()),
    [2] = X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 2)):UnpackRGBA()),
    [3] = X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 3)):UnpackRGBA()),
    [4] = X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 4)):UnpackRGBA()),
    [5] = X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 5)):UnpackRGBA()),
}

X4D_Colors.Gold = X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_GOLD)):UnpackRGBA())
X4D_Colors.AlliancePoints = X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_ALLIANCE_POINTS)):UnpackRGBA())
X4D_Colors.Items = X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_ITEM)):UnpackRGBA())
X4D_Colors.BattleTokens = X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_BATTLE_TOKENS)):UnpackRGBA())
X4D_Colors.RankPoints = X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_RANK_POINTS)):UnpackRGBA())
X4D_Colors.Inspiration = X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_INSPIRATION)):UnpackRGBA())
X4D_Colors.Crowns = X4D_Colors.Gold


function X4D_Colors:ExtractLinkColor(itemLink, defaultColor)
    local itemQuality = GetItemLinkQuality(itemLink)
	local itemColor = _itemQualityColors[itemQuality]
	return itemColor, itemQuality
end

--[[

['ABILITY_TOOLTIP_TEXT_COLOR_ABILITY_INFO'] = 10
['ABILITY_TOOLTIP_TEXT_COLOR_BODY'] = 2
['ABILITY_TOOLTIP_TEXT_COLOR_BRONZE_ABILITY'] = 6
['ABILITY_TOOLTIP_TEXT_COLOR_DEFAULT'] = 0
['ABILITY_TOOLTIP_TEXT_COLOR_FAILED_REQUIREMENT'] = 4
['ABILITY_TOOLTIP_TEXT_COLOR_GOLD_ABILITY'] = 8
['ABILITY_TOOLTIP_TEXT_COLOR_NAME'] = 1
['ABILITY_TOOLTIP_TEXT_COLOR_NEW_EFFECT'] = 14
['ABILITY_TOOLTIP_TEXT_COLOR_SILVER_ABILITY'] = 7
['ABILITY_TOOLTIP_TEXT_COLOR_SPECIAL_HEADER'] = 5
['ABILITY_TOOLTIP_TEXT_COLOR_UPGRADE_TO_ABILITY'] = 9
['ABILITY_TOOLTIP_TEXT_COLOR_UPGRADES'] = 15
['ABILITY_TOOLTIP_TEXT_COLOR_USE_INFO_TYPE1'] = 11
['ABILITY_TOOLTIP_TEXT_COLOR_USE_INFO_TYPE2'] = 12
['ABILITY_TOOLTIP_TEXT_COLOR_USE_INFO_TYPE3'] = 13
['ABILITY_TOOLTIP_TEXT_COLOR_VALID_REQUIREMENT'] = 3


['ACTIVE_COMBAT_TIP_COLOR_FAILURE'] = 1
['ACTIVE_COMBAT_TIP_COLOR_NORMAL'] = 2
['ACTIVE_COMBAT_TIP_COLOR_SUCCESS'] = 0

['BUFF_TYPE_COLOR_BUFF'] = 0
['BUFF_TYPE_COLOR_DEBUFF'] = 1

['CURRENCY_COLOR_ALLIANCE_POINTS'] = 1
['CURRENCY_COLOR_BATTLE_TOKENS'] = 2
['CURRENCY_COLOR_GOLD'] = 0
['CURRENCY_COLOR_INSPIRATION'] = 3
['CURRENCY_COLOR_RANK_POINTS'] = 4

['EMPTY_SOCKET_COLOR'] = table: 30BB0BD8

['FULL_SOCKET_COLOR'] = table: 3D18DE90

['GetAllianceColor'] = function: 3CB53C98

['GetBuffColor'] = function: 3CB5DB90

['GetChatCategoryColor'] = function: 16188868

['GetChatContainerColors'] = function: 16188518

['GetClassColor'] = function: 3CB5AB10

['GetColorForCon'] = function: 3CB54768

['GetConColor'] = function: 3CB54740

['GetItemQualityColor'] = function: 3CB5DC08

['GetPoisonEffectColorIndex'] = function: 16186388

['GetStatColor'] = function: 3CB5DBB8

['GetStatusEffectColor'] = function: 3CB5E778

['GetUnitReactionColor'] = function: 161857D0

['INTERFACE_COLOR_TYPE_ABILITY_TOOLTIP'] = 3
['INTERFACE_COLOR_TYPE_ACTIVE_COMBAT_TIP'] = 36
['INTERFACE_COLOR_TYPE_ALLIANCE'] = 25
['INTERFACE_COLOR_TYPE_ATTRIBUTE_TOOLTIP'] = 23
['INTERFACE_COLOR_TYPE_ATTRIBUTE_UPGRADE_PROJECTED'] = 34
['INTERFACE_COLOR_TYPE_BOOK_MEDIUM'] = 28
['INTERFACE_COLOR_TYPE_BUFF_TYPE'] = 19
['INTERFACE_COLOR_TYPE_CAST_BAR_END'] = 8
['INTERFACE_COLOR_TYPE_CAST_BAR_START'] = 7
['INTERFACE_COLOR_TYPE_CHAT_CHANNEL_CATEGORY_DEFAULTS'] = 24
['INTERFACE_COLOR_TYPE_CON_COLORS'] = 12
['INTERFACE_COLOR_TYPE_CURRENCY'] = 21
['INTERFACE_COLOR_TYPE_DEFAULT_COLOR'] = 0
['INTERFACE_COLOR_TYPE_FINESSE'] = 38
['INTERFACE_COLOR_TYPE_GENERAL'] = 9
['INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS'] = 1
['INTERFACE_COLOR_TYPE_ITEM_TOOLTIP'] = 2
['INTERFACE_COLOR_TYPE_KEEP_TOOLTIP'] = 26
['INTERFACE_COLOR_TYPE_LEADERBOARD_COLORS'] = 44
['INTERFACE_COLOR_TYPE_LEVEL_UP'] = 37
['INTERFACE_COLOR_TYPE_LINK'] = 22
['INTERFACE_COLOR_TYPE_LOADING_SCREEN'] = 29
['INTERFACE_COLOR_TYPE_MAPPIN_TOOLTIP'] = 4
['INTERFACE_COLOR_TYPE_NAME_PLATE'] = 6
['INTERFACE_COLOR_TYPE_NAME_PLATE_HEALTH_END'] = 42
['INTERFACE_COLOR_TYPE_NAME_PLATE_HEALTH_START'] = 41
['INTERFACE_COLOR_TYPE_NAME_PLATE_HIT_INDICATOR'] = 43
['INTERFACE_COLOR_TYPE_OBJECT_NOTIFICATION'] = 16
['INTERFACE_COLOR_TYPE_POWER_END'] = 31
['INTERFACE_COLOR_TYPE_POWER_FADE_IN'] = 32
['INTERFACE_COLOR_TYPE_POWER_FADE_OUT'] = 33
['INTERFACE_COLOR_TYPE_POWER_START'] = 30
['INTERFACE_COLOR_TYPE_PROGRESSION'] = 39
['INTERFACE_COLOR_TYPE_SCROLLING_COMBAT_TEXT'] = 10
['INTERFACE_COLOR_TYPE_SHARED_TOOLTIP'] = 18
['INTERFACE_COLOR_TYPE_SKILL_LINE_TOOLTIP'] = 17
['INTERFACE_COLOR_TYPE_STAT_VALUE'] = 20
['INTERFACE_COLOR_TYPE_STATUS_EFFECT'] = 27
['INTERFACE_COLOR_TYPE_TEXT_COLORS'] = 13
['INTERFACE_COLOR_TYPE_ULTIMATE_BAR'] = 35
['INTERFACE_COLOR_TYPE_UNIT_CLASS'] = 11
['INTERFACE_COLOR_TYPE_UNIT_REACTION'] = 5
['INTERFACE_COLOR_TYPE_UNUSED_VALUE'] = 15
['INTERFACE_COLOR_TYPE_UNUSED_VALUE2'] = 40
['INTERFACE_GENERAL_COLOR_ALERT'] = 3
['INTERFACE_GENERAL_COLOR_DISABLED'] = 1
['INTERFACE_GENERAL_COLOR_ENABLED'] = 0
['INTERFACE_GENERAL_COLOR_ERROR'] = 2
['INTERFACE_GENERAL_COLOR_STATUS_BAR_END'] = 6
['INTERFACE_GENERAL_COLOR_STATUS_BAR_START'] = 5
['INTERFACE_GENERAL_COLOR_WARNING'] = 4
['INTERFACE_TEXT_COLOR_BLADE'] = 5
['INTERFACE_TEXT_COLOR_BLADE_HIGHLIGHT'] = 6
['INTERFACE_TEXT_COLOR_BODY'] = 4
['INTERFACE_TEXT_COLOR_CHATTER_NPC'] = 13
['INTERFACE_TEXT_COLOR_CHATTER_PLAYER_OPTION'] = 14
['INTERFACE_TEXT_COLOR_CONTEXT_HIGHLIGHT'] = 9
['INTERFACE_TEXT_COLOR_CONTRAST'] = 15
['INTERFACE_TEXT_COLOR_DEFAULT_TEXT'] = 19
['INTERFACE_TEXT_COLOR_DISABLED'] = 2
['INTERFACE_TEXT_COLOR_FAILED'] = 11
['INTERFACE_TEXT_COLOR_GAME_REPRESENTATIVE'] = 20
['INTERFACE_TEXT_COLOR_HIGHLIGHT'] = 0
['INTERFACE_TEXT_COLOR_HINT'] = 12
['INTERFACE_TEXT_COLOR_NORMAL'] = 1
['INTERFACE_TEXT_COLOR_SECOND_CONTRAST'] = 16
['INTERFACE_TEXT_COLOR_SELECTED'] = 3
['INTERFACE_TEXT_COLOR_SUBTLE'] = 17
['INTERFACE_TEXT_COLOR_SUCCEEDED'] = 10
['INTERFACE_TEXT_COLOR_TOOLTIP_DEFAULT'] = 7
['INTERFACE_TEXT_COLOR_TOOLTIP_INSTRUCTIONAL'] = 8
['INTERFACE_TEXT_COLOR_VALUE'] = 18

['ITEM_TOOLTIP_COLOR_ACCENT'] = 3
['ITEM_TOOLTIP_COLOR_CHARGE_BAR_GRADIENT_END'] = 22
['ITEM_TOOLTIP_COLOR_CHARGE_BAR_GRADIENT_START'] = 21
['ITEM_TOOLTIP_COLOR_CLICK_TO_UPGRADE'] = 6
['ITEM_TOOLTIP_COLOR_CONDITION_BAR_GRADIENT_END'] = 24
['ITEM_TOOLTIP_COLOR_CONDITION_BAR_GRADIENT_START'] = 23
['ITEM_TOOLTIP_COLOR_CREATOR'] = 12
['ITEM_TOOLTIP_COLOR_DECONSTRUCTABLE'] = 14
['ITEM_TOOLTIP_COLOR_EQUIPPED'] = 17
['ITEM_TOOLTIP_COLOR_FAIL_CHECK'] = 1
['ITEM_TOOLTIP_COLOR_FLAVOR_TEXT'] = 11
['ITEM_TOOLTIP_COLOR_GENERAL'] = 2
['ITEM_TOOLTIP_COLOR_INACTIVE_BONUS'] = 20
['ITEM_TOOLTIP_COLOR_ITEM_LEVEL'] = 18
['ITEM_TOOLTIP_COLOR_MISC'] = 16
['ITEM_TOOLTIP_COLOR_ON_EQUIP'] = 4
['ITEM_TOOLTIP_COLOR_ON_USE'] = 5
['ITEM_TOOLTIP_COLOR_PASS_CHECK'] = 0
['ITEM_TOOLTIP_COLOR_QUEST_ITEM_NAME'] = 15
['ITEM_TOOLTIP_COLOR_SELLS_FOR'] = 10
['ITEM_TOOLTIP_COLOR_SHOWING_EQUIPPED_ITEM'] = 13
['ITEM_TOOLTIP_COLOR_SOCKET_EMPTY'] = 8
['ITEM_TOOLTIP_COLOR_SOCKET_FULL'] = 9
['ITEM_TOOLTIP_COLOR_SOCKET_PASS_CHECK'] = 7
['ITEM_TOOLTIP_COLOR_STYLE'] = 19

['KEEP_TOOLTIP_COLOR_ACCESSIBLE'] = 3
['KEEP_TOOLTIP_COLOR_AT_KEEP'] = 5
['KEEP_TOOLTIP_COLOR_ATTACK_LINE'] = 1
['KEEP_TOOLTIP_COLOR_NAME'] = 0
['KEEP_TOOLTIP_COLOR_NORMAL_LINE'] = 2
['KEEP_TOOLTIP_COLOR_NOT_ACCESSIBLE'] = 4

['LEADERBOARD_COLORS_TOP_100_BANNER_TEXT'] = 2
['LEADERBOARD_COLORS_TOP_20_BANNER_TEXT'] = 0
['LEADERBOARD_COLORS_TOP_50_BANNER_TEXT'] = 1

['LEVEL_UP_COLOR_GAINED_TEXT'] = 2
['LEVEL_UP_COLOR_GENERAL'] = 0
['LEVEL_UP_COLOR_NEW_LEVEL'] = 1

['LOADING_SCREEN_COLOR_BAR_END'] = 1
['LOADING_SCREEN_COLOR_BAR_START'] = 0

['MAP_PIN_TOOLTIP_COLOR_AVA_OBJECTIVE'] = 4
['MAP_PIN_TOOLTIP_COLOR_INTERACTABLE'] = 3
['MAP_PIN_TOOLTIP_COLOR_MAP_PING'] = 5
['MAP_PIN_TOOLTIP_COLOR_POI'] = 2
['MAP_PIN_TOOLTIP_COLOR_QUEST_ENDING'] = 0
['MAP_PIN_TOOLTIP_COLOR_RALLY_POINT'] = 6
['MAP_PIN_TOOLTIP_COLOR_YOUR_CORPSE'] = 1

['POISON_COLOR_INDEX_GREEN'] = 1
['POISON_COLOR_INDEX_NONE'] = 0
['POISON_COLOR_INDEX_ORANGE'] = 2
['POISON_COLOR_INDEX_PURPLE'] = 3

['PROGRESSION_COLOR_AVA_RANK_END'] = 14
['PROGRESSION_COLOR_AVA_RANK_START'] = 13
['PROGRESSION_COLOR_EARNED'] = 0
['PROGRESSION_COLOR_LOCKED'] = 12
['PROGRESSION_COLOR_PURCHASED'] = 10
['PROGRESSION_COLOR_SKILL_XP_END'] = 9
['PROGRESSION_COLOR_SKILL_XP_START'] = 8
['PROGRESSION_COLOR_UNEARNED'] = 1
['PROGRESSION_COLOR_UNPURCHASED'] = 11
['PROGRESSION_COLOR_VP_END'] = 16
['PROGRESSION_COLOR_VP_START'] = 15
['PROGRESSION_COLOR_XP_END'] = 3
['PROGRESSION_COLOR_XP_FULL_END'] = 5
['PROGRESSION_COLOR_XP_FULL_START'] = 4
['PROGRESSION_COLOR_XP_MORPH_END'] = 7
['PROGRESSION_COLOR_XP_MORPH_START'] = 6
['PROGRESSION_COLOR_XP_START'] = 2

['SCROLLING_COMBAT_TEXT_COLOR_AP_GAIN'] = 5
['SCROLLING_COMBAT_TEXT_COLOR_DAMAGE_DONE_TO_ANYONE_BUT_THE_LOCAL_PLAYER'] = 2
['SCROLLING_COMBAT_TEXT_COLOR_DAMAGE_DONE_TO_LOCAL_PLAYER'] = 1
['SCROLLING_COMBAT_TEXT_COLOR_DEFAULT'] = 0
['SCROLLING_COMBAT_TEXT_COLOR_HEAL'] = 3
['SCROLLING_COMBAT_TEXT_COLOR_STATUS_EFFECTS'] = 6
['SCROLLING_COMBAT_TEXT_COLOR_XP_GAIN'] = 4

['SI_CHAT_OPTIONS_BACKGROUND_COLOR'] = 1642
['SI_CHAT_OPTIONS_COLOR_TOOLTIP'] = 1644

['STAT_DIMINISHING_RETURNS_COLOR'] = table: 3D1691D8

['STAT_HIGHER_COLOR'] = table: 3D168DB0
['STAT_LOWER_COLOR'] = table: 3D165C28

['STAT_VALUE_COLOR_DIMINISHING_RETURNS'] = 2
['STAT_VALUE_COLOR_HIGHER'] = 1
['STAT_VALUE_COLOR_LOWER'] = 0

['ULTIMATE_BAR_COLOR_BAR_END'] = 1
['ULTIMATE_BAR_COLOR_BAR_START'] = 0
['ULTIMATE_BAR_COLOR_FULL_BAR_END'] = 3
['ULTIMATE_BAR_COLOR_FULL_BAR_START'] = 2

['ZO_AVA_RANK_GRADIENT_COLORS'] = table: 3CB53C48

['ZO_BUFF_COLOR'] = table: 3CB5C7D0

['ZO_CAST_BAR_COLORS'] = table: 3CB4B9E8

['ZO_CHARGE_GRADIENT_COLORS'] = table: 3CB5DC58

['ZO_CONDITION_GRADIENT_COLORS'] = table: 3CB5E690

['ZO_DEBUFF_COLOR'] = table: 3CB5C930

['ZO_DEFAULT_DISABLED_COLOR'] = table: 3CB610B8
['ZO_DEFAULT_DISABLED_MOUSEOVER_COLOR'] = table: 3CB61CB8
['ZO_DEFAULT_ENABLED_COLOR'] = table: 3CB61CE0

['ZO_ERROR_COLOR'] = table: 3D167600

['ZO_POWER_BAR_GRADIENT_COLORS'] = table: 4865ED08

['ZO_ProvisionerRow_GetTextColor'] = function: 4E5754E8

['ZO_QuestJournalNavigationEntry_GetTextColor'] = function: 3CCB5910

['ZO_SKILL_XP_BAR_GRADIENT_COLORS'] = table: 3CB53120

['ZO_SocketSocket1Color'] = userdata: 2E0814C0

['ZO_SocketSocket2Color'] = userdata: 2E081690

['ZO_SocketSocket3Color'] = userdata: 2E081860

['ZO_SocketSocket4Color'] = userdata: 2E081A30

['ZO_TOOLTIP_DEFAULT_COLOR'] = table: 3D169298
['ZO_TOOLTIP_INSTRUCTIONAL_COLOR'] = table: 3D1675D8

['ZO_VP_BAR_GRADIENT_COLORS'] = table: 3CB51DA8

['ZO_XP_BAR_GRADIENT_COLORS'] = table: 3CB50CC8

]]