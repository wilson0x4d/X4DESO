local X4D_XP = LibStub:NewLibrary("X4D_XP", 1011)
if (not X4D_XP) then
	return
end
local X4D = LibStub("X4D")
X4D.XP = X4D_XP

X4D_XP.NAME = "X4D_XP"
X4D_XP.VERSION = "1.11"

local _pointType = "XP"
local _currentXP = 0
local _playerIsVeteran = false
local _eta = nil

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

local function InvokeChatCallback(color, text)
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
    _eta:Increment(xpGained)
	InvokeChatCallback(X4D.Colors.XP, xpGained .. " " .. _pointType .. " for " .. X4D.Colors.X4D .. questName)
    _currentXP = _currentXP + xpGained
end

local function OnDiscoveryExperienceGain(eventCode, areaName, level, previousExperience, currentExperience, rank, previousPoints, currentPoints)
    local xpGained = currentExperience - previousExperience
    _eta:Increment(xpGained)
	InvokeChatCallback(X4D.Colors.XP, xpGained .. " " .. _pointType .. " for Discovery " .. X4D.Colors.X4D .. areaName)
    _currentXP = _currentXP + xpGained
end

local function OnObjectiveCompleted(eventCode, zoneIndex, poiIndex, level, previousExperience, currentExperience, rank, previousPoints, currentPoints)
    local xpGained = currentExperience - previousExperience
    _eta:Increment(xpGained)
	local objectiveName, objectiveLevel, startDescription, finishedDescription = GetPOIInfo(zoneIndex, poiIndex)
	if (objectiveName ~= nil and objectiveName:len() > 0) then
		InvokeChatCallback(X4D.Colors.XP, xpGained .. " " .. _pointType .. " for " .. X4D.Colors.X4D .. objectiveName)
	else
		InvokeChatCallback(X4D.Colors.XP, xpGained .. " " .. _pointType .. " for POI ")
	end
    _currentXP = _currentXP + xpGained
end

local function GetStatusBarPanelText()
    local xpMinute = math.floor(_eta:GetSessionAverage(60000))
    local message = ""
    local tnl = (_eta.TargetCount - _eta.AllTimeCount)
    if (xpMinute >= 1) then
        message = message .. xpMinute .. " " .. _pointType .. "/minute"
    if (X4D_XP.Settings:Get("ShowTTL")) then
        local ttl = (tnl / _eta:GetSessionAverage())
        local ttlDays = math.floor(ttl / 86400)
        local shave = (ttlDays * 86400)
        local ttlHours = math.floor((ttl - shave) / 3600)
        shave = shave + (ttlHours * 3600)
        local ttlMinutes = math.floor((ttl - shave) / 60)
        shave = shave + (ttlMinutes * 60)
        local ttlSeconds = math.floor(ttl - shave)
        local ttlString = ""
        if (ttlDays > 0) then
            ttlString = string.format("%d:%02d:%02d:%02d", ttlDays, ttlHours, ttlMinutes, ttlSeconds)
        elseif (ttlHours > 0) then
            ttlString = string.format("%02d:%02d:%02d", ttlHours, ttlMinutes, ttlSeconds)
        else
            ttlString = string.format("%02d:%02d", ttlMinutes, ttlSeconds)
        end
        message = message .. ", " .. ttlString
    end
    end
    if (X4D_XP.Settings:Get("ShowTNL") and tnl > 0) then
        if (message:len() > 0) then
            message = message .. ", "
        end
        message = message .. tnl .. " tnl" -- TODO: localize
    end
    return X4D.Colors.XP .. message
end

