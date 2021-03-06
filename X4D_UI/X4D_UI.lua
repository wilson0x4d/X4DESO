local X4D_UI = LibStub:NewLibrary("X4D_UI", "0#VERSION#")
if (not X4D_UI) then
	return
end
local X4D = LibStub("X4D")
X4D.UI = X4D_UI

X4D_UI.NAME = "X4D_UI"
X4D_UI.VERSION = "#VERSION#"

X4D.UI.SceneManager = SCENE_MANAGER
X4D.UI.CurrentScene = X4D.Observable(nil)

function X4D_UI:View(name)
    
end

X4D.UI.SceneManager:RegisterCallback("SceneStateChanged", function(scene, oldState, newState)
    if ((newState == SCENE_HIDING) or (newState == SCENE_HIDDEN)) then
        --X4D.Log:Verbose({"SceneStateChanged->Shown", scene:GetName()}, "UI")
    elseif (scene == nil) then
        --X4D.Log:Verbose({"scene==nil"}, "UI")
    else
        --X4D.Log:Verbose({"SceneStateChanged->Shown", scene:GetName()}, "UI")
        X4D.UI.CurrentScene(scene)
    end
end)

EVENT_MANAGER:RegisterForEvent(X4D_UI.NAME, EVENT_ADD_ON_LOADED, function(eventCode, addonName)
    if (addonName ~= X4D_UI.NAME) then
        return
    end
    X4D.Log:Debug({"OnAddonLoaded", eventCode, addonName}, X4D_UI.NAME)
    local stopwatch = X4D.Stopwatch:StartNew()
	X4D_UI.Settings = X4D.Settings:Open(
		X4D_UI.NAME .. "_SV",
		{
            SettingsAre = "Account-Wide",
            ShowFPS = true,
            ShowPing = true,
            ShowMemory = true,
        })
    X4D_UI.Took = stopwatch.ElapsedMilliseconds()
end)

SLASH_COMMANDS["/fps"] = function (parameters, other)
    X4D_UI.Settings:Set("ShowFPS", not X4D_UI.Settings:Get("ShowFPS"))
end
SLASH_COMMANDS["/latency"] = function (parameters, other)
    X4D_UI.Settings:Set("ShowPing", not X4D_UI.Settings:Get("ShowPing"))
end
SLASH_COMMANDS["/ping"] = function (parameters, other)
    X4D_UI.Settings:Set("ShowPing", not X4D_UI.Settings:Get("ShowPing"))
end
SLASH_COMMANDS["/mem"] = function (parameters, other)
    X4D_UI.Settings:Set("ShowMemory", not X4D_UI.Settings:Get("ShowMemory"))
end
