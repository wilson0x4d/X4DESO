local X4D_LibAntiSpam = LibStub:NewLibrary('LibAntiSpam', 1.49);
if (not X4D_LibAntiSpam) then
	return;
end

X4D_LibAntiSpam.NAME = 'X4D_LibAntiSpam';
X4D_LibAntiSpam.VERSION = '1.49';

X4D_LibAntiSpam.Options = {};
X4D_LibAntiSpam.Options.Saved = {};
X4D_LibAntiSpam.Options.Default = {
	NotifyWhenDetected = true,
	UseInternalPatterns = true,
	FloodTime = 30,
	ShowNormalizations = false,
	Patterns = {},
};

local function GetOption(name)
	local scope = 'Account-Wide';
	if (X4D_LibAntiSpam.Options.Saved.SettingsAre and X4D_LibAntiSpam.Options.Saved.SettingsAre ~= 'Account-Wide') then
		scope = GetUnitName("player");
	end
	local scoped = X4D_LibAntiSpam.Options.Saved[scope];
	if (scoped == nil) then
		return X4D_LibAntiSpam.Options.Default[name];
	end
	local value = scoped[name];
	if (value == nil) then
		value = X4D_LibAntiSpam.Options.Default[name];
	end
	return value;
end

local function SetOption(name, value)
	local scope = 'Account-Wide';
	if (X4D_LibAntiSpam.Options.Saved.SettingsAre and X4D_LibAntiSpam.Options.Saved.SettingsAre ~= 'Account-Wide') then
		scope = GetUnitName("player");
	end
	local scoped = X4D_LibAntiSpam.Options.Saved[scope];
	if (scoped == nil) then
		scoped = {};
		X4D_LibAntiSpam.Options.Saved[scope] = scoped;
	end
	scoped[name] = value;
end


X4D_LibAntiSpam.Colors = {
	X4D = '|cFFAE19',
	SystemChannel = '|cFFFF00',
};

X4D_LibAntiSpam.InternalPatterns = {
	[0] = 'h.?a.?n.?%a.?w.?o.?r.?k',
	[1] = 'i.?i.?i.?i.?i.?c.?o.?[mn]+',
	[2] = '%w?%w?%w?%w?%w?.?g.?[op].?[li].?d.?%w?%w?%w?%w?%w?%.?c.?[op].?[mn]+',
	[3] = 'p[vm]+p.?.?.?.?ba[vmn]+k.?.?.?.?[op][mn]+',
	[4] = 'p.?[vm]+.?p.?b.?a.?n.?k.*c.?[op].?[mn]+',
	[5] = 'o.?k.?a.?y.?g.?[co].?[co].?d.?s.?c.?[op].?[mn]+',
	[6] = 'e.?[zm].?o.?o.?[mn].?c.?[op].?[mn]+',
	[7] = 'g.?g.?a.?t.?[mn].?c.?[op].?[mn]+',
	[8] = '[mn].?[mn].?[op].?[wvm]+.?i.?n.?c.?[op].?[mn]+',
	[9] = 'g.?a.?e.?z.?c.?[op]?.?[mn]+',
	[10] = 'g.?a.?[mn].?e.?c.?b.?o.?c.?[op].?[mn]+',	
	[11] = 'w.?o.?w.?g.?[li].?c.?[op].?[mn]+',	
	[12] = 'g.?a.?[mn].?e.?[li].?[mn].?c.?[op].?[mn]+',
	[13] = 'u.?t.?[mn].?[mn].?o.?c.?[op].?[mn]+',
	[14] = 'g.?g.?a.?t.?[mn].?c.?[op].?[mn]+',
	[15] = 'g.?o.?l.?d[^e]?a[^c]?h',
	[16] = 's[ea][fl]eandfast',
	[17] = 'cheap.*g[op][li]d.*usd',	
	[18] = 'cheap.*fast.*sa[fl]e',
	[19] = '[li].?.?f.?.?d.?.?p.?.?s.?.?c.?.?[op].?.?[mn]+',
	[20] = 'g.?[op].?[li].?d.?c.?e.?[op].?.?.?c.?[op].?[mn]+',
	[21] = '[mn].?[mn].?[op].?[mn].?a.?r.?t.?c.?[op].?[mn]+',
	[22] = 'e.?g.?p.?a.?[li].?.c[op]*[mn]+',
	[23] = '[wvm]?.?t.?s.?i.?t.?e.?[mn].?c.?[op].?[mn]+',
	[24] = 'w.?t.?s.?m.?m.?o.?c.?o.?[mn]+',
};

