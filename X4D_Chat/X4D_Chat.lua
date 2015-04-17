local X4D_Chat = LibStub:NewLibrary("X4D_Chat", 1024)
if (not X4D_Chat) then
	return
end
local X4D = LibStub("X4D")
X4D.Chat = X4D_Chat

local X4D_LibAntiSpam = nil
local X4D_Loot = nil
local X4D_XP = nil
local X4D_Bank = nil
local X4D_Mail = nil

X4D_Chat.NAME = "X4D_Chat"
X4D_Chat.VERSION = "1.24"

X4D_Chat.Settings = {}
X4D_Chat.Settings.SavedVars = {}
X4D_Chat.Settings.Defaults = {
	GuildCharNames = true,
	GuildPlayerNames = false,
	UseGuildAbbr = true,
	GuildAbbr = {
		[1] = "",
		[2] = "",
		[3] = "",
		[4] = "",
		[5] = "",
	},
	UseGuildNum = false,
	TimestampOption = "24 Hour Format",
	RemoveSeconds = false,
	StripColors = false,
	StripExcess = true,
	PreventChatFade = true,
	DisableFriendStatus = false,
    UseLighterMessageColor = true,
}

X4D_Chat.ChannelCategory = {
	[CHAT_CHANNEL_EMOTE] = CHAT_CATEGORY_EMOTE,
	[CHAT_CHANNEL_GUILD_1] = CHAT_CATEGORY_GUILD_1,
	[CHAT_CHANNEL_GUILD_2] = CHAT_CATEGORY_GUILD_2,
	[CHAT_CHANNEL_GUILD_3] = CHAT_CATEGORY_GUILD_3,
	[CHAT_CHANNEL_GUILD_4] = CHAT_CATEGORY_GUILD_4,
	[CHAT_CHANNEL_GUILD_5] = CHAT_CATEGORY_GUILD_5,
	[CHAT_CHANNEL_MONSTER_EMOTE] = CHAT_CATEGORY_MONSTER_EMOTE,
	[CHAT_CHANNEL_MONSTER_SAY] = CHAT_CATEGORY_MONSTER_SAY,
	[CHAT_CHANNEL_MONSTER_WHISPER] = CHAT_CATEGORY_MONSTER_WHISPER,
	[CHAT_CHANNEL_MONSTER_YELL] = CHAT_CATEGORY_MONSTER_YELL,
	[CHAT_CHANNEL_OFFICER_1] = CHAT_CATEGORY_OFFICER_1,
	[CHAT_CHANNEL_OFFICER_2] = CHAT_CATEGORY_OFFICER_2,
	[CHAT_CHANNEL_OFFICER_3] = CHAT_CATEGORY_OFFICER_3,
	[CHAT_CHANNEL_OFFICER_4] = CHAT_CATEGORY_OFFICER_4,
	[CHAT_CHANNEL_OFFICER_5] = CHAT_CATEGORY_OFFICER_5,
	[CHAT_CHANNEL_PARTY] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_SAY] = CHAT_CATEGORY_SAY,
	[CHAT_CHANNEL_SYSTEM] = CHAT_CATEGORY_SYSTEM,
	[CHAT_CHANNEL_USER_CHANNEL_1] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_2] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_3] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_4] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_5] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_6] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_7] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_8] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_USER_CHANNEL_9] = CHAT_CATEGORY_PARTY,
	[CHAT_CHANNEL_WHISPER] = CHAT_CATEGORY_WHISPER_INCOMING,
	--[CHAT_CHANNEL_WHISPER_NOT_FOUND] = CHAT_CATEGORY_OUTGOING,
	[CHAT_CHANNEL_WHISPER_SENT] = CHAT_CATEGORY_WHISPER_OUTGOING,
	[CHAT_CHANNEL_YELL] = CHAT_CATEGORY_YELL,
	[CHAT_CHANNEL_ZONE] = CHAT_CATEGORY_ZONE,
	[CHAT_CHANNEL_ZONE_LANGUAGE_1] = CHAT_CATEGORY_ZONE_ENGLISH,
	[CHAT_CHANNEL_ZONE_LANGUAGE_2] = CHAT_CATEGORY_ZONE_FRENCH,
	[CHAT_CHANNEL_ZONE_LANGUAGE_3] = CHAT_CATEGORY_ZONE_GERMAN,
}

