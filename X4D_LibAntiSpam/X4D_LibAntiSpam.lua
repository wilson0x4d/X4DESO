----
-- LibAntiSpam 1.0
----
-- Spam/Flood library you can use from other addons, or stand-alone.
--
local X4D_LibAntiSpam = LibStub:NewLibrary("LibAntiSpam", 1061)
if (not X4D_LibAntiSpam) then
	return
end
local X4D = LibStub("X4D")
X4D.AntiSpam = X4D_LibAntiSpam

X4D_LibAntiSpam.NAME = "X4D_LibAntiSpam"
X4D_LibAntiSpam.VERSION = "1.61"

X4D_LibAntiSpam.Colors = {
	X4D = "|cFFAE19",
	SYSTEM = "|cFFFF00",
}

-- these patterns were derived from spam text discovered in-game, while this isn't so much a problem anymore the functionality is being retained
-- usually these patterns target a domain name or portion thereof which is unique to a gold/powerlevel spammer
X4D_LibAntiSpam.InternalPatterns = {
	"h.?a.?n.?%a.?w.?o.?r.?k",
	"cheap.*g[op][li]d.*usd",
	"%w?%w?%w?%w?%w?.?g.?[op].?[li].?d.?%w?%w?%w?%w?%w?%.?c.?[op][^i]?[mn]+",
	"p[vm]+p.?.?.?.?ba[vmn]+k.?.?.?.?[op][mn]+",
	"p.?[vm]+.?p.?b.?a.?n.?k.*c.?[op].?[mn]+",
	"o.?k.?a.?y.?g.?[co].?[co].?d.?s.?c.?[op].?[mn]+",
	"e.?[zm].?o.?o.?[mn].?c.?[op].?[mn]+",
	"g.?g.?a.?t.?[mn].?c.?[op].?[mn]+",
	"[mn].?[mn].?[op].?[wvm]+.?i.?n.?c.?[op].?[mn]+",
	"g.?a.?e.?z.?c.?[op]?.?[mn]+",
	"w.?o.?w.?g.?[li].?c.?[op].?[mn]+",
	"g.?a.?[mn].?e.?[li].?[mn].?c.?[op].?[mn]+",
	"u.?t.?[mn].?[mn].?o.?c.?[op].?[mn]+",
	"g.?g.?a.?t.?[mn].?c.?[op].?[mn]+",
	"g.?o.?l.?d[^e]?a[^c]?h",
	"[li].?.?f.?.?d.?.?p.?.?s.?.?c.?.?[op].?.?[mn]+",
	"g.?[op].?[li].?d.?c.?e.?[op].?.?.?c.?[op].?[mn]+",
	"[mn].?[mn].?[op].?[mn].?a.?r.?t.?c.?[op].?[mn]+",
	"[wvm]?.?t.?s.?i.?t.?e.?[mn].?c.?[op].?[mn]+",
	"v.?g.?[op].?l.?d.?s.?c.?[op].?[mn]+",
	"m.?m.?o.?a.?a.?c.?[op].?[mn]+",
}

-- these are patterns which have been found to catch non-spammers at least once (often times only once) but this, at one time, was more preferable to the wall-of-spam experienced at launch
-- these are broken out into a secondary option for those who don't care if random players get caught in a spam filter if the filter has a 99.999% chance of blocking spammers
-- often times these were formed based on analysis of ASCII ART being used by gold sellers, or unique sales phrases like "cheap and safe"
X4D_LibAntiSpam.AggressivePatterns = {
	"i.?i.?i.?i.?i.?c.?o.?[mn]+",
	"www.?g.?[li].?w.?o.?w",
	"ww.*wo.*wc.*go",
	"e.?g.?p.?a.?[li].?.c[op]*[mn]+",
	"g[^a]?a[^m]*m[^e]*e[^i]*i[^m]*m[^c]*c[^o]*o[^m]*m",
	"w.?t.?s.?m.?m.?o.?c.?[op].?[mn]+",
	--"wtsmmo",
	"s[ea][fl]e.*fast",
	"fast.*s[ea][fl]e",
	"g.?a.?[mn].?e.?c.?b.?o.?c.?[op].?[mn]+",
}