X4D_LibAntiSpam.CharMap = {};

local L_charMap = {
	['À'] = 'A', ['Á'] = 'A', ['Â'] = 'A', ['Ã'] = 'A', ['Ä'] = 'A', ['Å'] = 'A', ['Æ'] = 'AE', 
	['Ç'] = 'C', ['È'] = 'E', ['É'] = 'E', ['Ê'] = 'E', ['Ë'] = 'E', ['Ì'] = 'I', ['Í'] = 'I', 
	['Î'] = 'I', ['Ï'] = 'I', ['Ð'] = 'D', ['Ñ'] = 'N', ['Ò'] = 'O', ['Ó'] = 'O', ['Ô'] = 'O', 
	['Õ'] = 'O', ['Ö'] = 'O', ['×'] = 'x', ['Ø'] = 'O', ['Ù'] = 'U', ['Ú'] = 'U', ['Û'] = 'U', 
	['Ü'] = 'U', ['Ý'] = 'Y', ['Þ'] = 'b', ['¥'] = 'Y', ['¢'] = 'c', ['¡'] = 'i', ['£'] = 'L', 
	['ß'] = 'B', ['à'] = 'a', ['á'] = 'a', ['â'] = 'a', ['ã'] = 'a', ['ä'] = 'a', ['å'] = 'a', 
	['ç'] = 'c', ['è'] = 'e', ['é'] = 'e', ['ê'] = 'e', ['ë'] = 'e', ['ì'] = 'i', ['æ'] = 'ae', 
	['í'] = 'i', ['î'] = 'i', ['ï'] = 'i', ['ð'] = 'o', ['ñ'] = 'n', ['ò'] = 'o', ['ó'] = 'o', 
	['ô'] = 'o', ['õ'] = 'o', ['ö'] = 'o', ['÷'] = 't', ['ø'] = 'o', ['ù'] = 'u', ['ú'] = 'u', 
	['û'] = 'u', ['ü'] = 'u', ['ý'] = 'y', ['þ'] = 'b', ['ÿ'] = 'y', ['®'] = 'r', ['@'] = 'o',
	['1'] = 'l', ['3'] = 'e', ['4'] = 'a', ['7'] = 'T', ['0'] = 'O', ['('] = 'c', ['2'] = 'R',
	[')'] = 'o', ['·'] = '.', ['°'] = '.', ['¸'] = '.', ['¯'] = '-', [','] = '.', ['*'] = '.',
	['$'] = 'S', ['/'] = 'm', ['¿'] = '?', ['5'] = 'S', ['9'] = 'g', ['\\'] = 'v', ['ß'] = 'b',
	['{'] = 'c', ['}'] = 'o', ['<'] = 'c', ['>'] = 'o', 
};

for inp,v in pairs(L_charMap) do
	local b1, b2, res = inp:byte(1, 2);
	if (b2) then
		X4D_LibAntiSpam.CharMap[string.format('%x%x', b1, b2)] = v;
	elseif (b1) then
		X4D_LibAntiSpam.CharMap[string.format('%x', b1)] = v;
	end
	X4D_LibAntiSpam.CharMap[inp] = v;
	d(X4D_LibAntiSpam.CharMap[inp] .. '=' .. v);
end

local function DefaultEmitCallback(color, text)
	d(color .. text);
end

X4D_LibAntiSpam.EmitCallback = DefaultEmitCallback;

function X4D_LibAntiSpam.RegisterEmitCallback(self, callback)
	if (callback ~= nil) then
		X4D_LibAntiSpam.EmitCallback = callback;
	else
		X4D_LibAntiSpam.EmitCallback = DefaultEmitCallback;
	end
end

function X4D_LibAntiSpam.UnregisterEmitCallback(self, callback)
	if (X4D_LibAntiSpam.EmitCallback == callback) then
		self:RegisterEmitCallback(nil);
	end
end