X4D_Chat.Guilds = {
	[CHAT_CATEGORY_GUILD_1] = nil,
	[CHAT_CATEGORY_GUILD_2] = nil,
	[CHAT_CATEGORY_GUILD_3] = nil,
	[CHAT_CATEGORY_GUILD_4] = nil,
	[CHAT_CATEGORY_GUILD_5] = nil,
	[CHAT_CATEGORY_OFFICER_1] = nil,
	[CHAT_CATEGORY_OFFICER_2] = nil,
	[CHAT_CATEGORY_OFFICER_3] = nil,
	[CHAT_CATEGORY_OFFICER_4] = nil,
	[CHAT_CATEGORY_OFFICER_5] = nil,
}

X4D_Chat.Colors = {
	SYSTEM = "|cFFFF00",
}

local function GetTimestampPrefix(color)
	if (X4D_Chat.Settings.SavedVars.TimestampOption == nil) then
		X4D_Chat.Settings.SavedVars.TimestampOption = X4D_Chat.Settings.Defaults.TimestampOption
	elseif (X4D_Chat.Settings.SavedVars.TimestampOption == "Disabled") then
		return color
	end

	local timeString = GetTimeString()

	if (X4D_Chat.Settings.SavedVars.TimestampOption == "12 Hour Format") then
		local hour = timeString:gmatch("(%d%d).%d%d.%d%d")()
		if (tonumber(hour) > 12) then
			hour = tostring(tonumber(hour) - 12)
			if (hour:len() == 1) then
				hour = "0" .. hour
			end
			if (X4D_Chat.Settings.SavedVars.RemoveSeconds) then
				timeString = timeString:gsub("%d%d.(%d%d).%d%d", hour .. ":%1 PM")
			else
				timeString = timeString:gsub("%d%d.(%d%d).(%d%d)", hour .. ":%1:%2 PM")
			end
		else
			if (hour == '00') then
				hour = '12'
			end
			if (X4D_Chat.Settings.SavedVars.RemoveSeconds) then
				timeString = timeString:gsub("%d%d.(%d%d).%d%d", hour .. ":%1 AM")
			else
				timeString = timeString:gsub("%d%d.(%d%d).(%d%d)", hour .. ":%1:%2 AM")
			end
		end
	elseif (X4D_Chat.Settings.SavedVars.RemoveSeconds) then
		timeString = timeString:gsub("(%d%d).(%d%d).%d%d", "%1:%2")
	end

	local highlightColor = X4D.Colors:DeriveHighlight(color)
	return color .. "[" .. highlightColor .. timeString .. color .. "] "
end

function X4D_Chat.OnChatMessageReceived(messageType, fromName, text)
	if (X4D_LibAntiSpam) then
		local isSpam, isFlood = false, false
		if (X4D_LibAntiSpam.Check) then
			isSpam, isFlood = X4D_LibAntiSpam:Check(text, fromName)
		elseif (X4D_LibAntiSpam.IsSpam) then
			isSpam, isFlood = X4D_LibAntiSpam:IsSpam(text, fromName)
		end
		if (isSpam or isFlood) then
			return
		end
	end

    local ChannelInfo = ZO_ChatSystem_GetChannelInfo()
    local channelInfo = ChannelInfo[messageType]
	local result = nil
	text = X4D_Chat.StripColors(text)
    if (channelInfo and channelInfo.format) then
		local category = X4D_Chat.GetChatCategory(channelInfo)
		local r, g, b = GetChatCategoryColor(category)
		local categoryColor = X4D_Chat.CreateColorCode(r, g, b)
        local channelLink = X4D_Chat.CreateChannelLink(channelInfo, category)
        local fromLink = X4D_Chat.CreateCharacterLink(fromName, channelInfo)
        local textColor = categoryColor
        if (X4D_Chat.Settings.SavedVars.UseLighterMessageColor) then
            textColor = X4D.Colors:Lerp(textColor, "|cFFFFFF", 33)
        end
        if (channelLink) then
            result = zo_strformat(channelInfo.format, channelLink, fromLink, textColor .. text)
        else
			result = zo_strformat(channelInfo.format, fromLink, textColor .. text)
			if (X4D_Chat.Settings.SavedVars.StripExcess) then
				result = result:gsub("%]%|h%s?.-%:", "]|h:", 1)
			end
		end
		return GetTimestampPrefix(categoryColor) .. result, channelInfo.saveTarget
    end
end