X4D_LibAntiSpam.CharMap = {}

local L_charMap = {
	["À"] = "A", ["Á"] = "A", ["Â"] = "A", ["Ã"] = "A", ["Ä"] = "A", ["Å"] = "A", ["Æ"] = "AE", 
	["Ç"] = "C", ["È"] = "E", ["É"] = "E", ["Ê"] = "E", ["Ë"] = "E", ["Ì"] = "I", ["Í"] = "I", 
	["Î"] = "I", ["Ï"] = "I", ["Ð"] = "D", ["Ñ"] = "N", ["Ò"] = "O", ["Ó"] = "O", ["Ô"] = "O", 
	["Õ"] = "O", ["Ö"] = "O", ["×"] = "x", ["Ø"] = "O", ["Ù"] = "U", ["Ú"] = "U", ["Û"] = "U", 
	["Ü"] = "U", ["Ý"] = "Y", ["Þ"] = "b", ["¥"] = "Y", ["¢"] = "c", ["¡"] = "i", ["£"] = "L", 
	["ß"] = "B", ["à"] = "a", ["á"] = "a", ["â"] = "a", ["ã"] = "a", ["ä"] = "a", ["å"] = "a", 
	["ç"] = "c", ["è"] = "e", ["é"] = "e", ["ê"] = "e", ["ë"] = "e", ["ì"] = "i", ["æ"] = "ae", 
	["í"] = "i", ["î"] = "i", ["ï"] = "i", ["ð"] = "o", ["ñ"] = "n", ["ò"] = "o", ["ó"] = "o", 
	["ô"] = "o", ["õ"] = "o", ["ö"] = "o", ["÷"] = "t", ["ø"] = "o", ["ù"] = "u", ["ú"] = "u", 
	["û"] = "u", ["ü"] = "u", ["ý"] = "y", ["þ"] = "b", ["ÿ"] = "y", ["®"] = "r", ["@"] = "o",
	["1"] = "l", ["3"] = "e", ["4"] = "a", ["7"] = "T", ["0"] = "O", ["("] = "c", ["2"] = "R",
	[")"] = "o", ["·"] = "", ["°"] = "", ["¸"] = "", ["¯"] = "-", [","] = "", ["*"] = "",
	["$"] = "S", ["/"] = "m", ["¿"] = "?", ["5"] = "S", ["9"] = "g", ["\\"] = "v", ["ß"] = "b",
	["{"] = "c", ["}"] = "o", ["<"] = "c", [">"] = "o", 
	["c2a4"] = "o",
}

for inp,v in pairs(L_charMap) do
	local b1, b2, b3, res = inp:byte(1, 3)
	if (b3) then
		X4D_LibAntiSpam.CharMap[string.format("%x%x%x", b1, b2, b3)] = v
	elseif (b2) then
		X4D_LibAntiSpam.CharMap[string.format("%x%x", b1, b2)] = v
	elseif (b1) then
		X4D_LibAntiSpam.CharMap[string.format("%x", b1)] = v
	end
	X4D_LibAntiSpam.CharMap[inp] = v
	d(X4D_LibAntiSpam.CharMap[inp] .. "=" .. v)
end

local function DefaultEmitCallback(color, text)
	d(color .. text)
end

X4D_LibAntiSpam.EmitCallback = DefaultEmitCallback

function X4D_LibAntiSpam.RegisterEmitCallback(self, callback)
	if (callback ~= nil) then
		X4D_LibAntiSpam.EmitCallback = callback
	else
		X4D_LibAntiSpam.EmitCallback = DefaultEmitCallback
	end
end

function X4D_LibAntiSpam.UnregisterEmitCallback(self, callback)
	if (X4D_LibAntiSpam.EmitCallback == callback) then
		self:RegisterEmitCallback(nil)
	end
end

