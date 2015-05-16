local X4D_UI = LibStub:NewLibrary("X4D_UI", 1001)
if (not X4D_UI) then
	return
end
local X4D = LibStub("X4D")
X4D.UI = X4D_UI

X4D_UI.NAME = "X4D_UI"
X4D_UI.VERSION = "1.1"

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
