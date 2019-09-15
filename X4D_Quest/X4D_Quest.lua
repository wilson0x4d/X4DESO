local X4D_Quest = LibStub:NewLibrary("X4D_Quest", "0#VERSION#")
if (not X4D_Quest) then
	return
end
local X4D = LibStub("X4D")
X4D.Quest = X4D_Quest

X4D_Quest.NAME = "X4D_Quest"
X4D_Quest.VERSION = "#VERSION#"

-- NOTE: we track both module-local as well as expose an observable, the
--        module-local reference is for build-up purposes (we do not tamper
--        with observable until we have completed build-up); this ensures
--        consumer code can reliably observe the quest (in its entirety.)
local _trackedQuest = nil 
X4D_Quest.TrackedQuest = X4D.Observable(nil)

-- NOTE: within the ZO journal quest API is a notion of tasks, most likely
--        coroutines dependent on game UI state (not LUA state), this maps
--        from task IDs to the { QuestIndex, StepIndex, ConditionIndex }
--        the task was created for. this allows us to verify and index
--        quest info to apply the requested info. it is effectiely a
--        correlation table. passing a state object in on the request
--        (and on to callbacks/handlers) would be a more elegant design.
local _tasks = {}

local function DoesQuestHaveLocation(questInfo)

    -- not initialized
    if (questInfo == nil) then
        -- X4D.Log:Warning("DoesQuestHaveLocation(nil)", "Quest")
        return false
    end

    -- NOTE: we do not rely on condition location details because
    --       they are unreliable/incomplete for location purposes,
    --       instead we look for values populateed by the AddOn:
    if (questInfo.Locations == nil) then
        -- X4D.Log:Warning("DoesQuestHaveLocation(X=nil||Y=nil)", "Quest")
        return false
    end

    return true
end

local function CheckTrackedQuestFullyPopulatedThenEvent()
    -- if tracked quest is fully populated, update observable, and reset for next
    if (_trackedQuest ~= nil and DoesQuestHaveLocation(_trackedQuest)) then
        X4D_Quest.TrackedQuest(_trackedQuest)
        _trackedQuest = nil
        return true
    end
    return false
end