local function InvokeEmitCallbackSafe(color, text)
	local callback = X4D_LibAntiSpam.EmitCallback
	if (color == nil) then
		color = "|cFF0000"
	end
	if (color:len() < 8) then
		d("bad color color=" .. color:gsub("|", "!"))
		color = "|cFF0000"
	end
	if (callback ~= nil) then	
		callback(color, text)
	end
end

local function StringPivot(s, delimiter, sk)
	if (delimiter == nil) then
		delimiter = " "
	end
	if (sk == nil) then
		sk = 0
	end
	local t = s:Split(delimiter)
	local r = ""
	for j=1,1000 do
		local b = false
		for _,l in pairs(t) do
			sk = sk - 1
			if (sk <= 0) then
				if (l:len() > j) then
					b = true
					r = r .. l:sub(j, j)
				end
			end
		end
		if (not b) then			
			break
		end
	end
	return r
end

X4D_LibAntiSpam.TransientPlayerState = X4D.DB:Create() -- for storing player-specific settings that do not need to be persisted. such as normalized strings, we use this database

local function GetPlayerState(tag)
    local player = X4D.Players:GetPlayer(tag)
    local playerState = X4D_LibAntiSpam.TransientPlayerState:Find(player)
    if (playerState == nil) then
        playerState = {
            Key = player, -- use 'persistent' player object (runtime reference) as a Key
            Player = player, -- a formal reference to the associated player object, use this instead of 'Key' if you need access to X4D's Player object
            --region 
		    Time = player.LastSeen,
		    From = player.Name,
		    IsWhitelist = player.IsWhitelisted,
		    IsFlood = player.IsFlooder,
            FloodCount = 0,
            --endregion
		    TextTable = { },
		    TextCount = 0,		
		    LastMessage = "",
		    GetTextAggregate = function(self)
			    local r = ""
			    for _,v in pairs(self.TextTable) do
				    r = r .. " " .. v
			    end			
			    return r .. StringPivot(r, " ", 0)
		    end,
		    AddText = function(self, normalized)
			    self.LastMessage = normalized
			    table.insert(self.TextTable, normalized)
			    self.TextCount = self.TextCount + 1
			    if (self.TextCount > 5) then
				    table.remove(self.TextTable, 1)
				    self.TextCount = self.TextCount - 1
			    end
		    end,
	    }
        X4D_LibAntiSpam.TransientPlayerState:Add(playerState)
    end
	return playerState
end

local function GetEightyPercent(input)
	local len80 = math.ceil(input:len() * 0.8)
	if (len80 == 0) then
		return ""
	else
		return input:sub(1, len80)
	end
end

local function UpdateFloodState(playerState, normalized, reason)
	if (playerState.Player.IsWhitelisted or (X4D.AntiSpam.Settings:Get("FloodTimeSeconds") == 0)) then
		playerState.Player.IsFlooder = false
		return false
	end
	if (normalized ~= nil and normalized:len() and GetEightyPercent(playerState.LastMessage) == GetEightyPercent(normalized)) then
		playerState.Time = GetGameTimeMilliseconds()
		if (not playerState.Player.IsFlooder) then
			playerState.Player.IsFlooder = true
            playerState.FloodCount = 1
			if (X4D.AntiSpam.Settings:Get("NotifyWhenDetected") and (not playerState.Player.IsSpammer)) then
				InvokeEmitCallbackSafe(X4D.Colors.SYSTEM, "(LibAntiSpam) Detected " .. reason .. " Flood from: |cFFAE19" .. playerState.Player.Name)
			end
			return true
		end
	elseif (playerState.Time <= (GetGameTimeMilliseconds() - (X4D.AntiSpam.Settings:Get("FloodTimeSeconds") * 1000))) then
		playerState.Player.IsFlooder = false
        playerState.FloodCount = 0
	end
    if (playerState.IsFlood) then
        playerState.FloodCount = playerState.FloodCount + 1
    end
	return false
end

