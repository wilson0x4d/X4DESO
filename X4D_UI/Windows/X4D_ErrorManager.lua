local X4D_ErrorManager = LibStub:NewLibrary("X4D_ErrorManager", 1000)
if (not X4D_ErrorManager) then
    return
end
local X4D = LibStub("X4D")
X4D.ErrorManager = X4D_ErrorManager

local _errorId = 0
local _errors = {}

function PrettyPrint(errorString)
    X4D.Log:Error(errorString)
end

function OnUIError(eventCode, errorString)
    local errorId = tostring(_errorId)
    _errorId = _errorId + 1
    _errors[tostring(GetGameTimeMilliseconds()/1000) .. "-" .. errorId] = errorString
    PrettyPrint(errorString)
end

EVENT_MANAGER:RegisterForEvent("X4D_ErrorManager_OnLoaded", EVENT_ADD_ON_LOADED, function(event, name)
    if (name ~= "X4D_Core") then
        return
    end
    EVENT_MANAGER:UnregisterForEvent("ZO_UIErrors_OnEvent", EVENT_LUA_ERROR)
    EVENT_MANAGER:RegisterForEvent("ZO_UIErrors_OnEvent", EVENT_LUA_ERROR, OnUIError)
end)
