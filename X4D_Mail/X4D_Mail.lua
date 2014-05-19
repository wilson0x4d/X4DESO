local X4D_Mail = LibStub:NewLibrary('X4D_Mail', 1000)
if (not X4D_Mail) then
	return
end

X4D_Mail.NAME = 'X4D_Mail'
X4D_Mail.VERSION = '1.0'

-- 1.0
-- X4D_Mail:IsMailReadable(mailId)
-- X4D_Mail:HandleMailAttachments(mailId)
-- X4D_Mail:HandleSpam(mailId)

local X4D = LibStub('X4D')
local X4D_Loot = LibStub('X4D_Loot')
local X4D_LibAntiSpam = LibStub('LibAntiSpam', true)

local function DefaultEmitCallback(color, text)
	X4D.Debug.Info(color .. text, 'X4D Mail')
end 

local _emitCallback = DefaultEmitCallback

function X4D_Mail:RegisterEmitCallback(callback)
	if (callback ~= nil) then
		_emitCallback = callback
	else
		_emitCallback = DefaultEmitCallback
	end
end

function X4D_Mail:UnregisterEmitCallback(callback)
	if (_emitCallback == callback) then
		self:RegisterEmitCallback(nil)
	end
end

local function InvokeEmitCallbackSafe(color, text)
	local callback = _emitCallback
	if (color == nil) then
		color = '|cFF0000'
	end
	if (color:len() < 8) then
		color = '|cFF0000'
	end
	if (callback ~= nil) then	
		callback(color, text)
	end
end

local function CreateIcon(filename, width, height)	
	return string.format('|t%u:%u:%s|t', width or 16, height or 16, filename)
end

local function formatnum(n)
	local left, num, right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left .. (num:reverse():gsub('(%d%d%d)','%1,'):reverse()) .. right
end

local _readableMail = { }

function X4D_Mail:IsMailReadable(mailId)
	return _readableMail[mailId] ~= nil
end

function X4D_Mail:HandleMailAttachments(mailId)
	if (not X4D_Mail:IsMailReadable(mailId)) then
		X4D.Debug:Error({ 'HandleMailAttachments', '!IsMailReadable', mailId }, 'X4D Mail');
		return
	end
	local mail = _readableMail[mailId];
	if (mail.IsReturnedMail and X4D_Mail.Options:GetOption('LeaveReturnedMailAlone')) then
		return
	end
	if (X4D_Mail.Options:GetOption('AutoAcceptAttachments')) then
		if (mail.IsFromSystem and (not mail.IsCustomerService)) then
			if (mail.AttachedItemsCount > 0 or mail.AttachedMoney > 0) then
				if (mail.AttachedItemsCount > 0) then
					for attachmentIndex = 1, mail.AttachedItemsCount do
						local itemIcon, stackCount, creatorName = GetAttachedItemInfo(mailId, attachmentIndex)
						local itemLink = GetAttachedItemLink(mailId, attachmentIndex, LINK_STYLE_BRACKETS)
						local itemColor = X4D.Colors:ExtractLinkColor(itemLink)
						InvokeEmitCallbackSafe(itemColor, 'Accepted ' .. CreateIcon(itemIcon) .. itemLink .. ' x' .. stackCount .. ' from ' .. mail.SenderDisplayName);
					end
					TakeMailAttachedItems(mailId)
				end
				if (mail.AttachedMoney > 0) then
					if (X4D_Loot == nil) then
						local newMoney = GetCurrentMoney() + mail.AttachedMoney
						InvokeEmitCallbackSafe(X4D.Colors.Gold, string.format('%s %s%s %s  (%s total)', 'Accepted', formatnum(mail.AttachedMoney), CreateIcon('EsoUI/Art/currency/currency_gold.dds'), X4D.Colors.Subtext, formatnum(newMoney)))
					end				
					TakeMailAttachedMoney(mailId)
				end
				if (X4D_Mail.Options:GetOption('AutoDeleteMail')) then
					X4D.Debug.Verbose('Deleting mail from: ' .. mail.SenderDisplayName, 'X4D Mail')
					DeleteMail(mailId, false)
				end
			end
		end
	end