local function CheckPatterns(playerState, normalized, patterns)
	for i = 1, #patterns do
		if (playerState.Player.IsSpammer) then
			break
		end
		if (not pcall(function() 
		if (normalized:find(patterns[i])) then
			playerState.Time = GetGameTimeMilliseconds()
			if (not playerState.Player.IsSpammer) then
				playerState.Player.IsSpammer = true                
				--OOM: player.SpamMessage = normalized
				playerState.SpamPattern = patterns[i]
			end
		end
		end)) then
			InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SYSTEM, "(LibAntiSpam) Bad Pattern: |cFF7777" .. patterns[i])
		end
	end
end

local function UpdateSpamState(playerState, normalized)
	if (playerState.Player.IsWhitelisted) then
		playerState.Player.IsSpammer = false
		return
	end
	if (not playerState.Player.IsSpammer) then
		if (X4D.AntiSpam.Settings:Get("UseInternalPatterns")) then
			CheckPatterns(playerState, normalized, X4D_LibAntiSpam.InternalPatterns)
		    if (X4D.AntiSpam.Settings:Get("UseAggressivePatterns")) then
			    CheckPatterns(playerState, normalized, X4D_LibAntiSpam.AggressivePatterns)
		    end		
		end		
		CheckPatterns(playerState, normalized, X4D.AntiSpam.Settings:Get("Patterns"))
		return playerState.Player.IsSpammer -- if true, "new" spammer was detected
	end
	return false -- may or may not be a spammer, but definitely not a "new" spammer
end

function X4D_LibAntiSpam.OnChatMessageReceived(messageType, fromName, text)
    local ChannelInfo = ZO_ChatSystem_GetChannelInfo()	
    local channelInfo = ChannelInfo[messageType]
	local isSpam, isFlood, pattern, floodCount = X4D_LibAntiSpam:Check(text, fromName)
	if (isSpam or isFlood) then
		return
	end
    if (channelInfo and channelInfo.format) then
		local channelLink = nil
		if (channelInfo.channelLinkable) then
			local channelName = GetChannelName(channelInfo.id)
			channelLink = ZO_LinkHandler_CreateChannelLink(channelName)
		end
        local fromLink = fromName
		if (channelInfo.playerLinkable) then
			fromLink = ZO_LinkHandler_CreatePlayerLink(fromName)
		end
        if (channelLink) then
			local channelName = nil
            result = zo_strformat(channelInfo.format, channelLink, fromLink, text)
        else
			result = zo_strformat(channelInfo.format, fromLink, text)
		end
		return result, channelInfo.saveTarget
    end	
end

local function FromCharMap(inp)
	local res = X4D_LibAntiSpam.CharMap[inp]
	if (inp and (not res)) then
		local b1, b2, b3 = inp:byte(1, 3)
		if (b3) then
			res = X4D_LibAntiSpam.CharMap[string.format("%x%x%x", b1, b2, b3)]
		elseif (b2) then
			res = X4D_LibAntiSpam.CharMap[string.format("%x%x", b1, b2)]
		elseif (b1) then
			res = X4D_LibAntiSpam.CharMap[string.format("%x", b1)]
		end
		return res or inp, b1, b2, b3
	else
		return res or inp
	end
end
		