local function X4D_Quest_RefreshInternal()
    -- X4D.Log:Debug("X4D_Quest_RefreshInternal", X4D_Quest.NAME)
    local ts = GetGameTimeMilliseconds()
    local numQuests = MAX_JOURNAL_QUESTS --GetNumJournalQuests()
    for journalQuestIndex = 1, numQuests do
        if IsValidQuestIndex(journalIndex) then
            local questName, backgroundText, activeStepText, activeStepType, activeStepTrackerOverrideText, completed, tracked, questLevel, pushed, questType, instanceDisplayType = GetJournalQuestInfo(journalQuestIndex)
            if (tracked) then
                if (_trackedQuest == nil or (_trackedQuest.Index ~= journalQuestIndex) or (_trackedQuest.Name ~= questName)) then
                    local trackingLevel = GetTrackingLevel(TRACK_TYPE_QUEST, journalQuestIndex)
                    -- prep ZO World Map
                    -- NOTE: without these calls we don't see the pins when we scrape world map later
                    RemoveMapQuestPins(journalQuestIndex)
                    AddMapQuestPins(journalQuestIndex, trackingLevel)
                    -- quest
                    _trackedQuest = {
                        Index = journalQuestIndex,
                        IsComplete = completed,
                        Level = questLevel,
                        Type = questType,
                        TrackingLevel = trackingLevel,
                        InstanceDisplayType = instanceDisplayType,
                        Name = questName,
                        Steps = {}
                    }
                    -- quest ending details
                    local goalText, dialogText, confirmCompleteText, declineCompleteText, backgroundText, journalStepText = GetJournalQuestEnding(journalQuestIndex)
                    _trackedQuest.Ending = {
                        GoalText = goalText,
                        DialogText = dialogText,
                        ConfirmCompleteText = confirmCompleteText,
                        DeclineCompleteText = declineCompleteText,
                        BackgroundText = backgroundText,
                        JournalStepText = journalStepText
                    }

                    -- TODO: any other data we'd like to use?

                    -- quest steps
                    local numSteps = GetJournalQuestNumSteps(journalQuestIndex)
                    for stepIndex = QUEST_MAIN_STEP_INDEX, numSteps do
                        local stepText, visibility, stepType, stepOverrideText, numConditions = GetJournalQuestStepInfo(journalQuestIndex, stepIndex)
                        local stepInfo = {
                            Index = stepIndex,
                            IsEnding = IsJournalQuestStepEnding(journaQuestIndex, stepIndex),
                            Text = stepText,
                            Visibility = visibility,
                            Type = stepType,
                            OverrideText = overrideText,                        
                            Conditions = {}
                        }
                        _trackedQuest.Steps[stepIndex] = stepInfo
                        for conditionIndex = 1, numConditions do
                            -- quest conditions
                            local conditionValuesCurrent, conditionValuesMax, isConditionFailed, isConditionComplete, isConditionCreditShared, isConditionVisible = GetJournalQuestConditionValues(journalQuestIndex, stepIndex, conditionIndex)
                            local conditionInfo = {
                                Index = conditionIndex,
                                Current = conditionValuesCurrent,
                                Max = conditionValuesMax,
                                IsFailure = isConditionFailure,
                                IsComplete = isConditionComplete,
                                IsCreditShared = isConditionCreditShared,
                                IsVisible = isConditionVisible
                            }
                            stepInfo.Conditions[conditionIndex] = conditionInfo
                            conditionInfo.HasPosition = DoesJournalQuestConditionHavePosition(journalQuestIndex, stepIndex, conditionIndex) == true
                            if (conditionInfo.HasPosition) then
                                -- quest locations
                                -- NOTE: `EVENT_QUEST_POSITION_REQUEST_COMPLETE` serves as a continutation for this code
                                local conditionPositionTask = RequestJournalQuestConditionAssistance(journaQuestIndex, stepIndex, conditionIndex)
                                if (conditionPositionTask ~= nil) then
                                    _tasks["task:"..conditionPositionTask] = {
                                        Timestamp = ts,
                                        QuestIndex = journalQuestIndex,
                                        StepIndex = stepIndex,
                                        ConditionIndex = conditionIndex
                                    }
                                -- else
                                --     X4D.Log:Warning("RequestJournalQuestConditionAssistance returns nil", "Quest")
                                end
                            end
                        end
                    end
                end

                -- scrape WorldMap
                -- NOTE: scraping the world map is NOT ideal, we perform this only to 
                --       capture location information for quests, all other quest 
                --       information is available via API. this was previously factored
                --       out (world map scraping was the old mechanism for ALL minimap
                --       POIs) because it performs very poorly and is not necessary for
                --       all pin types. unfortunately the game is able to introduce map
                --       pins for quest states and then not provide client/ui code with 
                --       access to the position info for those states (for example, the
                --       "ENDING" state of various quests where there are no more quest
                --       conditions with which to fetch location info.)  This scraping
                --       mechanism also provides for interstitial map icons, such as 
                --       doors/rides which lead to the destination. to simulate these 
                --       ourselves we would require a proper connection graph. there is
                --       no API to provide such a connection graph.
                --
                -- TL;DR? world map scraping remains the only means to pull location info
                --       for quests.

                -- TODO: quest pip does not update when changing from interior to exterior
                --       on same map, for example, when transitioning from Daggerfall
                --       Courtyard to the Inn and back. because there is no map, location,
                --       zone change event the POIs do not update. it is not ideal to do a
                --        periodic scrape but it may be necessary.
                X4D.Log:Debug("Inspecting ZO Map Pins", "Quest")
                local zoPinCount = ZO_WorldMapContainer:GetNumChildren()
                for zoPinIndex=1,zoPinCount do
                    local zoWorldMapChild = ZO_WorldMapContainer:GetChild(zoPinIndex)
                    local zoMapPin = zoWorldMapChild.m_Pin
                    if (zoMapPin ~= nil and zoMapPin.m_PinType ~= nil) then
                        local zoQuestIndex, zoStepIndex, zoConditionIndex = zoMapPin:GetQuestData()
                        if (zoQuestIndex == _trackedQuest.Index) then
                            -- X4D.Log:Warning("Updating Quest'"..zoQuestIndex.."' with Pin'"..zoPinIndex.."'", "Quest")
                            -- NOTE: some quests have multiple objectives, and this code does not
                            --       discriminate which pin belongs to which objective. as such we
                            --       record a series of locations instead of a single location.
                            if (_trackedQuest.Locations == nil) then
                                _trackedQuest.Locations = {}
                            end
                            table.insert(_trackedQuest.Locations, {
                                Icon = zoMapPin:GetQuestIcon(),
                                X = zoMapPin.normalizedX or questInfo.X,
                                Y = zoMapPin.normalizedY or questInfo.Y
                            })
                        else
                            X4D.Log:Debug("Not Tracked for #"..zoPinIndex, "Quest")
                        end
                    else
                        X4D.Log:Debug("No Pin for #"..zoPinIndex, "Quest")
                    end
                end

            end
        end
    end
    if (not CheckTrackedQuestFullyPopulatedThenEvent()) then
        X4D.Async:Defer("X4D_Quest/TrackedQuestCheck", 250, CheckTrackedQuestFullyPopulatedThenEvent)
    end
end