local function InvokeEmitCallbackSafe(color, text)
	local callback = X4D_LibAntiSpam.EmitCallback;
	if (color == nil) then
		color = '|cFF0000';
	end
	if (color:len() < 8) then
		d('bad color color=' .. color:gsub('|', '!'));
		color = '|cFF0000';
	end
	if (callback ~= nil) then	
		callback(color, text);
	end
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

local function StringEndsWith(s,v)
   return v=='' or string.sub(s,-string.len(v))==v
end

local function StringPivot(s, delimiter, sk)
	if (delimiter == nil) then
		delimiter = ' ';
	end
	if (sk == nil) then
		sk = 0;
	end
	local t = StringSplit(s, delimiter);
	local r = '';
	for j=1,1000 do
		local b = false;
		for _,l in pairs(t) do
			sk = sk - 1;
			if (sk <= 0) then
				if (l:len() > j) then
					b = true;
					r = r .. l:sub(j, j);
				end
			end
		end
		if (not b) then			
			break;
		end
	end
	return r;
end

local function IsSelf(fromName)
	return (fromName == GetUnitName('player'));
end

local function IsInGroup(fromName)
	return IsPlayerInGroup(fromName);
end

local function IsInFriends(fromName)
	return IsFriend(fromName);
end

local function IsInGuild(fromName)
	fromName = fromName:gsub('%^.*', '');
	for guildIndex = 1,GetNumGuilds() do
		local guildId = GetGuildId(guildIndex);
		if (guildId ~= nil) then
			for memberIndex = 1,GetNumGuildMembers(guildId) do
				local name, note, rankIndex, playerStatus, secsSinceLogoff = GetGuildMemberInfo(guildId, memberIndex)				
				if (name == fromName) then
					return true;
				end
				local hasCharacter, characterName, zoneName, classType, alliance, level, veteranRank = GetGuildMemberCharacterInfo(guildId, memberIndex)
				characterName = characterName:gsub('%^.*', '');
				if (characterName == fromName) then
					return true;
				end
			end
		end			
	end
	return false;
end

local function ShouldWhitelistPlayer(fromName)
	return IsSelf(fromName) or IsInGroup(fromName) or IsInFriends(fromName) or IsInGuild(fromName);
end

X4D_LibAntiSpam.Players = {};

local function GetPlayer(fromName)
	fromName = fromName:gsub('%^.*', '');
	return X4D_LibAntiSpam.Players[fromName];
end

local function AddPlayer(fromName)
	fromName = fromName:gsub('%^.*', '');
	X4D_LibAntiSpam.Players[fromName] = {
		Time = GetGameTimeMilliseconds(),
		From = fromName,
		IsWhitelist = ShouldWhitelistPlayer(fromName),
		IsSpam = false,
		IsFlood = false,
		TextTable = { },
		TextCount = 0,		
		TextLatest = '',
		GetTextAggregate = function(self)
			local r = '';
			for _,v in pairs(self.TextTable) do
				r = r .. ' ' .. v;
			end			
			return r .. StringPivot(r, ' ', 0);
		end,
		AddText = function(self, normalized)
			self.TextLatest = normalized;
			table.insert(self.TextTable, normalized);
			self.TextCount = self.TextCount + 1;
			if (self.TextCount > 5) then
				table.remove(self.TextTable, 1);
				self.TextCount = self.TextCount - 1;
			end
		end,
	};
	return GetPlayer(fromName);
end

local function GetEightyPercent(input)
	local len80 = input:len() * 0.8;
	if (len80 == 0) then
		return '';
	else
		return input:sub(1, len80);
	end
end

local function UpdateFloodState(player, normalized)
	if (player.IsWhitelist or (GetOption('FloodTime') == 0)) then
		player.IsFlood = false;
		return false;
	end
	if (normalized ~= nil and normalized:len() and GetEightyPercent(player.TextLatest) == GetEightyPercent(normalized)) then
		player.Time = GetGameTimeMilliseconds();
		if (not player.IsFlood) then
			player.IsFlood = true;
			if (GetOption('NotifyWhenDetected') and (not player.IsSpam)) then
				InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SystemChannel, '(LibAntiSpam) Detected Chat Flood from: |cFFAE19' .. player.From);
			end
			return true;
		end
	elseif (player.Time <= (GetGameTimeMilliseconds() - (GetOption('FloodTime') * 1000))) then
		player.IsFlood = false;
	end
	return false;