local function PreScrub(input, depth)
	if (depth == nil) then
		depth = 3
	end

	local output = input:gsub("%|c%x%x%x%x%x%x", "")
	output = output:gsub("%|r", "")
	output = output:gsub("%|t[^%|]*%|t", "")
	output = output:gsub("%|u[^%|]*%|u", "")
	output = output:gsub("%|H[^%|]*%|h%[?([^%]%|]*)%]?%|h", "%[%1%]")
	output = output:upper()
	output = output:gsub("/%-\\", "A")
	output = output:gsub("\\.?/\\.?/", "W")
	output = output:gsub("\\/V", "W")
	output = output:gsub("V\\/", "W")
	output = output:gsub("/\\/\\", "M")
	output = output:gsub("/%^+\\", "M")	
	output = output:gsub("/V\\", "M")	
	output = output:gsub("/N\\", "M")	
	output = output:gsub("/\\/", "N")
	output = output:gsub("/V", "N")
	output = output:gsub("\\/V", "W")
	output = output:gsub("\\/", "V")
	output = output:gsub("\\/", "V")
	output = output:gsub("[%|/l]V[%|\\l]", "M")
	output = output:gsub("[%|/l]%-[%|\\l]", "H")
	output = output:gsub("[%|/l]_[%|\\l]", "U")
	output = output:gsub("[%|\\/l]_[%|\\/l][%|\\/l]?_[%|\\/l]", "W")
	output = output:gsub("VV", "W")
	output = output:gsub("VWVW", "WWW")
	output = output:gsub("WVWV", "WWW")
	output = output:gsub("%.", "")
	output = output:gsub("[%(%{%%[][%)%}%]]", "O")
	local endcaps = "%<%(%{%%[%)%}%]%>%-%*%^%|%=%+%_\\/%&%%%$%#%@%!"
	output = output:gsub("[" .. endcaps .."]+([^" .. endcaps .."])[" .. endcaps .."]+", "%1")
	output = output:gsub("[" .. endcaps .."]+%s+([^" .. endcaps .."])%s+[" .. endcaps .. "]+", "%1")
	output = output:gsub("([" .. endcaps .."])", FromCharMap)
	output = output:gsub("[" .. endcaps .."]+", "")

	if (depth > 0 and input ~= output) then		
		return PreScrub(output, depth - 1)
	else
		return output
	end
end

local function ToASCII(input, fromName)
	local output = input
	local ustrips = ""
	if (output ~= nil) then
		output = output:utf8replace(utf8_scrub1)
		output = output:utf8replace(utf8_scrub2)
		local stripped = ""
		local iA = 1
		local iB = 1
		while (iA <= output:len()) do
			local chA = output:sub(iA, iA)
			if (chA ~= nil) then
				local chB = output:utf8sub(iB, iB)
				if (chB ~= nil) then
					if (chA == chB) then
						stripped = stripped .. FromCharMap(chA)
						iA = iA + 1
						iB = iB + 1
					else
						local chC, x1, x2, x3 = FromCharMap(chB)
						if (chB ~= chC) then
							stripped = stripped .. FromCharMap(chC)
						else
							if (X4D.AntiSpam.Settings:Get("ShowNormalizations")) then
								if (x3) then
									ustrips = ustrips .. string.format(" %s+%x+%x+%x", chB, x1, x2, x3)
								elseif (x2) then
									ustrips = ustrips .. string.format(" %s+%x+%x", chB, x1, x2)
								else
									ustrips = ustrips .. string.format(" %s+%x", chB, x1)
								end
							end
						end
						iA = iA + chB:utf8charbytes()
						iB = iB + 1						
					end
				else
					break	
				end
			else
				break
			end
		end
		output = stripped:lower()
	end
	if (X4D.AntiSpam.Settings:Get("ShowNormalizations") and ustrips:len() > 0) then
		InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SYSTEM, "(LibAntiSpam) |c993333" .. ustrips .. " |cFFFF00 " .. (fromName or "") .. "|c5C5C5C (v" .. X4D_LibAntiSpam.VERSION .. ")")
	end
	return output
end

local function PostScrub(input, level)
	if (level == nil) then
		level = 3
	end
	local output = input:gsub("[%|%-~%s\1-\44\58-\63\91-\96\123-\255]", "")
	output = output:gsub("c+", "c")
	output = output:gsub("o+", "o")
	output = output:gsub("n+", "n")
	output = output:gsub("coco", "co")
	output = output:gsub("[%|/l]v[%|\\l]", "m")

	if (level > 0 and input ~= output) then
		return PostScrub(output, level - 1)
	else
		return output
	end
end

local function Condense(input)
	--local output = input:gsub("%.+", ".")
	--while (output ~= input) do
	--	input = output
	--	output = input:gsub("%.+", ".")
	--end
	return input:gsub("%.+", "")
end

local function Normalize(input, fromName)
	local output = PreScrub(input)
	output = ToASCII(output, fromName)
	return Condense(PostScrub(output)), Condense(PostScrub(StringPivot(output)))
