local X4D = LibStub:NewLibrary("X4D", 1015)
if (not X4D) then
    return
end

X4D.NAME = "X4D"
X4D.VERSION = "1.15"

local _mm

EVENT_MANAGER:RegisterForEvent("X4D_Core", EVENT_ADD_ON_LOADED, function(event, name)
    if (name ~= "X4D_Core") then
        return
    end

    local stopwatch = X4D.Stopwatch:StartNew()
    X4D.InternalSettings = X4D.Settings(
        "X4D_Core_SV",
        {
            SettingsAre = "Account-Wide",
            X4DB = nil,
        }, 
        5)

    if (_mm == nil) then
        local _lastCount = 0
        _mm = X4D.Async:CreateTimer(function (timer, state)
            local garbageCount = math.ceil(collectgarbage("count") * 1024)
            local countColor = ""
            if (garbageCount < _lastCount) then
                countColor = "|c11AA11"
            elseif (garbageCount > _lastCount) then
                countColor = "|cAA1111"
            end
            X4D.Log:Debug({
                "Memory: " .. countColor .. tostring(math.ceil(collectgarbage("count") * 1024)) .. X4D.Colors.TRACE_DEBUG,
                "Timers: " .. X4D.Async.ActiveTimers:Count(),
                }, "DBG")
            _lastCount = garbageCount
        end):Start(5000,{},"X4D_Core::DEBUG")
    end
    X4D.Took = stopwatch.ElapsedMilliseconds()
end)

--[[

We need something like "ZO_CallbackObject" where a event handler registry can be defined for any
event handler and also be easily extended/modified by multiple Add-Ons.

]]

function X4D:Test()
    d("Begin Test of X4D Framework..")

    local stopwatch = X4D.Stopwatch:StartNew()
    X4D.Log:SetTraceLevel(X4D.Log.TRACE_LEVELS.VERBOSE)

    -- Debug API
    --X4D.Log:Verbose("Test Verbose")
    --X4D.Log:Information("Test Information")
    --X4D.Log:Warning("Test Warning")
    --X4D.Log:Error({ ["TEST"] = { ["ERROR"] = "yes" } })
	--X4D.Log:Critical({ [{ ["CRITICAL"] = "yes" }] = "TEST"})

    -- Conversion API
    local channelRoundTrip = X4D.Convert:CategoryToChannel(X4D.Convert:ChannelToCategory(CHAT_CHANNEL_OFFICER_1))
    X4D.Log:Verbose(CHAT_CHANNEL_OFFICER_1 == channelRoundTrip, 'CONVERT')

    -- Async API
    local callback1 = function(timer, state)
        state.counter = state.counter + 1
        X4D.Log:Verbose("count=" .. state.counter .. " time=" .. GetGameTimeMilliseconds(), "TIMER#1@107ms")
        if (state.counter >= 4) then
            timer:Stop()
            stopwatch:Stop()
            X4D.Log:Information("Test() took " .. stopwatch.ElapsedMilliseconds() .. "ms")
        end
    end
    local callback2 = function(timer, state)
        state.counter = state.counter + 1
        X4D.Log:Verbose("count=" .. state.counter .. " time=" .. GetGameTimeMilliseconds(), "TIMER#2@47ms")
        if (state.counter >= 4) then
            timer:Stop()
        end
    end
    local asyncTimer1 = X4D.Async:CreateTimer(callback1, 107, { counter = 0 }):Start(nil,nil,"X4D_Core::Test")
    local asyncTimer2 = X4D.Async:CreateTimer(callback2, 47, { counter = 0 }):Start(nil,nil,"X4D_Core::Test")

    -- SavedVars API
    -- DB API (indirectly also verifies "Settings API")
    local nonPersistentDb = X4D.DB:Create()
    nonPersistentDb:Add({
        Id = ITEMTYPE_NONE,
        Canonical = "ITEMTYPE_NONE",
        Name = "Unspecified",
        Tooltip = nil,
        Group = "Misc"
    })
    -- verify conventions
    nonPersistentDb:Add({
        Key = "SupportsConventions",
        Value = true,
    })
    nonPersistentDb:Add({
        id = "SupportsConventions",
        Value = true,
    })
    nonPersistentDb:Add({
        Id = "SupportsConventions",
        Value = true,
    })
    nonPersistentDb:Add({
        ID = "SupportsConventions",
        Value = true,
    })

    -- NOTE: to verify, /reloadui or quit game and check file on disk
    local persistentDb = X4D.DB:Open(".x4d")
    persistentDb:Add({
        Key = "X4D_TEST_RESULT",
        Value = "SUCCESS",
    })

    -- Items API
    -- Guilds API
    -- Players API

    -- Vendors API

    -- Observable
    local observable = X4D.Observable("World!")
    observable:Observe(function (newVal, oldVal)
        if (newVal == oldVal) then
            X4D.Log:Error("TEST FAILURE: do not re-notify observers if the value is not changing")
        end
        X4D.Log:Verbose{"ObservableBVT", newVal, oldVal}
    end)
    observable("Hello")
    observable("Hello")
    X4D.Log:Verbose{"End"}

    return self
end

--region Garbage Collection

X4D.OOM = 64

