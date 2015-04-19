local X4D_Players = LibStub:NewLibrary("X4D_Players", 1001)
if (not X4D_Players) then
    return
end
local X4D = LibStub("X4D")
X4D.Players = X4D_Players

local X4D_Player = {}

function X4D_Player:New(tag)
    local playerName = GetRawUnitName(tag)
    if (playerName == nil or playerName:len() == 0) then
        playerName = tag
    end
    local proto = {
        Key = playerName,
        Name = playerName:gsub("%^.*", ""),
        AccountId = '', -- can we get the account id somehow?
        IsWhitelisted = false,
        IsBlacklisted = false,
        IsFlooder = false,
        IsSpammer = false,
        LastSeen = GetGameTimeMilliseconds(),
    }
	--setmetatable(proto, { __index = X4D_Player })
    return proto
end

function X4D_Players:IsSelf(player)
	return (player.Name == GetUnitName("player"))
end

function X4D_Players:IsInGroup(player)
	return IsPlayerInGroup(player.Name)
end

function X4D_Players:IsInFriends(player)
	return IsFriend(player.Name)
end

function X4D_Players:IsInGuild(player)
	local fromName = player.Name
	for guildIndex = 1,GetNumGuilds() do
		local guildId = GetGuildId(guildIndex)
		if (guildId ~= nil) then
			for memberIndex = 1,GetNumGuildMembers(guildId) do
				local name, note, rankIndex, playerStatus, secsSinceLogoff = GetGuildMemberInfo(guildId, memberIndex)				
				if (name == fromName) then
					return true
				end
				local hasCharacter, characterName, zoneName, classType, alliance, level, veteranRank = GetGuildMemberCharacterInfo(guildId, memberIndex)
				characterName = characterName:gsub("%^.*", "")
				if (characterName == fromName) then
					return true
				end
			end
		end			
	end
	return false
end

EVENT_MANAGER:RegisterForEvent("X4D_Players.DB", EVENT_ADD_ON_LOADED, function(event, name)
    if (name == "X4D_Core") then
        X4D_Players.DB = X4D.DB("X4D_Players.DB")
    end
end)

function X4D_Players:GetPlayer(tag)
    local playerName = GetRawUnitName(tag)
    if (playerName == nil or playerName:len() == 0) then
        playerName = tag
    end
    local player = self.DB
        :Where(function(player) return (player.Key:match(playerName) or player.Name:match(playerName)) ~= nil end)
        :FirstOrDefault()
    if (player == nil) then
        player = X4D_Player(tag)
        self.DB:Add(player)
    end
    -- TODO: this needs to be re-updated when (1) join or leave a group (2) add/remove from friends (3) you/other join/part a guild
    -- for now, we update whitelist every single time we fetch the player from the db - it's inefficient
    player.IsWhitelisted = self:IsSelf(player) or self:IsInGroup(player) or self:IsInFriends(player) or self:IsInGuild(player)
    return player
end

--setmetatable(X4D_Players, { __call = X4D_Players.GetPlayer })

setmetatable(X4D_Player, { __call = X4D_Player.New })

-- TODO: add OOM hook and free up any player records older than X time, discriminate and keep any records belonging to flooders, spammers, whitelisted and blacklisted users