end

--[[
	first param can be a table with the following elements, example
	
    local isSpam, isFlood = X4D_LibAntiSpam:Check({
			Text: "Hello, World!", -- required param
			Name: senderDisplayName, -- required param
			Reason: "Chat", -- optional
			NoFlood: false, -- optional
			NoSpam: false, -- optional
		})

    returns:
        isSpam: when true, means text matched one or more spam patterns
        isFlood: when true, means sender has sent the same message more than once within 'FloodTimeSeconds', isFlood will continue to return true until different message text is sent, or 'FloodTimeSeconds' has elapsed
        pattern: if isSpam is true, this will be the spam pattern matched, otherwise nil
        floodCount: if isFlood is true, this will be the number of flood messages messages received

]]
function X4D_LibAntiSpam:Check(text, fromName, reason)
	local noFlood = false
	local noSpam = false
	if (type(text) == "table") then
		reason = text.Reason or reason
		fromName = text.Name or fromName
		noFlood = text.NoFlood or false
		noSpam = text.NoSpam or false
		text = text.Text
	end
	if (reason == nil) then
		reason = "Chat" -- Guild Invite, Mail, etc, this is the text displayed to users later
	end
	local normalized, pivot = Normalize(text, fromName)
	local playerState = GetPlayerState(fromName)

	if (not noFlood) then
		local p2 = playerState.Player
        local wasFlood = p2.IsFlooder
		if (UpdateFloodState(playerState, normalized, reason) and not (wasFlood or playerState.Player.IsSpammer)) then
			if (X4D.AntiSpam.Settings:Get("ShowNormalizations")) then
				InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SYSTEM, "(LibAntiSpam) |c993333" .. normalized .. " |cFFFF00 " .. (fromName or "") .. "|c5C5C5C (v" .. X4D_LibAntiSpam.VERSION .. ")")
			end	
		end
	end
	playerState:AddText(normalized)
	normalized = playerState:GetTextAggregate()

	if (not noSpam) then		
		normalized = normalized .. pivot
		if (UpdateSpamState(playerState, normalized)) then
			if (X4D.AntiSpam.Settings:Get("NotifyWhenDetected")) then
				local fromLink = ZO_LinkHandler_CreatePlayerLink(fromName)
				if (X4D.AntiSpam.Settings:Get("ShowNormalizations")) then
					local highlighted = normalized:gsub("(" .. playerState.SpamPattern .. ")", X4D_LibAntiSpam.Colors.X4D .. "%1" .. "|c993333")
					InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SYSTEM, "(LibAntiSpam) |c993333" .. highlighted .. " |cFFFF00 " .. (fromName or "") .. "|c5C5C5C (v" .. X4D_LibAntiSpam.VERSION .. ")")
				end	
				InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SYSTEM, "(LibAntiSpam) Detected " .. reason .. " Spam from |cFFAE19" .. (fromLink or fromName or "") .. "|c5C5C5C [" .. playerState.SpamPattern .. "]")
			end	
		else
			if (X4D.AntiSpam.Settings:Get("ShowNormalizations") and not (playerState.Player.IsSpammer or playerState.Player.IsFlooder)) then
				InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SYSTEM, "(LibAntiSpam) |c993333" .. normalized .. " |cFFFF00 " .. (fromName or "") .. "|c5C5C5C (v" .. X4D_LibAntiSpam.VERSION .. ")")
			end	
		end
	end
	return playerState.Player.IsSpammer, playerState.Player.IsFlooder, playerState.Player.IsSpammer and playerState.SpamPattern, playerState.Player.IsFlooder and playerState.FloodCount
end	