function X4D_Chat.GetChatCategory(channelInfo)
	local category = X4D_Chat.ChannelCategory[channelInfo.id]
	if (category ~= nil) then
		return category
	end
	return CHAT_CATEGORY_ZONE
end

function X4D_Chat.CreateColorCode(r, g, b)
	return "|c" .. X4D.Convert.DEC2HEX(r * 255) .. X4D.Convert.DEC2HEX(g * 255) .. X4D.Convert.DEC2HEX(b * 255)
end

function X4D_Chat.ParseColorCode(color)
	return X4D.Convert.HEX2DEC(color, 3)/256, X4D.Convert.HEX2DEC(color, 5)/256, X4D.Convert.HEX2DEC(color, 7)/256, 1
end

function X4D_Chat.CreateChannelLink(channelInfo, category)
	if (category == CHAT_CATEGORY_OFFICER_1) then 
		category = CHAT_CATEGORY_GUILD_1
	elseif (category == CHAT_CATEGORY_OFFICER_2) then 
		category = CHAT_CATEGORY_GUILD_2
	elseif (category == CHAT_CATEGORY_OFFICER_3) then 
		category = CHAT_CATEGORY_GUILD_3
	elseif (category == CHAT_CATEGORY_OFFICER_4) then 
		category = CHAT_CATEGORY_GUILD_4
	elseif (category == CHAT_CATEGORY_OFFICER_5) then 
		category = CHAT_CATEGORY_GUILD_5
	end
    if (channelInfo.channelLinkable) then
        local channelName = GetChannelName(channelInfo.id)
        local result = ZO_LinkHandler_CreateChannelLink(channelName)
		local guild = nil
		local guildNum = nil
		if (category) then
			if (not X4D_Chat.Guilds[category] or X4D_Chat.Guilds[category].Time <= (GetGameTimeMilliseconds() - 5000)) then
				local guildId = nil
				if (category == CHAT_CATEGORY_GUILD_1) then					
					guildId = GetGuildId(1)
					guildNum = 1
				elseif (category == CHAT_CATEGORY_GUILD_2) then
					guildId = GetGuildId(2)
					guildNum = 2
				elseif (category == CHAT_CATEGORY_GUILD_3) then
					guildId = GetGuildId(3)
					guildNum = 3
				elseif (category == CHAT_CATEGORY_GUILD_4) then
					guildId = GetGuildId(4)
					guildNum = 4
				elseif (category == CHAT_CATEGORY_GUILD_5) then
					guildId = GetGuildId(5)
					guildNum = 5
				end				
				X4D_Chat.Guilds[category] = {
					Id = guildId,
					Time = GetGameTimeMilliseconds(),
					Num = guildNum,
				}
			end
			guild = X4D_Chat.Guilds[category]
		end
		if (guild) then
			if (X4D_Chat.Settings.SavedVars.UseGuildAbbr) then
				if (not guild.Abbr) then
					if (X4D_Chat.Settings.SavedVars.GuildAbbr[guild.Num] and X4D_Chat.Settings.SavedVars.GuildAbbr[guild.Num]:len() > 0) then
						guild.Abbr = X4D_Chat.Settings.SavedVars.GuildAbbr[guild.Num]
					else
						if (not guild.Description) then
							guild.Description = GetGuildDescription(guild.Id)
						end
						if (guild.Description and guild.Description:len() > 0) then
							for word in guild.Description:gmatch("%[.-%]") do 
								guild.Abbr = word:gsub("([%[%]])", "")
								break
							end
						end
						if (not guild.Abbr or guild.Abbr:len() == 0) then
							local abbr = channelName:gsub("[^%a%d]", ""):sub(1, 1)
							for w in channelName:gmatch("[^%a%d](.)") do
								abbr = abbr .. w
							end
							guild.Abbr = abbr
						end
					end
				end
			end
			if (X4D_Chat.Settings.SavedVars.UseGuildNum) then
				if (not guild.Num) then
					guild.Num = guildNum
				end
			end
			channelName = channelName:gsub("([^%a%d%s])", "%%%1")
			if (X4D_Chat.Settings.SavedVars.UseGuildNum and guild.Abbr and guild.Abbr:len() > 0 and guild.Num) then
				result = result:gsub(channelName, guild.Num .. "/" .. guild.Abbr)
			elseif (guild.Abbr and guild.Abbr:len() > 0) then
				result = result:gsub(channelName, guild.Abbr)
			elseif (X4D_Chat.Settings.SavedVars.UseGuildNum and guild.Num) then
				result = result:gsub(channelName, guild.Num)
			end
		end
		return result
    end
