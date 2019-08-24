local X4D_Currency = LibStub:NewLibrary("X4D_Currency", 1015)
if (not X4D_Currency) then
	return
end
local X4D = LibStub("X4D")
X4D.Currency = X4D_Currency

--region Money Reasons

-- TODO: relocate

X4D_Currency.MoneyUpdateReason = {
	[0] = { "Looted", "Stored" },
	[1] = { "Earned", "Spent" },
	[2] = { "Received", "Sent" },
	[4] = { "Gained", "Spent" },
	[5] = { "Earned", "Spent" },
	[19] = { "Gained", "Spent" },
	[28] = { "Gained", "Spent" },
	[29] = { "Gained", "Spent" },
	[42] = { "Withdrew", "Deposited" },
	[43] = { "Withdrew", "Deposited" },
    [63] = { "Fenced", "Laundered" },
}	
function X4D_Currency:GetMoneyReason(reasonId)
	return X4D_Currency.MoneyUpdateReason[reasonId] or { "Gained", "Removed" }
end

--endregion

X4D_Currency.CurrencyTypes = {
    [CURT_MONEY] = { --1
        Name = GetString(SI_CURRENCY_GOLD),
        Color = X4D.Colors.Gold,
        Canonical = "CURT_MONEY",
        Icon = "EsoUI/Art/currency/currency_gold.dds",
        GetCurrentAmount = function(self)
            return GetCurrentMoney()
        end,
    },
    [CURT_ALLIANCE_POINTS] = { --2
        Name = GetString(SI_CURRENCY_ALLIANCE_POINTS),
        Color = X4D.Colors.AlliancePoints,
        Canonical = "CURT_ALLIANCE_POINTS",
        Icon = "EsoUI/Art/currency/alliancePoints.dds",
        GetCurrentAmount = function(self)
            return GetAlliancePoints()
        end,
    },
    [CURT_TELVAR_STONES] = { --3
        Name = GetString(SI_CURRENCY_TELVAR_STONES),
        Color = X4D.Colors.TelvarStones,
        Canonical = "CURT_TELVAR_STONES",
        Icon = "EsoUI/Art/Icons/Icon_TelVarStone.dds",
        GetCurrentAmount = function(self)
            return 0 -- TODO: unsure where to pull from
        end,
    },
    -- removed in 2.1.4 ?
--    [CURRENCY_TYPE_ITEM] = { --4
--        Name = GetString(SI_CURRENCY_ITEM),
--        Color = X4D.Colors.Items,
--        Canonical = "CURRENCY_TYPE_ITEM",
--        Icon = "EsoUI/Art/Icons/icon_missing.dds",
--        GetCurrentAmount = function(self)
--            return 0 -- TODO: unsure where to pull from
--        end,
--    },
--    [CURRENCY_TYPE_RANK_POINTS] = { --5
--        Name = GetString(SI_CURRENCY_RANK_POINTS),
--        Color = X4D.Colors.RankPoints,
--        Canonical = "CURRENCY_TYPE_RANK_POINTS",
--        Icon = "EsoUI/Art/Icons/icon_missing.dds",
--        GetCurrentAmount = function(self)
--            return GetUnitAvARankPoints("player")
--        end,
--    },
--    [CURRENCY_TYPE_INSPIRATION] = { --6
--        Name = GetString(SI_CURRENCY_INSPIRATION),
--        Color = X4D.Colors.RankPoints,
--        Canonical = "CURRENCY_TYPE_INSPIRATION",
--        Icon = "EsoUI/Art/currency/currency_inspiration.dds",
--        GetCurrentAmount = function(self)
--            return GetLastCraftingResultTotalInspiration()
--        end,
--    },
--    [CURRENCY_TYPE_CROWNS] = { --7
--        Name = GetString(SI_CURRENCY_CROWN),
--        Color = X4D.Colors.Crowns,
--        Canonical = "CURRENCY_TYPE_CROWNS",
--        Icon = "EsoUI/Art/currency/currency_crown.dds",
--        GetCurrentAmount = function(self)
--            return GetMarketCurrency()
--        end,
--    },
}

X4D_Currency.Gold = X4D_Currency.CurrencyTypes[CURT_MONEY]
X4D_Currency.AlliancePoints = X4D_Currency.CurrencyTypes[CURT_ALLIANCE_POINTS]
X4D_Currency.BattleTokens = X4D_Currency.CurrencyTypes[CURT_TELVAR_STONES]
--X4D_Currency.Items = X4D_Currency.CurrencyTypes[CURRENCY_TYPE_ITEM]
--X4D_Currency.RankPoints = X4D_Currency.CurrencyTypes[CURRENCY_TYPE_RANK_POINTS]
--X4D_Currency.Inspiration = X4D_Currency.CurrencyTypes[CURRENCY_TYPE_INSPIRATION]
--X4D_Currency.Crowns = X4D_Currency.CurrencyTypes[CURRENCY_TYPE_CROWN]