function X4D_Quest:Refresh()
    X4D.Async:Defer("X4D_Quest/Refresh", 250, X4D_Quest_RefreshInternal)
end

local function OnConditionPositionRequestComplete(_, taskId, pinType, xLoc, yLoc, areaRadius, insideCurrentMapWorld, isBreadcrumb)
    local taskInfo = _tasks["task:"..taskId]
    _tasks[taskId] = nil
    if (taskInfo == nil) then
        return
    end

    -- TODO: capture location info for all quests, not just the tracked quest
    -- _quests[taskInfo.QuestIndex].Steps[taskInfo.StepIndex].Conditions[taskInfo.ConditionIndex]

    -- update tracked quest state
    if (insideCurrentMapWorld) then
        local trackedQuest = _trackedQuest
        if (trackedQuest ~= nil and taskInfo.QuestIndex == trackedQuest.Index) then
            local conditionInfo = trackedQuest.Steps[taskInfo.StepIndex].Conditions[taskInfo.ConditionIndex]
            if (conditionInfo ~= nil) then
                conditionInfo.X = xLoc
                conditionInfo.Y = yLoc
                conditionInfo.AreaRadius = areaRadius
                conditionInfo.IsBreadcrumb = isBreadcrumb
            end
            CheckTrackedQuestFullyPopulatedThenEvent()
        end
    end
end

EVENT_MANAGER:RegisterForEvent(X4D_Quest.NAME, EVENT_QUEST_POSITION_REQUEST_COMPLETE, function(...)
    X4D.Log:Debug({"EVENT_QUEST_POSITION_REQUEST_COMPLETE", ...}, X4D_Quest.NAME)
    OnConditionPositionRequestComplete(...)
end)

EVENT_MANAGER:RegisterForEvent(X4D_Quest.NAME, EVENT_QUEST_ADDED, function(...)
    X4D.Log:Debug("EVENT_QUEST_ADDED", X4D_Quest.NAME)
    X4D_Quest:Refresh()
end)
EVENT_MANAGER:RegisterForEvent(X4D_Quest.NAME, EVENT_QUEST_REMOVED, function(...)
    X4D.Log:Debug("EVENT_QUEST_REMOVED", X4D_Quest.NAME)
    X4D_Quest:Refresh()
end)
EVENT_MANAGER:RegisterForEvent(X4D_Quest.NAME, EVENT_QUEST_ADVANCED, function(...)
    X4D.Log:Debug("EVENT_QUEST_ADVANCED", X4D_Quest.NAME)
    X4D_Quest:Refresh()
end)
EVENT_MANAGER:RegisterForEvent(X4D_Quest.NAME, EVENT_QUEST_COMPLETE, function(...)
    X4D.Log:Debug("EVENT_QUEST_COMPLETE", X4D_Quest.NAME)
    X4D_Quest:Refresh()
end)
EVENT_MANAGER:RegisterForEvent(X4D_Quest.NAME, EVENT_QUEST_CONDITION_COUNTER_CHANGED, function(...)
    X4D.Log:Debug("EVENT_QUEST_CONDITION_COUNTER_CHANGED", X4D_Quest.NAME)
    X4D_Quest:Refresh()
end)
EVENT_MANAGER:RegisterForEvent(X4D_Quest.NAME, EVENT_TRACKING_UPDATE, function(...)
    X4D.Log:Debug("EVENT_TRACKING_UPDATE", X4D_Quest.NAME)
    X4D_Quest:Refresh()
end)
EVENT_MANAGER:RegisterForEvent(X4D_Quest.NAME, EVENT_ZONE_STORY_QUEST_ACTIVITY_TRACKED, function(...)
    X4D.Log:Debug("EVENT_ZONE_STORY_QUEST_ACTIVITY_TRACKED", X4D_Quest.NAME)
    X4D_Quest:Refresh()
end)
EVENT_MANAGER:RegisterForEvent(X4D_Quest.NAME, EVENT_ZONE_CHANGED, function()
	X4D.Log:Debug("EVENT_ZONE_CHANGED", X4D_Quest.NAME)
    X4D_Quest:Refresh()
end)

FOCUSED_QUEST_TRACKER:RegisterCallback("QuestTrackerTrackingStateChanged", function(...)
    X4D.Log:Debug("FOCUSED_QUEST_TRACKER::QuestTrackerTrackingStateChanged", X4D_Quest.NAME)
    X4D_Quest:Refresh()
end)

EVENT_MANAGER:RegisterForEvent(X4D_Quest.NAME, EVENT_ADD_ON_LOADED, function(eventCode, addonName)
	if (addonName ~= X4D_Quest.NAME) then
		return
	end
    X4D.Log:Debug("EVENT_ADD_ON_LOADED", X4D_Quest.NAME)
    X4D_Quest:Refresh()
end)