local function RejectSpammerGuildInvites()    
	for i=1,GetNumGuildInvites() do
		local guildId, guildName, guildAlliance, fromName, note = GetGuildInviteInfo(i)		
		if (guildId and guildId ~= 0) then
			local L_note = nil
			local text = guildName
			L_note = GetGuildDescription(guildId)
			if (L_note) then
				text = text .. L_note
			end	
			L_note = GetGuildMotD(guildId)
			if (L_note) then
				text = text .. L_note
			end
			local isSpam, isFlood = X4D_LibAntiSpam:Check(text, fromName)
			if (isSpam or isFlood) then
				if (X4D.AntiSpam.Settings:Get("NotifyWhenDetected")) then
					local fromLink = ZO_LinkHandler_CreatePlayerLink(fromName)
					InvokeEmitCallbackSafe(X4D_LibAntiSpam.Colors.SYSTEM, "(LibAntiSpam) Detected Spammer Invite from |cFFAE19" .. (fromLink or fromName))
				end
				RejectGuildInvite(guildId)
				zo_callLater(RejectSpammerGuildInvites, 1000)
				return
			end
		end
	end
end

_G["X4D_spamCheck"] = function(text)
	local las = LibStub("LibAntiSpam")
	if (las) then
		las:Check(text, "@test" .. tostring(GetGameTimeMilliseconds()))
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

local function SetEditBoxValue(controlName, value, maxInputChars)
	if (maxInputChars and maxInputChars > 0) then
		_G[controlName]["edit"]:SetMaxInputChars(maxInputChars)
	end
	_G[controlName]["edit"]:SetText(value)
end

