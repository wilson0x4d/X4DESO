local X4D_XP = LibStub:NewLibrary('X4D_XP', 1.1);
if (not X4D_XP) then
	return;
end

X4D_XP.NAME = 'X4D_XP';
X4D_XP.VERSION = 1.1;

X4D_XP.Settings = {};
X4D_XP.Settings.SavedVars = {};
X4D_XP.Settings.Defaults = {
	None = 'true',
};

X4D_XP.Colors = {
	XP = '|cAA33FF',
	Gray = '|cC5C5C5',
	X4D = '|cFFAE19',
};

local _expReasons = { };
_expReasons[0] = 'Kill';
--_expReasons[1] = 'Quest';
--_expReasons[2] = 'POI';
--_expReasons[3] = 'Discovery';
_expReasons[4] = 'Command';
_expReasons[5] = 'Keep';
_expReasons[6] = 'Battleground'
_expReasons[7] = 'Event';
_expReasons[8] = 'Medal';
_expReasons[9] = 'Finesse';
_expReasons[10] = 'Lockpicking';
_expReasons[11] = 'Book';
_expReasons[12] = 'Skill';
_expReasons[13] = 'Action';
_expReasons[14] = 'Guild';
_expReasons[15] = 'PvP';
_expReasons[16] = 'Tradeskill';
_expReasons[17] = 'Reward';
_expReasons[18] = 'Acheivement';
_expReasons[19] = 'Quest';
_expReasons[20] = 'Consumption';
_expReasons[21] = 'Harvest';
_expReasons[22] = 'Recipe'
_expReasons[23] = 'Trait';
_expReasons[24] = 'Boss';

local function GetExpReason(reasonIndex)
	return _expReasons[reasonIndex];
end

local function DefaultCallback(color, text)
	d(color .. text);
end

X4D_XP.Callback = DefaultCallback;

function X4D_XP.RegisterCallback(self, callback)
	if (callback ~= nil) then
		X4D_XP.Callback = callback;
	else
		X4D_XP.Callback = DefaultCallback;
	end
end

function X4D_XP.UnregisterCallback(self, callback)
	if (X4D_XP.Callback == callback) then
		self:RegisterCallback(nil);
	end
end

local function InvokeCallbackSafe(color, text)
	local callback = X4D_XP.Callback;
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

local function OnQuestCompleteExperience(eventCode, questName, xpGained)
	InvokeCallbackSafe(X4D_XP.Colors.XP, xpGained .. ' XP for ' .. X4D_XP.Colors.X4D .. questName);
end

local function OnExperienceGain(eventCode, xpGained, reasonIndex)
	local reason = GetExpReason(reasonIndex);
	if (reason ~= nil) then
		InvokeCallbackSafe(X4D_XP.Colors.XP, xpGained .. ' XP for ' .. reason);
	end
end

local function OnDiscoveryExperienceGain(eventCode, areaName, xpGained)
	InvokeCallbackSafe(X4D_XP.Colors.XP, xpGained .. ' XP for Discovery ' .. X4D_XP.Colors.X4D .. areaName);
end

local function OnObjectiveCompleted(eventCode, zoneIndex, poiIndex, xpGained)
	local objectiveName, objectiveLevel, startDescription, finishedDescription = GetPOIInfo(zoneIndex, poiIndex);
	if (objectiveName ~= nil and objectiveName:len() > 0) then
		InvokeCallbackSafe(X4D_XP.Colors.XP, xpGained .. ' XP for ' .. X4D_XP.Colors.X4D .. objectiveName);
	else
		InvokeCallbackSafe(X4D_XP.Colors.XP, xpGained .. ' XP for POI ');
	end
end

local _currentExp = 0;

local function OnExperienceUpdate(eventCode, unitTag, currentExp, maxExp, reasonIndex)
	if (unitTag ~= 'player') then
		return;
	end
	local xpGained = currentExp - _currentExp;
	if (xpGained > 0) then
		local reason = GetExpReason(reasonIndex);
		if (reason ~= nil) then
			InvokeCallbackSafe(X4D_XP.Colors.XP, xpGained .. ' XP for ' .. reason);
		end
	end
	_currentExp = currentExp;
end

function X4D_XP.OnAddOnLoaded(event, addonName)
	if (addonName ~= X4D_XP.NAME) then
		return;
	end	
	X4D_XP.Settings.SavedVars = ZO_SavedVars:NewAccountWide(X4D_XP.NAME .. '_SV', 1.0, nil, X4D_XP.Settings.Defaults);
	X4D_XP.Register();
end

function X4D_XP.Register()
	EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_QUEST_COMPLETE_EXPERIENCE, OnQuestCompleteExperience);
	--EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_EXPERIENCE_GAIN, OnExperienceGain);
	EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_EXPERIENCE_GAIN_DISCOVERY, OnDiscoveryExperienceGain);
	EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_OBJECTIVE_COMPLETED, OnObjectiveCompleted);
	EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_EXPERIENCE_UPDATE, OnExperienceUpdate);
end

function X4D_XP.Unregister()
end

function X4D_XP.OnPlayerActivated()
	_currentExp = GetUnitXP('player');
end

EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_ADD_ON_LOADED, X4D_XP.OnAddOnLoaded);
EVENT_MANAGER:RegisterForEvent(X4D_XP.NAME, EVENT_PLAYER_ACTIVATED, X4D_XP.OnPlayerActivated);