end

function X4D_Mail:HandleSpam(mailId)
	if (not X4D_Mail:IsMailReadable(mailId)) then
		X4D.Debug:Error({ 'HandleSpam', '!IsMailReadable', mailId }, 'X4D Mail');
		return
	end
	local mail = _readableMail[mailId];
	if (X4D_Mail.Options:GetOption('EnableAntiSpam')) then
		if (not mail.IsCustomerService) then
			if (X4D_LibAntiSpam ~= nil) then
				local isSpam = X4D_LibAntiSpam:Check({
						Text = mail.SubjectText .. ' ' .. mail.BodyText,
						Name = mail.SenderDisplayName,
						Reason = 'Mail',
						NoFlood = true, -- we do not want mail to result in flood triggering
					})
				if (isSpam) then
					mail.IsSpam = true
					X4D.Debug.Verbose('Deleting mail from spammer: ' .. mail.SenderDisplayName, 'X4D Mail')
					DeleteMail(mailId, false)
				end
			end
		end	
	end
	return mail.IsSpam
end

local function OnMailReadable(eventCode, mailId)
	local senderDisplayName, senderCharacterName, subjectText, mailIcon, unread, fromSystem, fromCustomerService, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived = GetMailItemInfo(mailId)
	local bodyText = ReadMail(mailId)
	local mail = {
		MailId = mailId,
		MailIcon = mailIcon,
		SubjectText = subjectText,
		BodyText = bodyText,
		IsUnread = unread,
		IsFromSystem = fromSystem,
		SenderDisplayName = senderDisplayName,
		SenderCharacterName = senderCharacterName,		
		IsCustomerService = fromCustomerService,
		IsReturnedMail = returned, 
		AttachedItemsCount = numAttachments, 
		AttachedMoney = attachedMoney, 
		CODAmount = codAmount, 
		ExpiresInDays = expiresInDays, 
		SecsSinceReceived = secsSinceReceived,
		IsSpam = false,
	}
	_readableMail[mailId] = mail
	X4D_Mail:HandleMailAttachments(mailId)
	X4D_Mail:HandleSpam(mailId)
end

local function OnOpenMailbox(eventCode)
	local mailId = GetNextMailId()
	while (mailId ~= nil) do
		RequestReadMail(mailId)
		mailId = GetNextMailId(mailId)
	end
end

local function Register()
	
	-- TODO: comment this out when not testing changes
	X4D.Debug:SetTraceLevel(X4D.Debug.TRACE_LEVELS.VERBOSE)

	EVENT_MANAGER:RegisterForEvent(X4D_Mail.NAME, EVENT_MAIL_OPEN_MAILBOX, OnOpenMailbox)
    EVENT_MANAGER:RegisterForEvent(X4D_Mail.NAME, EVENT_MAIL_READABLE, OnMailReadable)
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
			AutoDeleteMail = true,
			EnableAntiSpam = true,
			LeaveReturnedMailAlone = true,
		})

	Register()
end

local function OnPlayerActivated()
end

-- esoui fix: prevent nil reference error for deleted mail after taking gold attachements
function MAIL_INBOX:RefreshMoneyControls()
    local mailData = self:GetMailData(self.mailId)
    self.sentMoneyControl:SetHidden(true)
    self.codControl:SetHidden(true)
    if (mailData ~= nil) then
	    if(mailData.attachedMoney > 0) then
	        self.sentMoneyControl:SetHidden(false)
	        ZO_CurrencyControl_SetSimpleCurrency(GetControl(self.sentMoneyControl, "Currency"), CURRENCY_TYPE_MONEY, mailData.attachedMoney, MAIL_COD_ATTACHED_MONEY_OPTIONS)
	    elseif(mailData.codAmount > 0) then
	        self.codControl:SetHidden(false)
	        ZO_CurrencyControl_SetSimpleCurrency(GetControl(self.codControl, "Currency"), CURRENCY_TYPE_MONEY, mailData.codAmount, MAIL_COD_ATTACHED_MONEY_OPTIONS)
	    end
	end
end

EVENT_MANAGER:RegisterForEvent(X4D_Mail.NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(X4D_Mail.NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