end

local function CheckPatterns(player, normalized, patterns)
	for i = 1, #patterns do
		if (player.IsSpam) then
			break;
		end
		if (not pcall(function() 
		if (normalized:find(patterns[i])) then
			player.Time = GetGameTimeMilliseconds();
			if (not player.IsSpam) then
				player.IsSpam = true;
				player.SpamMessage = normalized;
				player.SpamPattern = patterns[i];
			end
		end
		end)) then
			InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SystemChannel, '(LibAntiSpam) Bad Pattern: |cFF7777' .. patterns[i]);
		end
	end
end

local function UpdateSpamState(player, normalized)
	if (player.IsWhitelist) then
		player.IsSpam = false;
		return;
	end
	if (not player.IsSpam) then
		if (GetOption('UseInternalPatterns')) then
			CheckPatterns(player, normalized, X4D_LibAntiSpam.InternalPatterns);
		end		
		CheckPatterns(player, normalized, GetOption('Patterns'));
		return player.IsSpam; -- new spammer detected
	end
	return false; -- may or may not be a spammer, but definitely not a 'new' spammer
end

function X4D_LibAntiSpam.OnChatMessageReceived(messageType, fromName, text)
    local ChannelInfo = ZO_ChatSystem_GetChannelInfo()	
    local channelInfo = ChannelInfo[messageType]
	local isSpam, isFlood = X4D_LibAntiSpam:Check(text, fromName);
	if (isSpam or isFlood) then
		return;
	end
    if (channelInfo and channelInfo.format) then
		local channelLink = nil;
		if (channelInfo.channelLinkable) then
			local channelName = GetChannelName(channelInfo.id);
			channelLink = ZO_LinkHandler_CreateChannelLink(channelName);
		end
        local fromLink = fromName;
		if (channelInfo.playerLinkable) then
			fromLink = ZO_LinkHandler_CreatePlayerLink(fromName);
		end
        if (channelLink) then
			local channelName = nil;
            result = zo_strformat(channelInfo.format, channelLink, fromLink, text);
        else
			result = zo_strformat(channelInfo.format, fromLink, text);
		end
		return result, channelInfo.saveTarget;
    end	
end

local function FromCharMap(inp)
	local res = nil;
	if (inp) then
		local b1, b2 = inp:byte(1, 2);
		if (b2) then
			res = X4D_LibAntiSpam.CharMap[string.format('%x%x', b1, b2)];
		elseif (b1) then
			res = X4D_LibAntiSpam.CharMap[string.format('%x', b1)];
		end
	end
	if (not res) then
		res = X4D_LibAntiSpam.CharMap[inp];
	end		
	return res or inp; 
end
		
local function PreScrub(input, level)
	if (level == nil) then
		level = 3;
	end
	local output = input:upper();
	output = output:gsub('\\/\\/', 'W');
	output = output:gsub('\\/V', 'W');
	output = output:gsub('V\\/', 'W');
	output = output:gsub('/\\/\\', 'M');
	output = output:gsub('/V\\', 'M');	
	output = output:gsub('/N\\', 'M');	
	output = output:gsub('/\\/', 'N');
	output = output:gsub('/V', 'N');
	output = output:gsub('\\/V', 'W');
	output = output:gsub('\\/', 'V');
	output = output:gsub('[%|/l]V[%|\\l]', 'M');
	output = output:gsub('VV', 'w');
	output = output:gsub('VWVW', 'www');
	output = output:gsub('WVWV', 'www');
	output = output:gsub('[%(%{%%[][%)%}%]]', 'o');
	output = output:gsub('[%(%{%%[%)%}%]]+([^%(%{%%[%)%}%]])[%(%{%%[%)%}%]]+', '%1');

	if (level > 0) then		
		return PreScrub(output, level - 1);
	else
		return output;
	end
end

local function Strip(input)
	local output = input:gsub('%|', '!');
	output = output:gsub('!c%x%x%x%x%x%x', '');
	output = output:gsub('!r', '');
	output = output:gsub('!t[^!]*!t', '');
	output = output:gsub('!u[^!]*!u', '');
	output = output:gsub('!H[^!]*!h%[?([^%]!]*)%]?!h', '%[%1%]');
	output = output:gsub('[%[%]]*', '');
	return output;
