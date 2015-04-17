local X4D_XP = LibStub:NewLibrary("X4D_XP", 1005)
if (not X4D_XP) then
	return
end
local X4D = LibStub("X4D")
X4D.XP = X4D_XP

X4D_XP.NAME = "X4D_XP"
X4D_XP.VERSION = "1.5"

X4D_XP.Settings = {}
X4D_XP.Settings.SavedVars = {}
X4D_XP.Settings.Defaults = {
	None = "true",
}

local _pointType = "XP"
local _currentExp = 0
local _currentVP = 0
local _playerIsVeteran = false


local _expReasons = { }
_expReasons[PROGRESS_REASON_NONE] = "???" -- TODO: what is this, exactly?
_expReasons[PROGRESS_REASON_KILL] = "Kill"
--_expReasons[PROGRESS_REASON_QUEST] = "Quest" --see OnQuestCompleteExperience() instead
--_expReasons[PROGRESS_REASON_DISCOVER_POI] = "POI" --see OnDiscoveryExperienceGain() instead
--_expReasons[PROGRESS_REASON_COMPLETE_POI] = "Exploration" --see OnObjectiveCompleted() instead
_expReasons[PROGRESS_REASON_COMMAND] = "Command"
_expReasons[PROGRESS_REASON_KEEP_REWARD] = "Keep"
_expReasons[PROGRESS_REASON_BATTLEGROUND] = "Battleground"
_expReasons[PROGRESS_REASON_SCRIPTED_EVENT] = "Event"
_expReasons[PROGRESS_REASON_EVENT] = "Event"
_expReasons[PROGRESS_REASON_DARK_ANCHOR_CLOSED] = "Anchor"
_expReasons[PROGRESS_REASON_DARK_FISSURE_CLOSED] = "Fissure"
_expReasons[PROGRESS_REASON_MEDAL] = "Medal"
_expReasons[PROGRESS_REASON_FINESSE] = "Finesse"
_expReasons[PROGRESS_REASON_LOCK_PICK] = "Lockpicking"
_expReasons[PROGRESS_REASON_COLLECT_BOOK] = "Book"
_expReasons[PROGRESS_REASON_BOOK_COLLECTION_COMPLETE] = "Book Collection"
_expReasons[PROGRESS_REASON_SKILL_BOOK] = "Skill"
_expReasons[PROGRESS_REASON_TRADESKILL_ACHIEVEMENT] = "Tradeskill (Achievement)"
_expReasons[PROGRESS_REASON_ACTION] = "Action"
_expReasons[PROGRESS_REASON_GUILD_REP] = "Guild"
_expReasons[PROGRESS_REASON_AVA] = "PvP"
_expReasons[PROGRESS_REASON_TRADESKILL] = "Tradeskill"
_expReasons[PROGRESS_REASON_REWARD] = "Reward"
_expReasons[PROGRESS_REASON_ACHIEVEMENT] = "Acheivement"
_expReasons[PROGRESS_REASON_TRADESKILL_QUEST] = "Tradeskill (Quest)"
_expReasons[PROGRESS_REASON_TRADESKILL_CONSUME] = "Tradeskill (Consume)"
_expReasons[PROGRESS_REASON_TRADESKILL_HARVEST] = "Tradeskill (Harvest)"
_expReasons[PROGRESS_REASON_TRADESKILL_RECIPE] = "Tradeskill (Recipe)"
_expReasons[PROGRESS_REASON_TRADESKILL_TRAIT] = "Tradeskill (Trait)"
_expReasons[PROGRESS_REASON_OVERLAND_BOSS_KILL] = "Boss"
_expReasons[PROGRESS_REASON_BOSS_KILL] = "Boss"
_expReasons[PROGRESS_REASON_OTHER] = "Other"
_expReasons[PROGRESS_REASON_GRANT_REPUTATION] = "Reputation Granted"
_expReasons[PROGRESS_REASON_ALLIANCE_POINTS] = "Alliance Points"
_expReasons[PROGRESS_REASON_PVP_EMPEROR] = "Emperor"
_expReasons[PROGRESS_REASON_DUNGEON_CHALLENGE] = "Dungeon Challenge"

