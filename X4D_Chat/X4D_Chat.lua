X4D_Chat = {};

local X4D_LibAntiSpam = nil;
local X4D_Loot = nil;
local X4D_XP = nil;
local X4D_Bank = nil;

X4D_Chat.NAME = 'X4D_Chat';
X4D_Chat.VERSION = 1.22;

X4D_Chat.Settings = {};
X4D_Chat.Settings.SavedVars = {};
X4D_Chat.Settings.Defaults = {
	GuildCharNames = true,
	GuildPlayerNames = false,
	UseGuildAbbr = true,
	GuildAbbr = {
		[1] = '',
		[2] = '',
		[3] = '',
		[4] = '',
		[5] = '',
	};
	UseGuildNum = false,
	TimestampOption = '24 Hour Format',
	RemoveSeconds = false,
	StripColors = false,
	StripExcess = true,
	PreventChatFade = true,
	DisableFriendStatus = false,
};

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
	[CHAT_CHANNEL_WHISPER_NOT_FOUND] = CHAT_CATEGORY_OUTGOING,
	[CHAT_CHANNEL_WHISPER_SENT] = CHAT_CATEGORY_WHISPER_OUTGOING,
	[CHAT_CHANNEL_YELL] = CHAT_CATEGORY_YELL,
	[CHAT_CHANNEL_ZONE] = CHAT_CATEGORY_ZONE,
	[CHAT_CHANNEL_ZONE_LANGUAGE_1] = CHAT_CATEGORY_ZONE_ENGLISH,
	[CHAT_CHANNEL_ZONE_LANGUAGE_2] = CHAT_CATEGORY_ZONE_FRENCH,
	[CHAT_CHANNEL_ZONE_LANGUAGE_3] = CHAT_CATEGORY_ZONE_GERMAN,
};

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
};

X4D_Chat.Colors = {
	SystemChannel = '|cFFFF00',
};

local function GetTimestampPrefix(color)
	if (X4D_Chat.Settings.SavedVars.TimestampOption == nil) then
		X4D_Chat.Settings.SavedVars.TimestampOption = X4D_Chat.Settings.Defaults.TimestampOption;
	elseif (X4D_Chat.Settings.SavedVars.TimestampOption == 'Disabled') then
		return color;
	end

	local timeString = GetTimeString();

	if (X4D_Chat.Settings.SavedVars.TimestampOption == '12 Hour Format') then
		local hour = timeString:gmatch('(%d%d).%d%d.%d%d')();
		if (tonumber(hour) > 12) then
			hour = tostring(tonumber(hour) - 12);
			if (hour:len() == 1) then
				hour = '0' .. hour;
			end
			if (X4D_Chat.Settings.SavedVars.RemoveSeconds) then
				timeString = timeString:gsub('%d%d.(%d%d).%d%d', hour .. ':%1 PM');
			else
				timeString = timeString:gsub('%d%d.(%d%d).(%d%d)', hour .. ':%1:%2 PM');
			end
		else
			if (hour == "00") then
				hour = "12";
			end
			if (X4D_Chat.Settings.SavedVars.RemoveSeconds) then
				timeString = timeString:gsub('%d%d.(%d%d).%d%d', hour .. ':%1 AM');
			else
				timeString = timeString:gsub('%d%d.(%d%d).(%d%d)', hour .. ':%1:%2 AM');
			end
		end
	elseif (X4D_Chat.Settings.SavedVars.RemoveSeconds) then
		timeString = timeString:gsub('(%d%d).(%d%d).%d%d', '%1:%2');
	end

	local highlightColor = X4D_Chat.DeriveHighlightColorCode(color);
	return color .. '[' .. highlightColor .. timeString .. color .. '] ';
end

function X4D_Chat.OnChatMessageReceived(messageType, fromName, text)
	if (X4D_LibAntiSpam) then
		local isSpam, isFlood = false, false;
		if (X4D_LibAntiSpam.Check) then
			isSpam, isFlood = X4D_LibAntiSpam:Check(text, fromName);
		elseif (X4D_LibAntiSpam.IsSpam) then
			isSpam, isFlood = X4D_LibAntiSpam:IsSpam(text, fromName);
		end
		if (isSpam or isFlood) then
			return;
		end
	end

    local ChannelInfo = ZO_ChatSystem_GetChannelInfo();
    local channelInfo = ChannelInfo[messageType];
	local result = nil;
	text = X4D_Chat.StripColors(text)
    if (channelInfo and channelInfo.format) then
		local category = X4D_Chat.GetChatCategory(channelInfo);
        local channelLink = X4D_Chat.CreateChannelLink(channelInfo, category)
        local fromLink = X4D_Chat.CreateCharacterLink(fromName, channelInfo)
        if (channelLink) then
            result = zo_strformat(channelInfo.format, channelLink, fromLink, text);
        else
			result = zo_strformat(channelInfo.format, fromLink, text);
			if (X4D_Chat.Settings.SavedVars.StripExcess) then
				result = result:gsub('%]%|h%s?.-%:', ']|h:', 1);
			end
		end
		local r, g, b = GetChatCategoryColor(category);
		local chatColor = X4D_Chat.CreateColorCode(r, g, b);
		return GetTimestampPrefix(chatColor) .. result, channelInfo.saveTarget;
    end