end

local function ToASCII(input)
	local output = input;
	if (output ~= nil) then
		output = output:utf8replace(utf8_scrub1);
		output = output:utf8replace(utf8_scrub2);
		local stripped = '';
		local iA = 1;
		local iB = 1;
		while (iA <= output:len()) do
			local chA = output:sub(iA, iA);
			if (chA ~= nil) then
				local chB = output:utf8sub(iB, iB);
				if (chB ~= nil) then
					--local b1, b2 = chB:byte(1, 2);
					--local b3 = chA:byte(1)
					--if (b2) then
					--	d(chA .. chB .. ' ' .. string.format('%x %x%x', b3, b1, b2));
					--else
					--	d(chA .. chB .. ' ' .. string.format('%x %x', b3, b1));
					--end
					if (chA == chB) then
						stripped = stripped .. FromCharMap(chA);
						iA = iA + 1;
						iB = iB + 1;
					else
						iA = iA + chB:utf8charbytes()
						iB = iB + 1;						
					end
				else
					break;	
				end
			else
				break;
			end
		end
		output = stripped:lower();
	end
	return output;
end

local function PostScrub(input, level)
	if (level == nil) then
		level = 3;
	end
	local output = input:gsub('[%{%}%|%-~%s\1-\44\58-\63\91-\96\123-\255]', '');
	output = output:gsub('c+', 'c');
	output = output:gsub('o+', 'o');
	output = output:gsub('n+', 'n');
	output = output:gsub('coco', 'co');
	output = output:gsub('[%|/l]v[%|\\l]', 'm');
	if (level > 0) then
		return PostScrub(output, level - 1);
	else
		return output;
	end
end

local function Condense(input)
	local output = input:gsub('%.+', '.');
	while (output ~= input) do
		input = output;
		output = input:gsub('%.+', '.');
	end
	return output;
end

local function Normalize(input)
	local output = PreScrub(input);
	output = Strip(output);
	output = ToASCII(output);
	return Condense(PostScrub(output)), Condense(PostScrub(StringPivot(output)));
end

function X4D_LibAntiSpam.Check(self, text, fromName)
	local normalized, pivot = Normalize(text);
	local player = GetPlayer(fromName);
	if (not player) then
		player = AddPlayer(fromName);
		player:AddText(normalized);
	else
		local wasFlood = player.IsFlood;
		if (UpdateFloodState(player, normalized) and (not wasFlood)) then
			if (GetOption('ShowNormalizations')) then
				InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SystemChannel, '(LibAntiSpam) |c993333' .. normalized .. ' |cFFFF00 ' .. (fromName or '') .. '|c5C5C5C (v' .. X4D_LibAntiSpam.VERSION .. ')');
			end	
		end
		player:AddText(normalized);
		normalized = player:GetTextAggregate();
	end
	normalized = normalized .. pivot;
	if (UpdateSpamState(player, normalized)) then
		if (GetOption('NotifyWhenDetected')) then
			local fromLink = ZO_LinkHandler_CreatePlayerLink(fromName);
			if (GetOption('ShowNormalizations')) then
				local highlighted = normalized:gsub('(' .. player.SpamPattern .. ')', X4D_LibAntiSpam.Colors.X4D .. '%1' .. '|c993333');
				InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SystemChannel, '(LibAntiSpam) |c993333' .. highlighted .. ' |cFFFF00 ' .. (fromName or '') .. '|c5C5C5C (v' .. X4D_LibAntiSpam.VERSION .. ')');
			end	
			InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SystemChannel, '(LibAntiSpam) Detected Chat Spam from |cFFAE19' .. (fromLink or fromName or '') .. '|c5C5C5C [' .. player.SpamPattern .. ']');
		end	
	else
		if (GetOption('ShowNormalizations') and not (player.IsSpam or player.IsFlood)) then
			InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SystemChannel, '(LibAntiSpam) |c993333' .. normalized .. ' |cFFFF00 ' .. (fromName or '') .. '|c5C5C5C (v' .. X4D_LibAntiSpam.VERSION .. ')');
		end	
	end
	return player.IsSpam, player.IsFlood;
