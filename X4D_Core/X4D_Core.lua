local X4D = LibStub:NewLibrary('X4D', 1.0);
if (not X4D) then	
	return;
end
X4D.NAME = 'X4D';
X4D.VERSION = 1.0;
X4D.Colors = LibStub('X4D_Colors');
X4D.Debug = LibStub('X4D_Debug');
X4D.Convert = LibStub('X4D_Convert');
X4D.SavedVars = LibStub('X4D_SavedVars');
X4D.Async = LibStub('X4D_Async');
X4D.Items = LibStub('X4D_Items');
X4D.Guilds = LibStub('X4D_Guilds');
X4D.Players = LibStub('X4D_Players');
X4D.Options = LibStub('X4D_Options');
if (X4D.Options) then
	X4D.Options:Extend();
end

--[[

We need something like 'ZO_CallbackObject' where a event handler registry can be defined for any
event handler and also be easily extended/modified by multiple Add-Ons.

]]

_G['test_X4D'] = function()
	d('Begin Test of X4D Framework..');
	
	X4D.Debug:SetTraceLevel(X4D.Debug.TRACE_LEVELS.VERBOSE);

	-- Debug API
	X4D.Debug:Verbose('X4D.Debug.Verbose', "DEBUG");
	X4D.Debug:Information('X4D.Debug.Information', "DEBUG");
	X4D.Debug:Warning('X4D.Debug.Warning', "DEBUG");
	X4D.Debug:Error('X4D.Debug.Error', "DEBUG");
	X4D.Debug:Critical('X4D.Debug.Critical', "DEBUG");

	-- Conversion API
	local channelRoundTrip = X4D.Convert:CategoryToChannel(X4D.Convert:ChannelToCategory(CHAT_CHANNEL_OFFICER_1));
	X4D.Debug:Verbose(CHAT_CHANNEL_OFFICER_1 == channelRoundTrip, "CONVERT");

	-- Async API
	local callback = function(timer, state)
		state.counter = state.counter + 1;
		X4D.Debug:Verbose('count=' .. state.counter .. ' time=' .. GetGameTimeMilliseconds(), 'ASYNC');
		if (state.counter >= 10) then
			timer:Stop();
			d('End Test of X4D Framework.');
		end
	end	
	X4D_Timer:New(callback, 100, { counter = 0 }):Start();

	-- SavedVars API

	-- Items API
	-- Guilds API
	-- Players API

	-- LibAddonMenu Extensions

end