function X4D_LibAntiSpam.OnAddOnLoaded(event, addonName)
	if (addonName ~= X4D_LibAntiSpam.NAME) then
		return
	end

    X4D_LibAntiSpam.Settings = X4D.Settings(
        X4D_LibAntiSpam.NAME .. "_SV",
        {
	        NotifyWhenDetected = false,
	        UseInternalPatterns = true,
	        UseAggressivePatterns = false,
	        FloodTimeSeconds = 300,
	        ShowNormalizations = false,
	        Patterns = {},
        },
        2)

	local LAM = LibStub("LibAddonMenu-2.0")
	local cplId = LAM:RegisterAddonPanel(
        "X4D_LibAntiSpam_CPL", 
        {
            type = "panel",
            name = "X4D |cFFAE19AntiSpam",        
        })	
    
    LAM:RegisterOptionControls(
        "X4D_LibAntiSpam_CPL",
        {
            [1] = {
                type = "checkbox",
                name = "Notify when detected Spam?", 
                tooltip = "When enabled, Names are logged to the chat frame when spam is detected.", 
                getFunc = function() return X4D.AntiSpam.Settings:Get("NotifyWhenDetected") end,
                setFunc = function() X4D.AntiSpam.Settings:Set("NotifyWhenDetected", not X4D.AntiSpam.Settings:Get("NotifyWhenDetected")) end,
            },
            [2] = {
                type = "slider",
                name = "Max Flood Time",
                tooltip = "This determines mininum amount of time, in seconds, before repeated text is not considered Flooding. Flooding is when a user types the same thing into chat over and over.",
                min = 0, max = 900, step = 5,
                getFunc = function () return X4D.AntiSpam.Settings:Get("FloodTimeSeconds") end,
                setFunc = function (v) X4D.AntiSpam.Settings:Set("FloodTimeSeconds", tonumber(tostring(v))) end,
            },
            [3] = {
                type = "editbox",
                name = "User Patterns", 
                tooltip = "Line-delimited list of User-Defined AntiSpam Patterns, each one should be on a new line.", 
                isMultiline = true,
                getFunc = function () 
                    local patterns = X4D.AntiSpam.Settings:Get("Patterns")
                    if (patterns == nil or type(patterns) == "string") then
                        patterns = { }
                    end
                    return table.concat(patterns, "\n")
                end,
                setFunc = function(v)
                    --local v = _G["X4D_LIBANTISPAM_EDIT_PATTERNS"]["edit"]:GetText()
                    local result = s:Split("\n")
                    -- NOTE: this is a hack to deal with the fact that the LUA parser in ESO bugs out processing escaped strings in SavedVars :(
                    for _,x in pairs(result) do
                        if (x:EndsWith("]")) then
                            result[_] = x .. "+"
                        end
                    end
                    X4D.AntiSpam.Settings:Set("Patterns", result)
                end,
            },
            [4] = {
                type = "checkbox",
                name = "Use Internal Patterns?", 
                tooltip = "When enabled, an internal set of patterns are used (in addition to any 'User Patterns' you define.) |c7C7C7CInternal patterns are based on popular gold-seller sites and chat spam observed in the past. Pattern definitions are only updated when new spammers are seen in-game.",
                getFunc = function() return X4D.AntiSpam.Settings:Get("UseInternalPatterns") end,
                setFunc = function()
                    local v = not X4D.AntiSpam.Settings:Get("UseInternalPatterns")
                    X4D.AntiSpam.Settings:Set("UseInternalPatterns", v)
                    if (not v) then
                        X4D.AntiSpam.Settings:Set("UseAggressivePatterns", v)
                    end
                end,
            },
            [5] = {
                type = "checkbox",
                name = "Use Aggressive Patterns?", 
                tooltip = "When enabled, an internal set of 'aggressive' patterns are used, these patterns are typically only used for extreme spam scenarios.",
                getFunc = function() return X4D.AntiSpam.Settings:Get("UseAggressivePatterns") end,
                setFunc = function() 
                    local v = not X4D.AntiSpam.Settings:Get("UseAggressivePatterns")
                    X4D.AntiSpam.Settings:Set("UseAggressivePatterns", v)
                    if (v) then
                        X4D.AntiSpam.Settings:Set("UseInternalPatterns", v)
                    end
                end,
            },
            [6] = {
                type = "checkbox",
                name = "[DEV] Show normalized text.", 
                tooltip = "When enabled, all normalized text is dumped to the Chat Window to aid in creating/debugging patterns.", 
                getFunc = function() return X4D.AntiSpam.Settings:Get("ShowNormalizations") end,
                setFunc = function() X4D.AntiSpam.Settings:Set("ShowNormalizations", not X4D.AntiSpam.Settings:Get("ShowNormalizations")) end,
            },
        })

	X4D_LibAntiSpam.Register()
end

function X4D_LibAntiSpam.OnGuildInviteAdded(id1, id2, guildName, id4, fromName)
	zo_callLater(RejectSpammerGuildInvites, 1000)
end

function X4D_LibAntiSpam.Register()
	ZO_ChatSystem_AddEventHandler(EVENT_CHAT_MESSAGE_CHANNEL, X4D_LibAntiSpam.OnChatMessageReceived)
end

function X4D_LibAntiSpam.Unregister()
	ZO_ChatSystem_AddEventHandler(EVENT_CHAT_MESSAGE_CHANNEL, nil)
end

local function DEC2HEX(input)
	local h = (input / 16)
	local l = (input - (h * 16))
	return string.format("%x%x", h, l)
end

function X4D_LibAntiSpam.CreateColorCode(r, g, b)
	return "|c" .. DEC2HEX(r * 255) .. DEC2HEX(g * 255) .. DEC2HEX(b * 255)
end

local _initialized = false

function X4D_LibAntiSpam.OnPlayerActivated()
	zo_callLater(function() 
		RejectSpammerGuildInvites()
	end, 3000)

	if (not _initialized) then
		_initialized = true
		local r, g, b = GetChatCategoryColor(CHAT_CATEGORY_SYSTEM)
		if (r ~= nil) then
			X4D_LibAntiSpam.Colors.SYSTEM = X4D_LibAntiSpam.CreateColorCode(r, g, b)
		end
	end
end

EVENT_MANAGER:RegisterForEvent(X4D_LibAntiSpam.NAME, EVENT_ADD_ON_LOADED, X4D_LibAntiSpam.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(X4D_LibAntiSpam.NAME, EVENT_GUILD_INVITE_ADDED, X4D_LibAntiSpam.OnGuildInviteAdded)
EVENT_MANAGER:RegisterForEvent(X4D_LibAntiSpam.NAME, EVENT_PLAYER_ACTIVATED, X4D_LibAntiSpam.OnPlayerActivated)

-- TODO: add OOM hook and free up any playerState records older than X hours