local function OnExperienceUpdate(eventCode, unitTag, currentExp, maxExp, reasonIndex)    
	if (unitTag ~= "player") then
		return
	end
    if (maxExp ~= _eta.TargetCount) then
        -- TODO: need a 'leveled' event to reset this from (and should also reset anything else set on 'player activation'
        _eta:Reset(maxExp)
    end
	local xpGained = currentExp - _currentXP
	if (xpGained > 0) then
        _eta:Increment(xpGained)
        local message = xpGained .. " " .. _pointType
		local reason = GetExpReason(reasonIndex)
		if (reason ~= nil) then            
            message = message .. " for " .. reason
            local xpMinute = _eta:GetSessionAverage(60000)
            message = message .. X4D.Colors.Subtext .. " (" .. math.ceil(xpMinute) .. " " .. _pointType .. "/minute" 
            local tnl = (_eta.TargetCount - _eta.AllTimeCount)
            if (X4D_XP.Settings:Get("ShowTTL")) then
                local ttl = (tnl / _eta:GetSessionAverage())
                local ttlDays = math.floor(ttl / 86400)
                local shave = (ttlDays * 86400)
                local ttlHours = math.floor((ttl - shave) / 3600)
                shave = shave + (ttlHours * 3600)
                local ttlMinutes = math.floor((ttl - shave) / 60)
                shave = shave + (ttlMinutes * 60)
                local ttlSeconds = math.floor(ttl - shave)
                local ttlString = ""
                if (ttlDays > 0) then
                    ttlString = string.format("%d:%02d:%02d:%02d", ttlDays, ttlHours, ttlMinutes, ttlSeconds)
                elseif (ttlHours > 0) then
                    ttlString = string.format("%02d:%02d:%02d", ttlHours, ttlMinutes, ttlSeconds)
                else
                    ttlString = string.format("%02d:%02d", ttlMinutes, ttlSeconds)
                end
                message = message .. ", " .. ttlString
            end
            if (X4D_XP.Settings:Get("ShowTNL")) then
                message = message .. ", " .. tnl .. " tnl"
            end
            message = message .. ")"
		    InvokeChatCallback(X4D.Colors.XP, message)
        end
	end
	_currentXP = _currentXP + xpGained
end

local function InitializeSettingsUI()
	local LAM = LibStub("LibAddonMenu-2.0")
	local cplId = LAM:RegisterAddonPanel("X4D_XP_CPL", {
        type = "panel",
        name = "X4D |cFFAE19XP |c4D4D4D" .. X4D_XP.VERSION,
    })

    local panelControls = { }

    table.insert(panelControls, {
        type = "checkbox",
        name = "Show time-to-level (TTL)", 
        tooltip = "When enabled, XP/min and time-to-level (ttl) are displayed with each kill.", 
        getFunc = function() 
            return X4D.XP.Settings:Get("ShowTTL")
        end,
        setFunc = function()
            X4D.XP.Settings:Set("ShowTTL", not X4D.XP.Settings:Get("ShowTTL")) 
        end,
    })

    table.insert(panelControls, {
        type = "checkbox",
        name = "Show XP `til-next-level (TNL)", 
        tooltip = "When enabled, XP remaining until next level are displayed.", 
        getFunc = function() 
            return X4D.XP.Settings:Get("ShowTNL")
        end,
        setFunc = function()
            X4D.XP.Settings:Set("ShowTNL", not X4D.XP.Settings:Get("ShowTNL")) 
        end,
    })

    LAM:RegisterOptionControls(
        "X4D_XP_CPL",
        panelControls
    )
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

local _statusBarPanel

local function UpdateStatusBarText()
    --X4D.Log:Verbose{"X4D_XP::UpdateStatusBarText"}
    local text = GetStatusBarPanelText()
    if (text == nil) then text = "" end
    _statusBarPanel:SetText(text)
end

local function InitializeUI()
    if (X4D.UI ~= nil) then
        _statusBarPanel = X4D.UI.StatusBar:CreatePanel("X4D_XP_StatusBarPanel", UpdateStatusBarText, 3)
        UpdateStatusBarText()
    end
end

EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_ADD_ON_LOADED, function(eventCode, addonName)
	if (addonName ~= X4D_XP.NAME) then
		return
	end	
    X4D.Log:Debug({"OnAddonLoaded", eventCode, addonName}, X4D_XP.NAME)
    local stopwatch = X4D.Stopwatch:StartNew()
    _eta = X4D.ETA('X4D_XP')

	X4D_XP.Settings = X4D.Settings(
        X4D_XP.NAME .. "_SV", 
        {
            ShowTNL = true, -- show XP til-next-level (tnl)
            ShowTTL = true, -- show XP/min and time-to-level (ttl)
        })

    InitializeSettingsUI()

	X4D_XP.Register()

    InitializeUI()
    X4D_XP.Took = stopwatch.ElapsedMilliseconds()
end)
EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_PLAYER_ACTIVATED, function()
    _playerIsVeteran = IsUnitVeteran("player")
	if (_playerIsVeteran) then
		_pointType = "VP"
    	_currentXP = GetUnitVeteranPoints("player")
	else
		_pointType = "XP"
    	_currentXP = GetUnitXP("player")        
	end
    _eta.AllTimeCount = _currentXP
end)