local function GetExpReason(reasonIndex)
	return _expReasons[reasonIndex]
end

local function DefaultCallback(color, text)
	d(color .. text)
end

X4D_XP.Callback = DefaultCallback

function X4D_XP.RegisterCallback(self, callback)
	if (callback ~= nil) then
		X4D_XP.Callback = callback
	else
		X4D_XP.Callback = DefaultCallback
	end
end

function X4D_XP.UnregisterCallback(self, callback)
	if (X4D_XP.Callback == callback) then
		self:RegisterCallback(nil)
	end
end

local function InvokeCallbackSafe(color, text)
	local callback = X4D_XP.Callback
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

local function OnQuestCompleteExperience(eventCode, questName, level, previousExperience, currentExperience, rank, previousPoints, currentPoints)	
    local xpGained = currentExperience - previousExperience
	InvokeCallbackSafe(X4D.Colors.XP, xpGained .. " " .. _pointType .. " for " .. X4D.Colors.X4D .. questName)
    _currentExp = _currentExp + xpGained
end

local function OnDiscoveryExperienceGain(eventCode, areaName, level, previousExperience, currentExperience, rank, previousPoints, currentPoints)
    local xpGained = currentExperience - previousExperience
	InvokeCallbackSafe(X4D.Colors.XP, xpGained .. " " .. _pointType .. " for Discovery " .. X4D.Colors.X4D .. areaName)
    _currentExp = _currentExp + xpGained
end

local function OnObjectiveCompleted(eventCode, zoneIndex, poiIndex, level, previousExperience, currentExperience, rank, previousPoints, currentPoints)
    local xpGained = currentExperience - previousExperience
	local objectiveName, objectiveLevel, startDescription, finishedDescription = GetPOIInfo(zoneIndex, poiIndex)
	if (objectiveName ~= nil and objectiveName:len() > 0) then
		InvokeCallbackSafe(X4D.Colors.XP, xpGained .. " " .. _pointType .. " for " .. X4D.Colors.X4D .. objectiveName)
	else
		InvokeCallbackSafe(X4D.Colors.XP, xpGained .. " " .. _pointType .. " for POI ")
	end
    _currentExp = _currentExp + xpGained
end


local function OnExperienceUpdate(eventCode, unitTag, currentExp, maxExp, reasonIndex)    
	if (unitTag ~= "player") then
		return
	end
	local xpGained = currentExp - _currentExp
	if (xpGained > 0) then
		local reason = GetExpReason(reasonIndex)
		if (reason ~= nil) then            
			InvokeCallbackSafe(X4D.Colors.XP, xpGained .. " " .. _pointType .. " for " .. reason)
		end
	end
	_currentExp = _currentExp + xpGained
end

function X4D_XP.OnAddOnLoaded(event, addonName)
	if (addonName ~= X4D_XP.NAME) then
		return
	end	
	X4D_XP.Settings.SavedVars = ZO_SavedVars:NewAccountWide(X4D_XP.NAME .. "_SV", 1.0, nil, X4D_XP.Settings.Defaults)
	X4D_XP.Register()
end

function X4D_XP.Register()
	EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_QUEST_COMPLETE, OnQuestCompleteExperience)
	EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_DISCOVERY_EXPERIENCE, OnDiscoveryExperienceGain)
	EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_OBJECTIVE_COMPLETED, OnObjectiveCompleted)
	EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_EXPERIENCE_UPDATE, OnExperienceUpdate)
	EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_VETERAN_POINTS_UPDATE, OnExperienceUpdate)
end

function X4D_XP.Unregister()
end

function X4D_XP.OnPlayerActivated()
	_currentExp = GetUnitXP("player")
    _playerIsVeteran = IsUnitVeteran("player")
	if (_playerIsVeteran) then        
		_pointType = "VP"
	else
		_pointType = "XP"
	end
end

EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_ADD_ON_LOADED, X4D_XP.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_PLAYER_ACTIVATED, X4D_XP.OnPlayerActivated)