local _oomCount = 0
local _previousGarbageIdle, _previousGarbageStepMul = 100, 150
collectgarbage('setpause', _previousGarbageIdle)
collectgarbage('setstepmul', _previousGarbageStepMul)

EVENT_MANAGER:UnregisterForEvent("ZO_UIErrors_OnEvent", EVENT_LUA_LOW_MEMORY)
EVENT_MANAGER:RegisterForEvent("X4D_Core_OOM", EVENT_LUA_LOW_MEMORY, function()
    X4D.OOM = math.ceil((collectgarbage("count") / 1024) * 1.164)
    _oomCount = _oomCount + 1
    -- log to chat, including how much memory is in use
    local before = collectgarbage("count")
    collectgarbage("collect")
    if (_oomCount % 5 == 0) then        
        local after = collectgarbage("count")
        local message = GetString(SI_LUA_LOW_MEMORY) .. "\nLua memory usage before " .. (math.ceil(before / 1024)) .. "MB, after " .. (math.ceil(after / 1024)) .. "MB. Total reclaimed " .. (math.ceil((before - after) / 1024)) .. "MB)"
        X4D.Log:Warning(message, "X4D")
    end
    -- dynamically adjust gc configuration under the assumption that the default config is not aggressive enough to handle the user's current addons
    _previousGarbageIdle = _previousGarbageIdle - 15
    if (_previousGarbageIdle < 85) then
        _previousGarbageIdle = 85
    end
    _previousGarbageStepMul = _previousGarbageStepMul + 25
    if (_previousGarbageStepMul > 200) then
        _previousGarbageStepMul = 200
    end
    collectgarbage('setpause', _previousGarbageIdle)
    collectgarbage('setstepmul', _previousGarbageStepMul)
    X4D.Log:Warning(message)
end)

--endregion

local function ReportVersions()
    -- TODO: iterate 'X4D' instead looking for 'NAME" and 'VERSION' properties (instead of manually updating)
    local versions = "Core/" .. X4D.VERSION .. " "
    if (X4D.Bank ~= nil) then
        versions = versions .. "Bank/" .. X4D.Bank.VERSION .. " "
    end
    if (X4D.Chat ~= nil) then
        versions = versions .. "Chat/" .. X4D.Chat.VERSION .. " "
    end
    if (X4D.AntiSpam ~= nil) then
        versions = versions .. "AntiSpam/" .. X4D.AntiSpam.VERSION .. " "
    end
    if (X4D.Loot ~= nil) then
        versions = versions .. "Loot/" .. X4D.Loot.VERSION .. " "
    end
    if (X4D.Mail ~= nil) then
        versions = versions .. "Mail/" .. X4D.Mail.VERSION .. " "
    end
    if (X4D.Vendors ~= nil) then
        versions = versions .. "Vendors/" .. X4D.Vendors.VERSION .. " "
    end
    if (X4D.XP ~= nil) then
        versions = versions .. "XP/" .. X4D.XP.VERSION .. " "
    end
    if (X4D.UI ~= nil) then
        versions = versions .. "UI/" .. X4D.UI.VERSION .. " "
    end
    X4D.Log:Warning(versions, "X4D")
end

local function ReportLoadTimes()
    -- TODO: iterate 'X4D' instead looking for 'NAME" and 'VERSION' properties (instead of manually updating)
    local loadTimes = "Core/" .. X4D.Took .. "ms "
    if (X4D.Bank ~= nil) then
        loadTimes = loadTimes .. "Bank/" .. X4D.Bank.Took .. "ms "
    end
    if (X4D.Chat ~= nil) then
        loadTimes = loadTimes .. "Chat/" .. X4D.Chat.Took .. "ms "
    end
    if (X4D.AntiSpam ~= nil) then
        loadTimes = loadTimes .. "AntiSpam/" .. X4D.AntiSpam.Took .. "ms "
    end
    if (X4D.Loot ~= nil) then
        loadTimes = loadTimes .. "Loot/" .. X4D.Loot.Took .. "ms "
    end
    if (X4D.Mail ~= nil) then
        loadTimes = loadTimes .. "Mail/" .. X4D.Mail.Took .. "ms "
    end
    if (X4D.Vendors ~= nil) then
        loadTimes = loadTimes .. "Vendors/" .. X4D.Vendors.Took .. "ms "
    end
    if (X4D.XP ~= nil) then
        loadTimes = loadTimes .. "XP/" .. X4D.XP.Took .. "ms "
    end
    if (X4D.UI ~= nil) then
        loadTimes = loadTimes .. "UI/" .. X4D.UI.Took .. "ms "
    end
    X4D.Log:Warning(loadTimes, "X4D")
end


SLASH_COMMANDS["/x4d"] = function (parameters, other)
    ReportVersions()
    ReportLoadTimes()
    if (parameters ~= nil and parameters:len() > 0) then
        X4D.Log:Information("Parameters: " .. parameters, "X4D")
    end
    if (parameters == "-debug") then
        X4D.Log:SetTraceLevel(X4D.Log.TRACE_LEVELS.DEBUG)
        if (Zgoo ~= nil) then
            Zgoo:Main(nil,1,X4D)
        end
    end
    if (parameters == "-test") then
        X4D.Test()
        return
    end

    if (X4D.UI ~= nil) then
        X4D.UI:View("X4D_About")
    end
end