end

X4D_Chat.Players = {}

local function GetPlayer(fromName)
	return X4D_Chat.Players[fromName]
end

local function AddPlayer(fromName)
	local player = {
		Time = GetGameTimeMilliseconds(),
		From = fromName,
	}
	X4D_Chat.Players[fromName] = player
	return player
end

local function TryUpdatePlayerCharacterName(player, fromName)
	if (string.StartsWith(fromName,"@")) then
		for guildIndex = 1,GetNumGuilds() do
			local guildId = GetGuildId(guildIndex)
			if (guildId ~= nil) then
				for memberIndex = 1,GetNumGuildMembers(guildId) do
					local name, note, rankIndex, playerStatus, secsSinceLogoff = GetGuildMemberInfo(guildId, memberIndex)
					if (name == fromName) then
						local hasCharacter, characterName, zoneName, classType, alliance, level, veteranRank = GetGuildMemberCharacterInfo(guildId, memberIndex)
						if (characterName ~= nil and characterName:len() > 0) then
							player.CharacterName = characterName:gsub("%^.*", "")
							break
						end
					end
				end
				if (player.CharacterName) then
					break
				end
			end			
		end
	end
end

function X4D_Chat.CreateCharacterLink(fromName, channelInfo)
	local result = fromName
	if (X4D_Chat.Settings.SavedVars.GuildCharNames) then
		local player = GetPlayer(fromName)
		if (not (player and player.CharacterName and player.Time >= (GetGameTimeMilliseconds() - 15000))) then
			player = AddPlayer(fromName)
			TryUpdatePlayerCharacterName(player, fromName)
		end
		if (not player.CharacterName) then
			player.CharacterName = fromName					
		end				
		if (player.CharacterName) then
			result = player.CharacterName
		end
	end
    if (channelInfo == nil or channelInfo.playerLinkable) then
		if (result and result ~= fromName) then
			local rep = fromName:gsub("([^%a%d%s])", "%%%1")
			local linkName = ZO_LinkHandler_CreatePlayerLink(fromName)
			if (linkName) then
				if (X4D_Chat.Settings.SavedVars.GuildPlayerNames) then
					result = linkName:gsub(rep, result .. fromName)
				else
					result = linkName:gsub(rep, result)
				end
			end
		else
			result = ZO_LinkHandler_CreatePlayerLink(fromName)
		end
    end
    return result
end

function X4D_Chat.StripColors(text)
	if (X4D_Chat.Settings.SavedVars.StripColors) then
		return text:gsub("%|c%x%x%x%x%x%x", "")
	end
	return text
end

local function StringSplit(s, delimiter)
    local result = {}
    for match in (s..delimiter):gmatch('(.-)'..delimiter) do
		local s = tostring(match)
		if (s:len() > 0) then
			table.insert(result, match)
		end
    end
    return result
end