end

function X4D_Chat.GetChatCategory(channelInfo)
	local category = X4D_Chat.ChannelCategory[channelInfo.id];
	if (category ~= nil) then
		return category;
	end
	return CHAT_CATEGORY_ZONE;
end

function X4D_Chat.CreateColorCode(r, g, b)
	return '|c' .. DEC2HEX(r * 255) .. DEC2HEX(g * 255) .. DEC2HEX(b * 255);
end

function X4D_Chat.ParseColorCode(color)
	return HEX2DEC(color, 3)/256, HEX2DEC(color, 5)/256, HEX2DEC(color, 7)/256, 1;
end

function X4D_Chat.DeriveHighlightColorCode(color)
	local r, g, b, a = X4D_Chat.ParseColorCode(color);
	r = r * 1.5;
	if (r > 1) then
		r = 1;
	end
	g = g * 1.5;
	if (g > 1) then
		g = 1;
	end
	b = b * 1.5;
	if (b > 1) then
		b = 1;
	end
	return X4D_Chat.CreateColorCode(r, g, b);
end

function X4D_Chat.CreateChannelLink(channelInfo, category)
	if (category == CHAT_CATEGORY_OFFICER_1) then 
		category = CHAT_CATEGORY_GUILD_1;
	elseif (category == CHAT_CATEGORY_OFFICER_2) then 
		category = CHAT_CATEGORY_GUILD_2;
	elseif (category == CHAT_CATEGORY_OFFICER_3) then 
		category = CHAT_CATEGORY_GUILD_3;
	elseif (category == CHAT_CATEGORY_OFFICER_4) then 
		category = CHAT_CATEGORY_GUILD_4;
	elseif (category == CHAT_CATEGORY_OFFICER_5) then 
		category = CHAT_CATEGORY_GUILD_5;
	end
    if (channelInfo.channelLinkable) then
        local channelName = GetChannelName(channelInfo.id);
        local result = ZO_LinkHandler_CreateChannelLink(channelName);
		local guild = nil;
		local guildNum = nil;
		if (category) then
			if (not X4D_Chat.Guilds[category] or X4D_Chat.Guilds[category].Time <= (GetGameTimeMilliseconds() - 5000)) then
				local guildId = nil;
				if (category == CHAT_CATEGORY_GUILD_1) then					
					guildId = GetGuildId(1);
					guildNum = 1;
				elseif (category == CHAT_CATEGORY_GUILD_2) then
					guildId = GetGuildId(2);
					guildNum = 2;
				elseif (category == CHAT_CATEGORY_GUILD_3) then
					guildId = GetGuildId(3);
					guildNum = 3;
				elseif (category == CHAT_CATEGORY_GUILD_4) then
					guildId = GetGuildId(4);
					guildNum = 4;
				elseif (category == CHAT_CATEGORY_GUILD_5) then
					guildId = GetGuildId(5);
					guildNum = 5;
				end				
				X4D_Chat.Guilds[category] = {
					Id = guildId,
					Time = GetGameTimeMilliseconds(),
					Num = guildNum,
				};
			end
			guild = X4D_Chat.Guilds[category];
		end
		if (guild) then
			if (X4D_Chat.Settings.SavedVars.UseGuildAbbr) then
				if (not guild.Abbr) then
					if (X4D_Chat.Settings.SavedVars.GuildAbbr[guild.Num] and X4D_Chat.Settings.SavedVars.GuildAbbr[guild.Num]:len() > 0) then
						guild.Abbr = X4D_Chat.Settings.SavedVars.GuildAbbr[guild.Num];
					else
						if (not guild.Description) then
							guild.Description = GetGuildDescription(guild.Id);
						end
						if (guild.Description and guild.Description:len() > 0) then
							for word in guild.Description:gmatch('%[.-%]') do 
								guild.Abbr = word:gsub('([%[%]])', '');
								break;
							end
						end
						if (not guild.Abbr or guild.Abbr:len() == 0) then
							local abbr = channelName:gsub('[^%a%d]', ''):sub(1, 1);
							for w in channelName:gmatch('[^%a%d](.)') do
								abbr = abbr .. w;
							end
							guild.Abbr = abbr;
						end
					end
				end
			end
			if (X4D_Chat.Settings.SavedVars.UseGuildNum) then
				if (not guild.Num) then
					guild.Num = guildNum;
				end
			end
			channelName = channelName:gsub('([^%a%d%s])', '%%%1');
			if (X4D_Chat.Settings.SavedVars.UseGuildNum and guild.Abbr and guild.Abbr:len() > 0 and guild.Num) then
				result = result:gsub(channelName, guild.Num .. '/' .. guild.Abbr);
			elseif (guild.Abbr and guild.Abbr:len() > 0) then
				result = result:gsub(channelName, guild.Abbr);
			elseif (X4D_Chat.Settings.SavedVars.UseGuildNum and guild.Num) then
				result = result:gsub(channelName, guild.Num);
			end
		end
		return result;
    end
