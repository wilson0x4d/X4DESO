local X4D_Mail = LibStub:NewLibrary('X4D_Mail', 1000)
if (not X4D_Mail) then
	return
end

X4D_Mail.NAME = 'X4D_Mail'
X4D_Mail.VERSION = '1.0'

local X4D = LibStub('X4D')

local function OnOpenMailbox(eventCode, ...)
	X4D.Debug:SetTraceLevel(X4D.Debug.TRACE_LEVELS.VERBOSE)
	X4D.Debug:Verbose({eventCode, ...}, 'X4D_Mail OnOpenMailbox')
end

local function Register()
	EVENT_MANAGER:RegisterForEvent(X4D_Mail.NAME, EVENT_MAIL_OPEN_MAILBOX, OnOpenMailbox)
end

local function Unregister()
end

local function OnAddOnLoaded(event, addonName)
	if (addonName ~= X4D_Mail.NAME) then
		return
	end	

	X4D_Mail.Options = X4D.Options:Create(
		X4D_Mail.NAME .. '_SV',
		{
			AutoAcceptAttachments = true,
			AutoDeleteSpamMail = true,
		})
	
	Register()
end

local function OnPlayerActivated()
end

EVENT_MANAGER:RegisterForEvent(X4D_Mail.NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(X4D_Mail.NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)


