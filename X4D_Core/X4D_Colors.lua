local X4D_Colors = LibStub:NewLibrary("X4D_Colors", 1015)
if (not X4D_Colors) then
	return
end
local X4D = LibStub("X4D")
X4D.Colors = X4D_Colors

X4D_Colors.X4D = "|cFFAE19"

X4D_Colors.Deposit = "|cFFAE19"
X4D_Colors.Withdraw = "|cAA33FF"

X4D_Colors.SYSTEM = "|cFFFF00"
X4D_Colors.TRACE_DEBUG = "|cCCFF70"
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
X4D_Colors.LightGray = "|cC5C5C5"
X4D_Colors.Gray = "|c757575"
X4D_Colors.DarkGray = "|c353535"
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

X4D_Colors.Gold = "|cEED700" --X4D_Colors:Create(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY, CURRENCY_COLOR_GOLD)):UnpackRGBA())
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