end

X4D_Chat.Players = {};

local function GetPlayer(fromName)
	return X4D_Chat.Players[fromName];
end

local function AddPlayer(fromName)
	local player = {
		Time = GetGameTimeMilliseconds(),
		From = fromName,
	};
	X4D_Chat.Players[fromName] = player;
	return player;
end

local function TryUpdatePlayerCharacterName(player, fromName)
	if (string.StartsWith(fromName,'@')) then
		for guildIndex = 1,GetNumGuilds() do
			local guildId = GetGuildId(guildIndex);
			if (guildId ~= nil) then
				for memberIndex = 1,GetNumGuildMembers(guildId) do
					local name, note, rankIndex, playerStatus, secsSinceLogoff = GetGuildMemberInfo(guildId, memberIndex)
					if (name == fromName) then
						local hasCharacter, characterName, zoneName, classType, alliance, level, veteranRank = GetGuildMemberCharacterInfo(guildId, memberIndex)
						if (characterName ~= nil and characterName:len() > 0) then
							player.CharacterName = characterName:gsub('%^.*', '');
							break;
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
	local result = fromName;
	if (X4D_Chat.Settings.SavedVars.GuildCharNames) then
		local player = GetPlayer(fromName);
		if (not (player and player.CharacterName and player.Time >= (GetGameTimeMilliseconds() - 15000))) then
			player = AddPlayer(fromName);
			TryUpdatePlayerCharacterName(player, fromName);
		end
		if (not player.CharacterName) then
			player.CharacterName = fromName;					
		end				
		if (player.CharacterName) then
			result = player.CharacterName;
		end
	end
    if (channelInfo == nil or channelInfo.playerLinkable) then
		if (result and result ~= fromName) then
			local rep = fromName:gsub('([^%a%d%s])', '%%%1');
			local linkName = ZO_LinkHandler_CreatePlayerLink(fromName);
			if (linkName) then
				if (X4D_Chat.Settings.SavedVars.GuildPlayerNames) then
					result = linkName:gsub(rep, result .. fromName);
				else
					result = linkName:gsub(rep, result);
				end
			end
		else
			result = ZO_LinkHandler_CreatePlayerLink(fromName);
		end
    end
    return result
end

function X4D_Chat.StripColors(text)
	if (X4D_Chat.Settings.SavedVars.StripColors) then
		return text:gsub('%|c%x%x%x%x%x%x', '');
	end
	return text;
end