function string.StartsWith(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

local _nextUpdateTime = 0

local function OnUpdate(...)
	local timeNow = GetGameTimeMilliseconds()
	if (_nextUpdateTime >= timeNow) then
		return
	end
	_nextUpdateTime = timeNow + 5000	
	X4D_Chat.Register()
	if (X4D_Chat.Settings.SavedVars.PreventChatFade) then
		if (ZO_ChatWindow.container and ZO_ChatWindow.container.currentBuffer) then
			ZO_ChatWindow.container.currentBuffer:ShowFadedLines()
		end
	end
end

local function SetComboboxValue(controlName, value)
	local combobox = _G[controlName]
	local dropmenu = ZO_ComboBox_ObjectFromContainer(GetControl(combobox, 'Dropdown'))
	local items = dropmenu:GetItems()
	for k,v in pairs(items) do
		if (v.name == value) then
			dropmenu:SetSelectedItem(v.name)
		end
	end
end

local function SetCheckboxValue(controlName, value)
	local checkbox = _G[controlName]:GetNamedChild("Checkbox")
	checkbox:SetState(value and 1 or 0)
	checkbox:toggleFunction(value)
end

local function SetSliderValue(controlName, value, minValue, maxValue)
	local range = maxValue - minValue
	local slider = _G[controlName]
	local slidercontrol = slider:GetNamedChild('Slider')
	local slidervalue = slider:GetNamedChild('ValueLabel')
	slidercontrol:SetValue((value - minValue)/range)
	slidervalue:SetText(tostring(value))
end

--local function SetEditBoxValue(controlName, value, maxInputChars)
--	if (maxInputChars and maxInputChars > 0) then
--		_G[controlName]["edit"]:SetMaxInputChars(maxInputChars)
--	end
--	_G[controlName]["edit"]:SetText(value)
--end

local function OnAddOnLoaded(event, addonName)
	if (addonName ~= X4D_Chat.NAME) then
		return
	end	
	X4D_Chat.Settings.SavedVars = ZO_SavedVars:NewAccountWide(X4D_Chat.NAME .. "_SV", 1.12, nil, X4D_Chat.Settings.Defaults)
	local LAM = LibStub("LibAddonMenu-2.0")
	local cplId = LAM:RegisterAddonPanel(
        "X4D_Chat_CPL", 
        {
            type = "panel",
            name = "X4D |cFFAE19Chat",
        })
    
    LAM:RegisterOptionControls(
        "X4D_Chat_CPL", 
        {
            [1] = {
                type = "dropdown",
                name = "Timestamps",
                tooltip = "Timestamp Option",
                choices = {"Disabled", "24 Hour Format", "12 Hour Format"},
                getFunc = function() 
                    return X4D_Chat.Settings.SavedVars.TimestampOption or "24 Hour Format" 
                end,
                setFunc = function(v)
                    X4D_Chat.Settings.SavedVars.TimestampOption = v
                end,
            },
            [2] = {
                type = "checkbox",
                name = "Remove 'Seconds' Component", 
                tooltip = "When enabled, the 'Seconds' component is removed from timestamps.", 
                getFunc = function() return X4D_Chat.Settings.SavedVars.RemoveSeconds end,
                setFunc = function() X4D_Chat.Settings.SavedVars.RemoveSeconds = not X4D_Chat.Settings.SavedVars.RemoveSeconds end,
            },
            [3] = {
                type = "checkbox",
                name = "Show Character Names in Guild Chat", 
                tooltip = "When enabled, Player Names are replaced with Character Names in Guild Chat.", 
                getFunc = function() return X4D_Chat.Settings.SavedVars.GuildCharNames end,
                setFunc = function() X4D_Chat.Settings.SavedVars.GuildCharNames = not X4D_Chat.Settings.SavedVars.GuildCharNames end,
            },
            [4] = {
                type = "checkbox",
                name = "Show Player Names in Guild Chat",
                tooltip = "When enabled, Player Names are appended to Character Names in Guild Chat.", 
                getFunc = function() return X4D_Chat.Settings.SavedVars.GuildPlayerNames end,
                setFunc = function() X4D_Chat.Settings.SavedVars.GuildPlayerNames = not X4D_Chat.Settings.SavedVars.GuildPlayerNames end,
            },
            [5] = {
                type = "checkbox",
                name = "Use Guild Abbrevations", 
                tooltip = "When enabled, Guild Names are replaced with an Abbreviation. Abbrevations are set in the Guild Description e.g. [FOO], or inferred as the capital letters of the guild.", 
                getFunc = function() return X4D_Chat.Settings.SavedVars.UseGuildAbbr end,
                setFunc = function() 
                    X4D_Chat.Settings.SavedVars.UseGuildAbbr = not X4D_Chat.Settings.SavedVars.UseGuildAbbr
                    X4D_Chat.Guilds = {}
                end,
            },
            [6] = {
                type = "checkbox",
            	name = "Use Guild Number", 
                tooltip = "When enabled, Guild Names are replaced with their corresponding Number.", 
                getFunc = function() return X4D_Chat.Settings.SavedVars.UseGuildNum end,
                setFunc = function() 
                    X4D_Chat.Settings.SavedVars.UseGuildNum = not X4D_Chat.Settings.SavedVars.UseGuildNum
                    X4D_Chat.Guilds = {}
                end,
            },
            [7] = {
                type = "checkbox",
            	name = "Strip Colors", 
                tooltip = "When enabled, color codes are stripped from chat messages.", 
                getFunc = function() return X4D_Chat.Settings.SavedVars.StripColors end,
                setFunc = function() X4D_Chat.Settings.SavedVars.StripColors = not X4D_Chat.Settings.SavedVars.StripColors end,
            },
            [8] = {
                type = "checkbox",
                name = "Use Lighter Color for Message Text",
                tooltip = "When enabled, message text appears with a slightly lighter color to improve readability.", 
                getFunc = function() return X4D_Chat.Settings.SavedVars.UseLighterMessageColor end,
                setFunc = function() X4D_Chat.Settings.SavedVars.UseLighterMessageColor = not X4D_Chat.Settings.SavedVars.UseLighterMessageColor end,
            },
            [9] = {
                type = "checkbox",
                name = "Strip Excess Text", 
                tooltip = "When enabled, excess text is stripped from chat messages.", 
                getFunc = function() return X4D_Chat.Settings.SavedVars.StripExcess end,
                setFunc = function() X4D_Chat.Settings.SavedVars.StripExcess = not X4D_Chat.Settings.SavedVars.StripExcess end,
            },
            [10] = {
                type = "checkbox",
                name = "Prevent Chat Fade", 
                tooltip = "When enabled, Chat Text will not Fade.", 
                getFunc = function() return X4D_Chat.Settings.SavedVars.PreventChatFade end,
                setFunc = function() X4D_Chat.Settings.SavedVars.PreventChatFade = not X4D_Chat.Settings.SavedVars.PreventChatFade end,
            },
            [11] = {
                type = "checkbox",
                name = "Disable Friend Status Messages", 
                tooltip = "When enabled, Friend Online/Offline Status Messages are not displayed.", 
                getFunc = function() return X4D_Chat.Settings.SavedVars.DisableFriendStatus end,
                setFunc = function() X4D_Chat.Settings.SavedVars.DisableFriendStatus = not X4D_Chat.Settings.SavedVars.DisableFriendStatus end,
            },
            [12] = {
                type = "editbox",
                name = "Guild #1", 
                tooltip = "An Abbreviation for Guild #1, do not include brackets.", 
                isMultiline = false,
                getFunc = function()
                    return X4D_Chat.Settings.SavedVars.GuildAbbr[1]
                end,
                setFunc = function(v)
                    X4D_Chat.Settings.SavedVars.GuildAbbr[1] = v --_G["X4D_CHAT_EDIT_GUILD1"]["edit"]:GetText()
                end,
                default = X4D_Chat.Settings.SavedVars.GuildAbbr[1],
                width = "half",      
            },
            [13] = {
                type = "editbox",
                name = "Guild #2", 
                tooltip = "An Abbreviation for Guild #2, do not include brackets.", 
                isMultiline = false,
                getFunc = function()
                    return X4D_Chat.Settings.SavedVars.GuildAbbr[2]
                end,
                setFunc = function(v)
                    X4D_Chat.Settings.SavedVars.GuildAbbr[2] = v --_G["X4D_CHAT_EDIT_GUILD2"]["edit"]:GetText()
                end,
                default = X4D_Chat.Settings.SavedVars.GuildAbbr[2],
                width = "half",                
            },
            [14] = {
                type = "editbox",
                name = "Guild #3", 
                tooltip = "An Abbreviation for Guild #3, do not include brackets.", 
                isMultiline = false,
                getFunc = function()
                    return X4D_Chat.Settings.SavedVars.GuildAbbr[3]
                end,
                setFunc = function(v)
                    X4D_Chat.Settings.SavedVars.GuildAbbr[3] = v --_G["X4D_CHAT_EDIT_GUILD3"]["edit"]:GetText()
                end,
                default = X4D_Chat.Settings.SavedVars.GuildAbbr[3],
                width = "half",                
            },
            [15] = {
                type = "editbox",
                name = "Guild #4", 
                tooltip = "An Abbreviation for Guild #4, do not include brackets.", 
                isMultiline = false,
                getFunc = function()
                    return X4D_Chat.Settings.SavedVars.GuildAbbr[4]
                end,
                setFunc = function(v)
                    X4D_Chat.Settings.SavedVars.GuildAbbr[4] = v --_G["X4D_CHAT_EDIT_GUILD4"]["edit"]:GetText()
                end,
                default = X4D_Chat.Settings.SavedVars.GuildAbbr[4],
                width = "half",                
            },
            [16] = {
                type = "editbox",
                name = "Guild #5", 
                tooltip = "An Abbreviation for Guild #5, do not include brackets.", 
                isMultiline = false,
                getFunc = function()
                    return X4D_Chat.Settings.SavedVars.GuildAbbr[5]
                end,
                setFunc = function(v)
                    X4D_Chat.Settings.SavedVars.GuildAbbr[5] = v --_G["X4D_CHAT_EDIT_GUILD5"]["edit"]:GetText()
                end,
                default = X4D_Chat.Settings.SavedVars.GuildAbbr[5],
                width = "half",                
            },
        })

	-- TODO: these really should initialize to values relative to the current game window size/resolution - these values are approximations based on a 1920x1080 (Full HD) resolution
	CHAT_SYSTEM["maxContainerHeight"] = 1000
	CHAT_SYSTEM["maxContainerWidth"] = 1800
	
	EVENT_MANAGER:RegisterForUpdate("X4D_Chat_Update", 1000, OnUpdate)
end

function X4D_Chat.LootCallback(color, text)
	if (color == nil or color:len() < 8) then
		d("LootCallback.. bad color received")
		color = "|cFFFFFF"
	end
	if (text == nil or text:len() == 0) then
		d("LootCallback.. bad text received")
		text = "loot?"
	end
	d(GetTimestampPrefix(color) .. text)
end

function X4D_Chat.XPCallback(color, text)
	if (color == nil or color:len() < 8) then
		d("XPCallback.. bad color received")
		color = "|cFFFFFF"
	end
	if (text == nil or text:len() == 0) then
		d("XPCallback.. bad text received")
		text = "xp?"
	end
	d(GetTimestampPrefix(color) .. text)
end

function X4D_Chat.AntiSpamEmitCallback(color, text)
	if (color == nil or color:len() < 8) then
		d("AntiSpamEmitCallback.. bad color received")
		color = "|cFFFFFF"
	end
	if (text == nil or text:len() == 0) then
		d("AntiSpamEmitCallback.. bad text received")
		text = "spam?"
	end
	d(GetTimestampPrefix(color) ..  text)
end

function X4D_Chat.BankEmitCallback(color, text)
	if (color == nil or color:len() < 8) then
		d("BankEmitCallback.. bad color received")
		color = "|cFFFFFF"
	end
	if (text == nil or text:len() == 0) then
		d("BankEmitCallback.. bad text received")
		text = "huh?"
	end
	d(GetTimestampPrefix(color) .. text)
end

local function OnFriendPlayerStatusChanged(displayName, oldStatus, newStatus)
	if (oldStatus == newStatus) then
		return
	end
	if (X4D_Chat.Settings.SavedVars.DisableFriendStatus) then
		return
	end
    local characterLink = X4D_Chat.CreateCharacterLink(displayName)
	local timestamp = GetTimestampPrefix(X4D_Chat.Colors.SYSTEM)
    if (newStatus == PLAYER_STATUS_OFFLINE) then
	    return timestamp .. zo_strformat(SI_FRIENDS_LIST_FRIEND_LOGGED_OFF, characterLink)
    else
	    return timestamp .. zo_strformat(SI_FRIENDS_LIST_FRIEND_LOGGED_ON, characterLink)
    end
end

local _onServerShutdownInfo = nil

local function OnServerShutdownInfo(action, timeRemaining)
	return GetTimestampPrefix(X4D_Chat.Colors.SYSTEM) .. _onServerShutdownInfo(action, timeRemaining)
end

local _onIgnoreAdded = nil

local function OnIgnoreAdded(displayName)
	return GetTimestampPrefix(X4D_Chat.Colors.SYSTEM) .. _onIgnoreAdded(displayName)
end

local _onIgnoreRemoved = nil

local function OnIgnoreRemoved(displayName)
	return GetTimestampPrefix(X4D_Chat.Colors.SYSTEM) .. _onIgnoreRemoved(displayName)
end

local _onGroupMemberJoined = nil

local function OnGroupMemberJoined(characterName)
	return GetTimestampPrefix(X4D_Chat.Colors.SYSTEM) .. _onGroupMemberJoined(characterName)
end

local _onGroupMemberLeft = nil

local function OnGroupMemberLeft(characterName)
	return GetTimestampPrefix(X4D_Chat.Colors.SYSTEM) .. _onGroupMemberLeft(characterName)
end

local _onGroupTypeChanged = nil

local function OnGroupTypeChanged(largeGroup)
	return GetTimestampPrefix(X4D_Chat.Colors.SYSTEM) .. _onGroupTypeChanged(largeGroup)
end

function X4D_Chat.Register()
	ZO_ChatSystem_AddEventHandler(EVENT_CHAT_MESSAGE_CHANNEL, X4D_Chat.OnChatMessageReceived)
    if (not X4D) then 
        X4D = LibStub("X4D", true)
    end
	if (not X4D_LibAntiSpam) then
		X4D_LibAntiSpam = LibStub("LibAntiSpam", true)
		if (X4D_LibAntiSpam and X4D_LibAntiSpam.RegisterEmitCallback) then
			X4D_LibAntiSpam:RegisterEmitCallback(X4D_Chat.AntiSpamEmitCallback)
		end
	end
	if (not X4D_Loot) then
		X4D_Loot = LibStub("X4D_Loot", true)
		if (X4D_Loot and X4D_Loot.RegisterCallback) then
			X4D_Loot:RegisterCallback(X4D_Chat.LootCallback)
		end
	end
	if (not X4D_Mail) then
		X4D_Mail = LibStub("X4D_Mail", true)
		if (X4D_Mail and X4D_Mail.RegisterEmitCallback) then
			X4D_Mail:RegisterEmitCallback(X4D_Chat.LootCallback)
		end
	end
	if (not X4D_XP) then
		X4D_XP = LibStub("X4D_XP", true)
		if (X4D_XP and X4D_XP.RegisterCallback) then
			X4D_XP:RegisterCallback(X4D_Chat.XPCallback)
		end
	end
	if (not X4D_Bank) then
		X4D_Bank = LibStub("X4D_Bank", true)
		if (X4D_Bank and X4D_Bank.RegisterEmitCallback) then
			X4D_Bank:RegisterEmitCallback(X4D_Chat.BankEmitCallback)
		end
	end

	local r, g, b = GetChatCategoryColor(CHAT_CATEGORY_SYSTEM)
	if (r ~= nil) then
		X4D_Chat.Colors.SYSTEM = X4D_Chat.CreateColorCode(r, g, b)
	end

	local handlers = ZO_ChatSystem_GetEventHandlers()
	if (handlers ~= nil) then
		local friendPlayerStatusHandler = handlers[EVENT_FRIEND_PLAYER_STATUS_CHANGED]
		if (friendPlayerStatusHandler ~= nil) then
			handlers[EVENT_FRIEND_PLAYER_STATUS_CHANGED] = OnFriendPlayerStatusChanged
		end
		if (_onServerShutdownInfo == nil) then
			_onServerShutdownInfo = handlers[EVENT_SERVER_SHUTDOWN_INFO]
			if (_onServerShutdownInfo ~= nil) then
				handlers[EVENT_SERVER_SHUTDOWN_INFO] = OnServerShutdownInfo
			end
		end
		if (_onIgnoreAdded == nil) then
			_onIgnoreAdded = handlers[EVENT_IGNORE_ADDED]
			if (_onIgnoreAdded ~= nil) then
				handlers[EVENT_IGNORE_ADDED] = OnIgnoreAdded
			end
		end
		if (_onIgnoreRemoved == nil) then
			_onIgnoreRemoved = handlers[EVENT_IGNORE_REMOVED]
			if (_onIgnoreRemoved ~= nil) then
				handlers[EVENT_IGNORE_REMOVED] = OnIgnoreRemoved
			end
		end
		if (_onGroupMemberJoined == nil) then
			_onGroupMemberJoined = handlers[EVENT_GROUP_MEMBER_JOINED]
			if (_onGroupMemberJoined ~= nil) then
				handlers[EVENT_GROUP_MEMBER_JOINED] = OnGroupMemberJoined
			end
		end
		if (_onGroupMemberLeft == nil) then
			_onGroupMemberLeft = handlers[EVENT_GROUP_MEMBER_LEFT]
			if (_onGroupMemberLeft ~= nil) then
				handlers[EVENT_GROUP_MEMBER_LEFT] = OnGroupMemberLeft
			end
		end
		if (_onGroupTypeChanged == nil) then
			_onGroupTypeChanged = handlers[EVENT_GROUP_TYPE_CHANGED]
			if (_onGroupTypeChanged ~= nil) then
				handlers[EVENT_GROUP_TYPE_CHANGED] = OnGroupTypeChanged
			end
		end
	end	
end 

function X4D_Chat.Unregister()
	ZO_ChatSystem_AddEventHandler(EVENT_CHAT_MESSAGE_CHANNEL, nil)
end

local function OnPlayerActivated()
	zo_callLater(X4D_Chat.Register, 3000)
end

EVENT_MANAGER:RegisterForEvent(X4D_Chat.NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(X4D_Chat.NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
