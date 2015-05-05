local X4D_Currency = LibStub:NewLibrary("X4D_Currency", 1000)
if (not X4D_Currency) then
	return
end
local X4D = LibStub("X4D")
X4D.Currency = X4D_Currency

X4D_Currency.CurrencyTypes = {
    [CURRENCY_TYPE_MONEY] = { --1
        Name = GetString(SI_CURRENCY_GOLD),
        Color = X4D.Colors.Gold,
        Canonical = "CURRENCY_TYPE_MONEY",
        Icon58 = X4D.Icons:ToIcon58("EsoUI/Art/currency/currency_gold.dds"),
    },
    [CURRENCY_TYPE_ALLIANCE_POINTS] = { --2
        Name = GetString(SI_CURRENCY_ALLIANCE_POINTS),
        Color = X4D.Colors.AlliancePoints,
        Canonical = "CURRENCY_TYPE_ALLIANCE_POINTS",
        Icon58 = X4D.Icons:ToIcon58("EsoUI/Art/currency/alliancePoints.dds"),
    },
    [CURRENCY_TYPE_BATTLE_TOKENS] = { --3
        Name = GetString(SI_CURRENCY_BATTLE_TOKENS),
        Color = X4D.Colors.BattleTokens,
        Canonical = "CURRENCY_TYPE_BATTLE_TOKENS",
        Icon58 = X4D.Icons:ToIcon58("EsoUI/Art/currency/battleToken.dds"),
    },
    [CURRENCY_TYPE_ITEM] = { --4
        Name = GetString(SI_CURRENCY_ITEM),
        Color = X4D.Colors.Items,
        Canonical = "CURRENCY_TYPE_ITEM",
        Icon58 = X4D.Icons:ToIcon58("EsoUI/Art/Icons/icon_missing.dds"),
    },
    [CURRENCY_TYPE_RANK_POINTS] = { --5
        Name = GetString(SI_CURRENCY_RANK_POINTS),
        Color = X4D.Colors.RankPoints,
        Canonical = "CURRENCY_TYPE_RANK_POINTS",
        Icon58 = X4D.Icons:ToIcon58("EsoUI/Art/Icons/icon_missing.dds"),
    },
    [CURRENCY_TYPE_INSPIRATION] = { --6
        Name = GetString(SI_CURRENCY_INSPIRATION),
        Color = X4D.Colors.RankPoints,
        Canonical = "CURRENCY_TYPE_INSPIRATION",
        Icon58 = X4D.Icons:ToIcon58("EsoUI/Art/currency/currency_inspiration.dds"),
    },
    [CURRENCY_TYPE_CROWNS] = { --7
        Name = GetString(SI_CURRENCY_CROWN),
        Color = X4D.Colors.Crowns,
        Canonical = "CURRENCY_TYPE_CROWNS",
        Icon58 = X4D.Icons:ToIcon58("EsoUI/Art/currency/currency_crown.dds"),
    },
}

