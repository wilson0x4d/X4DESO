local X4D_Players = LibStub:NewLibrary("X4D_Players", 1020)
if (not X4D_Players) then
    return
end
local X4D = LibStub("X4D")
X4D.Players = X4D_Players

local X4D_Player = {}

---
-- X4D_Player:New(tag)
---
-- 'tag' := <target-unit|player-name|character-name>::string
--
function X4D_Player:New(tag)
    local unitName = GetRawUnitName(tag)
    if (unitName == nil or unitName:len() == 0) then
        unitName = tag
    end
    local key = "$" .. base58(sha1(unitName):FromHex())
    local proto = {
        Name = unitName,
        IsWhitelisted = false,
        IsBlacklisted = false,
        IsFlooder = false,
        IsSpammer = false,
        LastSeen = GetGameTimeMilliseconds(),
        --TODO LastMapIndex = nil,
        --TODO LastZoneIndex = nil,
        --TODO LastX = nil,
        --TODO LastY = nil,
        --TODO LastHeading = nil,
        --TODO LastVelocity = nil,
    }
	--setmetatable(proto, { __index = X4D_Player })
    return proto
end

function X4D_Players:IsSelf(player)
	return (player.Name == GetRawUnitName("player"))
end

function X4D_Players:IsInGroup(player)
	return IsPlayerInGroup(player.Name)
end

function X4D_Players:IsInFriends(player)
	return IsFriend(player.Name)
end

function X4D_Players:IsInGuild(player)
	for guildIndex = 1,GetNumGuilds() do
		local guildId = GetGuildId(guildIndex)
		if (guildId ~= nil) then
			for memberIndex = 1,GetNumGuildMembers(guildId) do
				local name, note, rankIndex, playerStatus, secsSinceLogoff = GetGuildMemberInfo(guildId, memberIndex)				
				if (name == player.Name) then
					return true
				end
				local hasCharacter, characterName, zoneName, classType, alliance, level, veteranRank = GetGuildMemberCharacterInfo(guildId, memberIndex)
                if (hasCharacter) then
				    if (characterName == player.Name) then
					    return true
				    end
                end
			end
		end			
	end
	return false
end

local _playerScavenger = nil
local _playerScavengerFrequency = 1000 * 47 -- default, 2 minutes between player db maintenance intervals
local _playerScavengerTimePeriod = _playerScavengerFrequency * 10 -- default, 10 'maintenance intervals' before players are scavenged

local function ShouldScavengePlayer(player) 
    local now = GetGameTimeMilliseconds()
    return
        player == nil
        or (not (player.IsWhitelisted or player.IsBlacklisted or player.IsSpammer) -- do not purge known spammers or anyone explicitly blacklisted/whitelisted
        and ((now - player.LastSeen) >= _playerScavengerTimePeriod)) -- only purge 'old' players from database
end

local function DoScavenge(player, key)
    if (ShouldScavengePlayer(player)) then
        X4D_Players.DB:Remove(key)
    end
end

local function StartPlayerScavenger() 
    if (_playerScavenger ~= nil) then
        return 
    end
    _playerScavenger = X4D.Async:CreateTimer(function (timer, state)
        X4D_Players.DB
            :ForEach(DoScavenge)
    end, {}):Start(_playerScavengerFrequency, {}, "X4D_Players::PlayerScavenger")
end

EVENT_MANAGER:RegisterForEvent("X4D_Players", EVENT_ADD_ON_LOADED, function(event, name)
    if (name ~= "X4D_Core") then
        return
    end
    X4D_Players.DB = X4D.DB:Open("X4D_Players")
end)

EVENT_MANAGER:RegisterForEvent("X4D_Players_SCAVENGER", EVENT_PLAYER_ACTIVATED, function()
    StartPlayerScavenger()
end)

function X4D_Players:GetPlayer(tag)
    local ts = GetGameTimeMilliseconds()
    local unitName = GetRawUnitName(tag)
    if (unitName == nil or unitName:len() == 0) then
        unitName = tag
    end
    -- attempt to lookup by key
    local key = "$" .. base58(sha1(unitName):FromHex())
    local player = self.DB:Find(key)
    if (player == nil or player.CreatedAt == nil or (ts - player.CreatedAt) > 300000) then
        -- lookup by key failed, perhaps this user is known by name (e.g. cross-channel chat where player-names are not discoverable, but we know this player through some other means such as friends list or guild where their account name is in the clear.)
        player = self.DB:FirstOrDefault(function(player) return player.Name == unitName end)
        if (player == nil or player.CreatedAt == nil or (ts - player.CreatedAt) > 300000) then
            player = X4D_Player(tag)
            player.CreatedAt = ts
            self.DB:Add(key, player)
        end
    end
    -- TODO: this needs to be re-updated when (1) join or leave a group (2) add/remove from friends (3) you/other join/part a guild
    -- EVENT_FRIEND_ADDED
    -- EVENT_FRIEND_REMOVED
    -- for now, we update whitelist every single time we fetch the player from the db - it's inefficient, but assures consistency with game state for the caller
    player.IsWhitelisted = self:IsSelf(player) or self:IsInGroup(player) or self:IsInFriends(player) or self:IsInGuild(player)
    return player, key
end

--setmetatable(X4D_Players, { __call = X4D_Players.GetPlayer })

setmetatable(X4D_Player, { __call = X4D_Player.New })