end	

local function RejectSpammerGuildInvites()
	for i=1,GetNumGuildInvites() do
		local guildId, guildName, guildAlliance, fromName, note = GetGuildInviteInfo(i);		
		if (guildId and guildId ~= 0) then
			local L_note = nil;
			local text = guildName;
			L_note = GetGuildDescription(guildId);
			if (L_note) then
				text = text .. L_note;
			end	
			L_note = GetGuildMotD(guildId);
			if (L_note) then
				text = text .. L_note;
			end
			local isSpam, isFlood = X4D_LibAntiSpam:Check(text, fromName);
			if (isSpam or isFlood) then
				if (GetOption('NotifyWhenDetected')) then
					local fromLink = ZO_LinkHandler_CreatePlayerLink(fromName);
					InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SystemChannel, '(LibAntiSpam) Detected Invite Spam from |cFFAE19' .. (fromLink or fromName));
				end
				RejectGuildInvite(guildId);
				zo_callLater(RejectSpammerGuildInvites, 1000);
				return;
			end
		end
	end
end

_G['X4D_spamCheck'] = function(text)
	local las = LibStub('LibAntiSpam');
	if (las) then
		las:Check(text, '@test' .. tostring(GetGameTimeMilliseconds()));
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

local function SetPatternsEditBoxText()
	local patterns = table.concat(GetOption('Patterns'), '\n');
	SetEditBoxValue('X4D_LIBANTISPAM_EDIT_PATTERNS', patterns, 8192);
	return patterns;
end

