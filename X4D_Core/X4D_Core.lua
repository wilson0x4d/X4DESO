local X4D = LibStub:NewLibrary('X4D', 1001)
if (not X4D) then	
	return
end
X4D.NAME = 'X4D'
X4D.VERSION = '1.0'
X4D.Colors = LibStub('X4D_Colors')
X4D.Debug = LibStub('X4D_Debug')
X4D.Convert = LibStub('X4D_Convert')
X4D.Async = LibStub('X4D_Async')
X4D.Items = LibStub('X4D_Items')
X4D.Guilds = LibStub('X4D_Guilds')
X4D.Players = LibStub('X4D_Players')
X4D.Options = LibStub('X4D_Options')

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

end

EVENT_MANAGER:RegisterForEvent(X4D.NAME, EVENT_PLAYER_ACTIVATED, 
    function()
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
	            X4D.Debug:Information(versions, 'X4D')
            end, 1000, {}):Start()
    end)