local function StringSplit(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		local s = tostring(match);
		if (s:len() > 0) then
			table.insert(result, match);
		end
    end
    return result;
end

function HEX2DEC(input, offset)
	return (tonumber(input:sub(offset, offset), 16) * 16) + tonumber(input:sub(offset + 1, offset + 1), 16);
end

function DEC2HEX(input)
	local h = (input / 16);
	local l = (input - (h * 16));
	return string.format('%x%x', h, l);
end

function string.StartsWith(String,Start)
   return string.sub(String,1,string.len(Start))==Start;
end

local _nextUpdateTime = 0;

local function OnUpdate(...)
	local timeNow = GetGameTimeMilliseconds();
	if (_nextUpdateTime >= timeNow) then
		return;
	end
	_nextUpdateTime = timeNow + 5000;	
	X4D_Chat.Register();
	if (X4D_Chat.Settings.SavedVars.PreventChatFade) then
		if (ZO_ChatWindow.container and ZO_ChatWindow.container.currentBuffer) then
			ZO_ChatWindow.container.currentBuffer:ShowFadedLines();
		end
	end
end

local function SetComboboxValue(controlName, value)
	local combobox = _G[controlName];
	local dropmenu = ZO_ComboBox_ObjectFromContainer(GetControl(combobox, "Dropdown"));
	local items = dropmenu:GetItems();
	for k,v in pairs(items) do
		if (v.name == value) then
			dropmenu:SetSelectedItem(v.name);
		end
	end
end

local function SetCheckboxValue(controlName, value)
	local checkbox = _G[controlName]:GetNamedChild('Checkbox');
	checkbox:SetState(value and 1 or 0);
	checkbox:toggleFunction(value);
end

local function SetSliderValue(controlName, value, minValue, maxValue)
	local range = maxValue - minValue
	local slider = _G[controlName];
	local slidercontrol = slider:GetNamedChild("Slider");
	local slidervalue = slider:GetNamedChild("ValueLabel");
	slidercontrol:SetValue((value - minValue)/range);
	slidervalue:SetText(tostring(value));
end

local function SetEditBoxValue(controlName, value, maxInputChars)
	if (maxInputChars and maxInputChars > 0) then
		_G[controlName]['edit']:SetMaxInputChars(maxInputChars);
	end
	_G[controlName]['edit']:SetText(value);
end

function X4D_Chat.OnAddOnLoaded(event, addonName)
	if (addonName ~= X4D_Chat.NAME) then
		return;
	end	
	X4D_Chat.Settings.SavedVars = ZO_SavedVars:NewAccountWide(X4D_Chat.NAME .. '_SV', 1.12, nil, X4D_Chat.Settings.Defaults);
	local LAM = LibStub('LibAddonMenu-1.0');
	local cplId = LAM:CreateControlPanel('X4D_Chat_CPL', 'X4D |cFFAE19Chat');	
	LAM:AddHeader(cplId, 
		'X4D_CHAT_HEADER_SETTINGS', 'Settings');

	LAM:AddDropdown(cplId, 'X4D_CHAT_OPTION_TIMESTAMPS', 'Timestamps',
		'Timestamp Option', {'Disabled', '24 Hour Format', '12 Hour Format'},
		function() return X4D_Chat.Settings.SavedVars.TimestampOption or '24 Hour Format' end,
		function(option)
			X4D_Chat.Settings.SavedVars.TimestampOption = option;
		end);

	LAM:AddCheckbox(cplId, 
		'X4D_CHAT_CHECK_REMOVESECONDS', 'Remove "Seconds" Component', 
		'When enabled, the "Seconds" component is removed from timestamps.', 
		function() return X4D_Chat.Settings.SavedVars.RemoveSeconds end,
		function() X4D_Chat.Settings.SavedVars.RemoveSeconds = not X4D_Chat.Settings.SavedVars.RemoveSeconds end);

	LAM:AddCheckbox(cplId, 
		'X4D_CHAT_CHECK_GUILD_CHARNAMES', 'Show Character Names in Guild Chat', 
		'When enabled, Player Names are replaced with Character Names in Guild Chat.', 
		function() return X4D_Chat.Settings.SavedVars.GuildCharNames end,
		function() X4D_Chat.Settings.SavedVars.GuildCharNames = not X4D_Chat.Settings.SavedVars.GuildCharNames end);
	
	LAM:AddCheckbox(cplId, 
		'X4D_CHAT_CHECK_GUILD_PLAYERNAMES', 'Show Player Names in Guild Chat', 
		'When enabled, Player Names are replaced with Character Names in Guild Chat.', 
		function() return X4D_Chat.Settings.SavedVars.GuildPlayerNames end,
		function() X4D_Chat.Settings.SavedVars.GuildPlayerNames = not X4D_Chat.Settings.SavedVars.GuildPlayerNames end);
	
	LAM:AddCheckbox(cplId, 
		'X4D_CHAT_CHECK_GUILD_ABBR', 'Use Guild Abbrevations', 
		'When enabled, Guild Names are replaced with an Abbreviation. Abbrevations are set in the Guild Description e.g. [FOO], or inferred as the capital letters of the guild.', 
		function() return X4D_Chat.Settings.SavedVars.UseGuildAbbr end,
		function() 
			X4D_Chat.Settings.SavedVars.UseGuildAbbr = not X4D_Chat.Settings.SavedVars.UseGuildAbbr;
			X4D_Chat.Guilds = {};
		end);
	
	LAM:AddCheckbox(cplId, 
		'X4D_CHAT_CHECK_GUILD_NUM', 'Use Guild Number', 
		'When enabled, Guild Names are replaced with their corresponding Number.', 
		function() return X4D_Chat.Settings.SavedVars.UseGuildNum end,
		function() 
			X4D_Chat.Settings.SavedVars.UseGuildNum = not X4D_Chat.Settings.SavedVars.UseGuildNum;
			X4D_Chat.Guilds = {};
		end);
	
	LAM:AddCheckbox(cplId, 
		'X4D_CHAT_CHECK_STRIP_COLORS', 'Strip Colors', 
		'When enabled, color codes are stripped from chat messages.', 
		function() return X4D_Chat.Settings.SavedVars.StripColors end,
		function() X4D_Chat.Settings.SavedVars.StripColors = not X4D_Chat.Settings.SavedVars.StripColors end);
	
	LAM:AddCheckbox(cplId, 
		'X4D_CHAT_CHECK_STRIP_EXCESS', 'Strip Excess Text', 
		'When enabled, excess text is stripped from chat messages.', 
		function() return X4D_Chat.Settings.SavedVars.StripExcess end,
		function() X4D_Chat.Settings.SavedVars.StripExcess = not X4D_Chat.Settings.SavedVars.StripExcess end);
	
	LAM:AddCheckbox(cplId, 
		'X4D_CHAT_CHECK_PREVENT_FADE', 'Prevent Chat Fade', 
		'When enabled, Chat Window will not Fade.', 
		function() return X4D_Chat.Settings.SavedVars.PreventChatFade end,
		function() X4D_Chat.Settings.SavedVars.PreventChatFade = not X4D_Chat.Settings.SavedVars.PreventChatFade end);
	
	LAM:AddCheckbox(cplId, 
		'X4D_CHAT_CHECK_DISABLE_FRIEND_STATUS', 'Disable Friend Status Messages', 
		'When enabled, Friend Online/Offline Status Messages are not displayed.', 
		function() return X4D_Chat.Settings.SavedVars.DisableFriendStatus end,
		function() X4D_Chat.Settings.SavedVars.DisableFriendStatus = not X4D_Chat.Settings.SavedVars.DisableFriendStatus end);
		
	LAM:AddEditBox(cplId, 
		'X4D_CHAT_EDIT_GUILD1', 'Guild #1', 
		'An Abbreviation for Guild #1, do not include brackets.', 
		false,
		function()
			return X4D_Chat.Settings.SavedVars.GuildAbbr[1];
		end,
		function()
			X4D_Chat.Settings.SavedVars.GuildAbbr[1] = _G['X4D_CHAT_EDIT_GUILD1']['edit']:GetText();
		end);
	SetEditBoxValue('X4D_CHAT_EDIT_GUILD1', X4D_Chat.Settings.SavedVars.GuildAbbr[1], 10);

	LAM:AddEditBox(cplId, 
		'X4D_CHAT_EDIT_GUILD2', 'Guild #2', 
		'An Abbreviation for Guild #2, do not include brackets.', 
		false,
		function()
			return X4D_Chat.Settings.SavedVars.GuildAbbr[2];
		end,
		function()
			X4D_Chat.Settings.SavedVars.GuildAbbr[2] = _G['X4D_CHAT_EDIT_GUILD2']['edit']:GetText();
		end);
	SetEditBoxValue('X4D_CHAT_EDIT_GUILD2', X4D_Chat.Settings.SavedVars.GuildAbbr[2], 10);

	LAM:AddEditBox(cplId, 
		'X4D_CHAT_EDIT_GUILD3', 'Guild #3', 
		'An Abbreviation for Guild #3, do not include brackets.', 
		false,
		function()
			return X4D_Chat.Settings.SavedVars.GuildAbbr[3];
		end,
		function()
			X4D_Chat.Settings.SavedVars.GuildAbbr[3] = _G['X4D_CHAT_EDIT_GUILD3']['edit']:GetText();
		end);
	SetEditBoxValue('X4D_CHAT_EDIT_GUILD3', X4D_Chat.Settings.SavedVars.GuildAbbr[3], 10);

	LAM:AddEditBox(cplId, 
		'X4D_CHAT_EDIT_GUILD4', 'Guild #4', 
		'An Abbreviation for Guild #4, do not include brackets.', 
		false,
		function()
			return X4D_Chat.Settings.SavedVars.GuildAbbr[4];
		end,
		function()
			X4D_Chat.Settings.SavedVars.GuildAbbr[4] = _G['X4D_CHAT_EDIT_GUILD4']['edit']:GetText();
		end);
	SetEditBoxValue('X4D_CHAT_EDIT_GUILD4', X4D_Chat.Settings.SavedVars.GuildAbbr[4], 10);

	LAM:AddEditBox(cplId, 
		'X4D_CHAT_EDIT_GUILD5', 'Guild #5', 
		'An Abbreviation for Guild #5, do not include brackets.', 
		false,
		function()
			return X4D_Chat.Settings.SavedVars.GuildAbbr[5];
		end,
		function()
			X4D_Chat.Settings.SavedVars.GuildAbbr[5] = _G['X4D_CHAT_EDIT_GUILD5']['edit']:GetText();
		end);
	SetEditBoxValue('X4D_CHAT_EDIT_GUILD5', X4D_Chat.Settings.SavedVars.GuildAbbr[5], 10);
		
	ZO_PreHook("ZO_OptionsWindow_ChangePanels", function(panel)
			if (panel == cplId) then				
				ZO_OptionsWindowResetToDefaultButton:SetCallback(function ()
					if (ZO_OptionsWindowResetToDefaultButton:GetParent()['currentPanel'] == cplId) then

						SetCheckboxValue('X4D_CHAT_CHECK_GUILD_CHARNAMES', X4D_Chat.Settings.Defaults.GuildCharNames);
						X4D_Chat.Settings.SavedVars.GuildCharNames = X4D_Chat.Settings.Defaults.GuildCharNames;

						SetCheckboxValue('X4D_CHAT_CHECK_GUILD_PLAYERNAMES', X4D_Chat.Settings.Defaults.GuildPlayerNames);
						X4D_Chat.Settings.SavedVars.GuildPlayerNames = X4D_Chat.Settings.Defaults.GuildPlayerNames;

						SetCheckboxValue('X4D_CHAT_CHECK_GUILD_ABBR', X4D_Chat.Settings.Defaults.UseGuildAbbr);
						X4D_Chat.Settings.SavedVars.UseGuildAbbr = X4D_Chat.Settings.Defaults.UseGuildAbbr;
	
						SetCheckboxValue('X4D_CHAT_CHECK_GUILD_NUM', X4D_Chat.Settings.Defaults.UseGuildNum);
						X4D_Chat.Settings.SavedVars.UseGuildNum = X4D_Chat.Settings.Defaults.UseGuildNum;
	
						SetComboboxValue('X4D_CHAT_OPTION_TIMESTAMPS', X4D_Chat.Settings.Defaults.TimestampOption);
						X4D_Chat.Settings.SavedVars.TimestampOption = X4D_Chat.Settings.Defaults.TimestampOption;
	
						SetCheckboxValue('X4D_CHAT_CHECK_STRIP_COLORS', X4D_Chat.Settings.Defaults.StripColors);
						X4D_Chat.Settings.SavedVars.StripColors = X4D_Chat.Settings.Defaults.StripColors;
	
						SetCheckboxValue('X4D_CHAT_CHECK_STRIP_EXCESS', X4D_Chat.Settings.Defaults.StripExcess);
						X4D_Chat.Settings.SavedVars.StripExcess = X4D_Chat.Settings.Defaults.StripExcess;

						SetCheckboxValue('X4D_CHAT_CHECK_PREVENT_FADE', X4D_Chat.Settings.Defaults.PreventChatFade);
						X4D_Chat.Settings.SavedVars.PreventChatFade = X4D_Chat.Settings.Defaults.PreventChatFade;

						SetCheckboxValue('X4D_CHAT_CHECK_DISABLE_FRIEND_STATUS', X4D_Chat.Settings.Defaults.DisableFriendStatus);
						X4D_Chat.Settings.SavedVars.DisableFriendStatus = X4D_Chat.Settings.Defaults.DisableFriendStatus;
						
						SetEditBoxValue('X4D_CHAT_EDIT_GUILD1', '', 10);
						X4D_Chat.Settings.SavedVars.GuildAbbr[1] = '';
						SetEditBoxValue('X4D_CHAT_EDIT_GUILD2', '', 10);
						X4D_Chat.Settings.SavedVars.GuildAbbr[2] = '';
						SetEditBoxValue('X4D_CHAT_EDIT_GUILD3', '', 10);
						X4D_Chat.Settings.SavedVars.GuildAbbr[3] = '';
						SetEditBoxValue('X4D_CHAT_EDIT_GUILD4', '', 10);
						X4D_Chat.Settings.SavedVars.GuildAbbr[4] = '';
						SetEditBoxValue('X4D_CHAT_EDIT_GUILD5', '', 10);
						X4D_Chat.Settings.SavedVars.GuildAbbr[5] = '';
						
					end
				end);
			end
		end);		

	-- TODO: these really should intitialize to values relative to the current game window size/resolution - these values are approximations based on a 1920x1080 (Full HD) resolution
	CHAT_SYSTEM['maxContainerHeight'] = 1000;
	CHAT_SYSTEM['maxContainerWidth'] = 1800;
	
	EVENT_MANAGER:RegisterForUpdate('X4D_Chat_Update', 1000, OnUpdate);
end

function X4D_Chat.LootCallback(color, text)
	if (color == nil or color:len() < 8) then
		d('LootCallback.. bad color received');
		color = '|cFFFFFF';
	end
	if (text == nil or text:len() == 0) then
		d('LootCallback.. bad text received');
		text = 'loot?';
	end
	d(GetTimestampPrefix(color) .. text);
end

function X4D_Chat.XPCallback(color, text)
	if (color == nil or color:len() < 8) then
		d('LootCallback.. bad color received');
		color = '|cFFFFFF';
	end
	if (text == nil or text:len() == 0) then
		d('LootCallback.. bad text received');
		text = 'xp?';
	end
	d(GetTimestampPrefix(color) .. text);
end

function X4D_Chat.AntiSpamEmitCallback(color, text)
	if (color == nil or color:len() < 8) then
		d('AntiSpamEmitCallback.. bad color received');
		color = '|cFFFFFF';
	end
	if (text == nil or text:len() == 0) then
		d('AntiSpamEmitCallback.. bad text received');
		text = 'spam?';
	end
	d(GetTimestampPrefix(color) ..  text);
end

function X4D_Chat.BankEmitCallback(color, text)
	if (color == nil or color:len() < 8) then
		d('BankEmitCallback.. bad color received');
		color = '|cFFFFFF';
	end
	if (text == nil or text:len() == 0) then
		d('BankEmitCallback.. bad text received');
		text = 'huh?';
	end
	d(GetTimestampPrefix(color) ..  text);
end

local function OnFriendPlayerStatusChanged(displayName, oldStatus, newStatus)
	if (oldStatus == newStatus) then
		return;
	end
	if (X4D_Chat.Settings.SavedVars.DisableFriendStatus) then
		return;
	end
    local characterLink = X4D_Chat.CreateCharacterLink(displayName);
	local timestamp = GetTimestampPrefix(X4D_Chat.Colors.SystemChannel);
    if (newStatus == PLAYER_STATUS_OFFLINE) then
	    return timestamp .. zo_strformat(SI_FRIENDS_LIST_FRIEND_LOGGED_OFF, characterLink);
    else
	    return timestamp .. zo_strformat(SI_FRIENDS_LIST_FRIEND_LOGGED_ON, characterLink);
    end
end

local _onServerShutdownInfo = nil;

local function OnServerShutdownInfo(action, timeRemaining)
	return GetTimestampPrefix(X4D_Chat.Colors.SystemChannel) .. _onServerShutdownInfo(action, timeRemaining);
end

local _onIgnoreAdded = nil;

local function OnIgnoreAdded(displayName)
	return GetTimestampPrefix(X4D_Chat.Colors.SystemChannel) .. _onIgnoreAdded(displayName);
end

local _onIgnoreRemoved = nil;

local function OnIgnoreRemoved(displayName)
	return GetTimestampPrefix(X4D_Chat.Colors.SystemChannel) .. _onIgnoreRemoved(displayName);
end

local _onGroupMemberJoined = nil;

local function OnGroupMemberJoined(characterName)
	return GetTimestampPrefix(X4D_Chat.Colors.SystemChannel) .. _onGroupMemberJoined(characterName);
end

local _onGroupMemberLeft = nil;

local function OnGroupMemberLeft(characterName)
	return GetTimestampPrefix(X4D_Chat.Colors.SystemChannel) .. _onGroupMemberLeft(characterName);
end

local _onGroupTypeChanged = nil;

local function OnGroupTypeChanged(largeGroup)
	return GetTimestampPrefix(X4D_Chat.Colors.SystemChannel) .. _onGroupTypeChanged(largeGroup);
end

function X4D_Chat.Register()
	ZO_ChatSystem_AddEventHandler(EVENT_CHAT_MESSAGE_CHANNEL, X4D_Chat.OnChatMessageReceived);
	if (not X4D_LibAntiSpam) then
		X4D_LibAntiSpam = LibStub('LibAntiSpam', true);
		if (X4D_LibAntiSpam and X4D_LibAntiSpam.RegisterEmitCallback) then
			X4D_LibAntiSpam:RegisterEmitCallback(X4D_Chat.AntiSpamEmitCallback);
		end
	end
	if (not X4D_Loot) then
		X4D_Loot = LibStub('X4D_Loot', true);
		if (X4D_Loot and X4D_Loot.RegisterCallback) then
			X4D_Loot:RegisterCallback(X4D_Chat.LootCallback);
		end
	end
	if (not X4D_XP) then
		X4D_XP = LibStub('X4D_XP', true);
		if (X4D_XP and X4D_XP.RegisterCallback) then
			X4D_XP:RegisterCallback(X4D_Chat.XPCallback);
		end
	end
	if (not X4D_Bank) then
		X4D_Bank = LibStub('X4D_Bank', true);
		if (X4D_Bank and X4D_Bank.RegisterEmitCallback) then
			X4D_Bank:RegisterEmitCallback(X4D_Chat.BankEmitCallback);
		end
	end

	local r, g, b = GetChatCategoryColor(CHAT_CATEGORY_SYSTEM);
	if (r ~= nil) then
		X4D_Chat.Colors.SystemChannel = X4D_Chat.CreateColorCode(r, g, b);
	end

	local handlers = ZO_ChatSystem_GetEventHandlers();
	if (handlers ~= nil) then
		local friendPlayerStatusHandler = handlers[EVENT_FRIEND_PLAYER_STATUS_CHANGED];
		if (friendPlayerStatusHandler ~= nil) then
			handlers[EVENT_FRIEND_PLAYER_STATUS_CHANGED] = OnFriendPlayerStatusChanged;
		end
		if (_onServerShutdownInfo == nil) then
			_onServerShutdownInfo = handlers[EVENT_SERVER_SHUTDOWN_INFO];
			if (_onServerShutdownInfo ~= nil) then
				handlers[EVENT_SERVER_SHUTDOWN_INFO] = OnServerShutdownInfo;
			end
		end
		if (_onIgnoreAdded == nil) then
			_onIgnoreAdded = handlers[EVENT_IGNORE_ADDED];
			if (_onIgnoreAdded ~= nil) then
				handlers[EVENT_IGNORE_ADDED] = OnIgnoreAdded;
			end
		end
		if (_onIgnoreRemoved == nil) then
			_onIgnoreRemoved = handlers[EVENT_IGNORE_REMOVED];
			if (_onIgnoreRemoved ~= nil) then
				handlers[EVENT_IGNORE_REMOVED] = OnIgnoreRemoved;
			end
		end
		if (_onGroupMemberJoined == nil) then
			_onGroupMemberJoined = handlers[EVENT_GROUP_MEMBER_JOINED];
			if (_onGroupMemberJoined ~= nil) then
				handlers[EVENT_GROUP_MEMBER_JOINED] = OnGroupMemberJoined;
			end
		end
		if (_onGroupMemberLeft == nil) then
			_onGroupMemberLeft = handlers[EVENT_GROUP_MEMBER_LEFT];
			if (_onGroupMemberLeft ~= nil) then
				handlers[EVENT_GROUP_MEMBER_LEFT] = OnGroupMemberLeft;
			end
		end
		if (_onGroupTypeChanged == nil) then
			_onGroupTypeChanged = handlers[EVENT_GROUP_TYPE_CHANGED];
			if (_onGroupTypeChanged ~= nil) then
				handlers[EVENT_GROUP_TYPE_CHANGED] = OnGroupTypeChanged;
			end
		end
	end	
end 

function X4D_Chat.Unregister()
	ZO_ChatSystem_AddEventHandler(EVENT_CHAT_MESSAGE_CHANNEL, nil);
end

function X4D_Chat.OnPlayerActivated()
	zo_callLater(X4D_Chat.Register, 3000);
end

EVENT_MANAGER:RegisterForEvent(X4D_Chat.NAME, EVENT_ADD_ON_LOADED, X4D_Chat.OnAddOnLoaded);
EVENT_MANAGER:RegisterForEvent(X4D_Chat.NAME, EVENT_PLAYER_ACTIVATED, X4D_Chat.OnPlayerActivated);
