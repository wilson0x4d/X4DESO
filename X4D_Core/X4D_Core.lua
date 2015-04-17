local X4D = LibStub:NewLibrary('X4D', 1001)
if (not X4D) then
    return
end

X4D.NAME = 'X4D'
X4D.VERSION = '1.1'

EVENT_MANAGER:RegisterForEvent('X4D_Core', EVENT_ADD_ON_LOADED, function(event, name)

end)

--[[

We need something like 'ZO_CallbackObject' where a event handler registry can be defined for any
event handler and also be easily extended/modified by multiple Add-Ons.

]]

X4D.Test = function()
    d('Begin Test of X4D Framework..')

    X4D.Debug:SetTraceLevel(X4D.Debug.TRACE_LEVELS.VERBOSE)

    -- Debug API
    X4D.Debug:Verbose('Test Verbose')
    X4D.Debug:Information('Test Information')
    X4D.Debug:Warning('Test Warning')
    X4D.Debug:Error({ ['TEST'] = { ['ERROR'] = 'yes' } })
	X4D.Debug:Critical({ [{ ['CRITICAL'] = 'yes' }] = 'TEST'})

    -- Conversion API
    local channelRoundTrip = X4D.Convert:CategoryToChannel(X4D.Convert:ChannelToCategory(CHAT_CHANNEL_OFFICER_1))
    X4D.Debug:Verbose(CHAT_CHANNEL_OFFICER_1 == channelRoundTrip, "CONVERT")

    -- Async API
    local callback1 = function(timer, state)
        state.counter = state.counter + 1
        X4D.Debug:Verbose('count=' .. state.counter .. ' time=' .. GetGameTimeMilliseconds(), 'TIMER#1@107ms')
        if (state.counter >= 4) then
            timer:Stop()
        end
    end
    local callback2 = function(timer, state)
        state.counter = state.counter + 1
        X4D.Debug:Verbose('count=' .. state.counter .. ' time=' .. GetGameTimeMilliseconds(), 'TIMER#2@47ms')
        if (state.counter >= 4) then
            timer:Stop()
        end
    end
    local asyncTimer1 = X4D.Async.CreateTimer(callback1, 107, { counter = 0 }):Start()
    local asyncTimer2 = X4D.Async.CreateTimer(callback2, 47, { counter = 0 }):Start()

    -- SavedVars API

    -- Items API
    -- Guilds API
    -- Players API

    -- LibAddonMenu Extensions

    --    X4D.Async.CreateTimer(function(timer)
    --        timer:Stop()
    --        X4D.Debug:Verbose('Display Money Updates: Loot=' .. tostring(X4D.Loot.Options:GetOption('DisplayMoneyUpdates')) .. ' Bank=' .. tostring(X4D.Bank.Options:GetOption('DisplayMoneyUpdates')))
    --    end, 1200, {}):Start()
end

local _oneTimeVersionReport = false

EVENT_MANAGER:RegisterForEvent(X4D.NAME, EVENT_PLAYER_ACTIVATED,
    function()
        if (name == 'X4D_Core') then
            X4D.Options:Create(
                X4D_Core.NAME .. '_SV',
                {
                    SettingsAre = 'Account-Wide',
                    _DB = { },
                })
            if (_oneTimeVersionReport) then
                return
            end
            _oneTimeVersionReport = true
            X4D.Async.CreateTimer(
            function(timer, state)
                timer:Stop()
                local versions = 'Core/' .. X4D.VERSION .. ' '
                if (X4D.Bank ~= nil) then
                    versions = versions .. 'Bank/' .. X4D.Bank.VERSION .. ' '
                end
                if (X4D.Chat ~= nil) then
                    versions = versions .. 'Chat/' .. X4D.Chat.VERSION .. ' '
                end
                if (X4D.AntiSpam ~= nil) then
                    versions = versions .. 'AntiSpam/' .. X4D.AntiSpam.VERSION .. ' '
                end
                if (X4D.Loot ~= nil) then
                    versions = versions .. 'Loot/' .. X4D.Loot.VERSION .. ' '
                end
                if (X4D.Mail ~= nil) then
                    versions = versions .. 'Mail/' .. X4D.Mail.VERSION .. ' '
                end
                if (X4D.XP ~= nil) then
                    versions = versions .. 'XP/' .. X4D.XP.VERSION .. ' '
                end
                X4D.Debug:SetTraceLevel(X4D.Debug.TRACE_LEVELS.INFORMATION)
                X4D.Debug:Verbose(versions, 'X4D')
            end, 1977, {}):Start()
        end
    end)