function X4D_LibAntiSpam.OnAddOnLoaded(event, addonName)
	if (addonName ~= X4D_LibAntiSpam.NAME) then
		return;
	end

	X4D_LibAntiSpam.Options.Saved = ZO_SavedVars:NewAccountWide(X4D_LibAntiSpam.NAME .. '_SV', 1.45, nil, {});

	local LAM = LibStub('LibAddonMenu-1.0');
	local cplId = LAM:CreateControlPanel('X4D_LibAntiSpam_CPL', 'X4D |cFFAE19AntiSpam');	
	LAM:AddHeader(cplId, 
		'X4D_LIBANTISPAM_HEADER_SETTINGS', 'Settings');

	LAM:AddCheckbox(cplId, 
		'X4D_LIBANTISPAM_CHECK_NOTIFY_DETECTED', 'Notify when detected Spam?', 
		'When enabled, Names are logged to the chat frame when spam is detected.', 
		function() return GetOption('NotifyWhenDetected') end,
		function() SetOption('NotifyWhenDetected', not GetOption('NotifyWhenDetected')) end);

	LAM:AddSlider(cplId,
		'X4D_LIBANTISPAM_SLIDER_FLOODTIME', 'Max Flood Time',
		'This determines mininum amount of time, in seconds, before repeated text is not considered Flooding. Flooding is when a user types the same thing into chat over and over.',
		0, 900, 30,
		function () return GetOption('FloodTime') end,
		function (v) SetOption('FloodTime', tonumber(tostring(v))) end);

	LAM:AddEditBox(cplId, 
		'X4D_LIBANTISPAM_EDIT_PATTERNS', 'User Patterns', 
		'Line-delimited list of Spammer Patterns, each one should be on a new line.', 
		true,
		SetPatternsEditBoxText,
		function()
			local v = _G['X4D_LIBANTISPAM_EDIT_PATTERNS']['edit']:GetText();
			local result = StringSplit(v, '\n');
			-- NOTE: this is a hack to deal with the fact that the LUA parser in ESO bugs out processing escaped strings in SavedVars :(
			for _,x in pairs(result) do
				if (StringEndsWith(x, ']')) then
					result[_] = x .. '+';
				end
			end
			SetOption('Patterns', result);
		end);
	SetPatternsEditBoxText();

	LAM:AddCheckbox(cplId, 
		'X4D_LIBANTISPAM_CHECK_USEINTERNAL', 'Use Internal Patterns?', 
		'When enabled, an internal set of patterns are used (in addition to any "User Patterns" you define.)', 
		function() return GetOption('UseInternalPatterns') end,
		function() SetOption('UseInternalPatterns', not GetOption('UseInternalPatterns')) end);

	LAM:AddCheckbox(cplId, 
		'X4D_LIBANTISPAM_CHECK_SHOW_NORMALIZATIONS', '[DEV] Show normalized text.', 
		'When enabled, all normalized text is dumped to the chat frame to aid in creating new patterns.', 
		function() return GetOption('ShowNormalizations') end,
		function() SetOption('ShowNormalizations', not GetOption('ShowNormalizations')) end);
		
	ZO_PreHook("ZO_OptionsWindow_ChangePanels", function(panel)
			if (panel == cplId) then				
				ZO_OptionsWindowResetToDefaultButton:SetCallback(function ()
					if (ZO_OptionsWindowResetToDefaultButton:GetParent()['currentPanel'] == cplId) then

						SetCheckboxValue('X4D_LIBANTISPAM_CHECK_NOTIFY_DETECTED', X4D_LibAntiSpam.Options.Default.NotifyWhenDetected);
						SetOption('NotifyWhenDetected', X4D_LibAntiSpam.Options.Default.NotifyWhenDetected);
						
						SetSliderValue('X4D_LIBANTISPAM_SLIDER_FLOODTIME', X4D_LibAntiSpam.Options.Default.FloodTime, 0, 900);
						SetOption('FloodTime', X4D_LibAntiSpam.Options.Default.FloodTime);
																		
						SetEditBoxValue('X4D_LIBANTISPAM_EDIT_PATTERNS', '', 8192);
						SetOption('Patterns', '');

						SetCheckboxValue('X4D_LIBANTISPAM_CHECK_USEINTERNAL', X4D_LibAntiSpam.Options.Default.UseInternalPatterns);
						SetOption('UseInternalPatterns', X4D_LibAntiSpam.Options.Default.UseInternalPatterns);

						SetCheckboxValue('X4D_LIBANTISPAM_CHECK_SHOW_NORMALIZATIONS', X4D_LibAntiSpam.Options.Default.ShowNormalizations);						
						SetOption('ShowNormalizations', X4D_LibAntiSpam.Options.Default.ShowNormalizations);
					end
				end);
			end
		end);		

	X4D_LibAntiSpam.Register();
end

function X4D_LibAntiSpam.OnGuildInviteAdded(id1, id2, guildName, id4, fromName)
	zo_callLater(RejectSpammerGuildInvites, 1000);
end

function X4D_LibAntiSpam.Register()
	ZO_ChatSystem_AddEventHandler(EVENT_CHAT_MESSAGE_CHANNEL, X4D_LibAntiSpam.OnChatMessageReceived);
end

function X4D_LibAntiSpam.Unregister()
	ZO_ChatSystem_AddEventHandler(EVENT_CHAT_MESSAGE_CHANNEL, nil);
end

local function DEC2HEX(input)
	local h = (input / 16);
	local l = (input - (h * 16));
	return string.format('%x%x', h, l);
end

function X4D_LibAntiSpam.CreateColorCode(r, g, b)
	return '|c' .. DEC2HEX(r * 255) .. DEC2HEX(g * 255) .. DEC2HEX(b * 255);
end

local _initialized = false;

function X4D_LibAntiSpam.OnPlayerActivated()
	zo_callLater(function() 
		RejectSpammerGuildInvites();
	end, 3000);

	if (not _initialized) then
		_initialized = true;
		local r, g, b = GetChatCategoryColor(CHAT_CATEGORY_SYSTEM);
		if (r ~= nil) then
			X4D_LibAntiSpam.Colors.SystemChannel = X4D_LibAntiSpam.CreateColorCode(r, g, b);
		end
	end
end

EVENT_MANAGER:RegisterForEvent(X4D_LibAntiSpam.NAME, EVENT_ADD_ON_LOADED, X4D_LibAntiSpam.OnAddOnLoaded);
EVENT_MANAGER:RegisterForEvent(X4D_LibAntiSpam.NAME, EVENT_GUILD_INVITE_ADDED, X4D_LibAntiSpam.OnGuildInviteAdded);
EVENT_MANAGER:RegisterForEvent(X4D_LibAntiSpam.NAME, EVENT_PLAYER_ACTIVATED, X4D_LibAntiSpam.OnPlayerActivated);

