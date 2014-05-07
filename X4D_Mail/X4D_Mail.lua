local X4D_Mail = LibStub:NewLibrary('X4D_Mail', 1000)
if (not X4D_Mail) then
	return
end

X4D_Mail.NAME = 'X4D_Mail'
X4D_Mail.VERSION = '1.0'

local X4D = LibStub('X4D')
local X4D_Loot = LibStub('X4D_Loot')
local X4D_LibAntiSpam = LibStub('LibAntiSpam')

local function DefaultEmitCallback(color, text)
	d(color .. text)
end 

local _emitCallback = DefaultEmitCallback

function X4D_Mail.RegisterEmitCallback(self, callback)
	if (callback ~= nil) then
		_emitCallback = callback
	else
		_emitCallback = DefaultEmitCallback
	end
end

function X4D_Mail.UnregisterEmitCallback(self, callback)
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
	-- example: /zgoo EsoStrings[SI_BANK_GOLD_AMOUNT_BANKED]:gsub('%|', '!')
	-- gladly accepting gold donations in-game, thanks.
	return string.format('|t%u:%u:%s|t', width or 16, height or 16, filename)
end

local function formatnum(n)
	local left, num, right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left .. (num:reverse():gsub('(%d%d%d)','%1,'):reverse()) .. right
end

local function OnMailReadable(eventCode, mailId)
	local senderDisplayName, senderCharacterName, subjectText, mailIcon, unread, fromSystem, fromCustomerService, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived = GetMailItemInfo(mailId)		
	local body = ReadMail(mailId)		
	if (fromSystem and (not fromCustomerService)) then
		if (X4D_Mail.Options.GetOption('AutoAcceptAttachments')) then
			if (numAttachments > 0 or attachedMoney > 0) then
				if (numAttachments > 0) then
					for attachmentIndex = 1, numAttachments do
						local itemIcon, stackCount, creatorName = GetAttachedItemInfo(mailId, attachmentIndex)
						local itemLink = GetAttachedItemLink(mailId, attachmentIndex, LINK_STYLE_BRACKETS)
						local itemColor = X4D.Colors:ExtractLinkColor(itemLink)
						InvokeEmitCallbackSafe(itemColor, 'Accepted ' .. CreateIcon(itemIcon) .. itemLink .. ' x' .. stackCount);
					end
					TakeMailAttachedItems(mailId)
				end
				if (attachedMoney > 0) then
					if (X4D_Loot == nil) then
						local newMoney = GetCurrentMoney() + attachedMoney
						InvokeEmitCallbackSafe(X4D.Colors.Gold, string.format('%s %s%s %s  (%s total)', 'Accepted', formatnum(attachedMoney), CreateIcon('EsoUI/Art/currency/currency_gold.dds'), X4D.Colors.Subtext, formatnum(newMoney)))
					end				
					TakeMailAttachedMoney(mailId)
				end
				if (X4D_Mail.Options.GetOption('AutoDeleteMail')) then
					DeleteMail(mailId, false)
				end
			end
		end
	elseif ((not fromCustomerService) and (X4D_LibAntiSpam ~= nil)) then
		local isSpam, isFlood = X4D_LibAntiSpam:Check(subjectText .. ' ' .. body, senderDisplayName)
		if (isSpam) then
			if (X4D_Mail.Options.GetOption('AutoDeleteMail')) then
				DeleteMail(mailId, false)
			end
		end
	end	
end

local function OnOpenMailbox(eventCode)
	--X4D.Debug:Verbose({'OnOpenMailbox', eventCode, ...}, 'X4D_Mail')
	--local hasUnreadMail = HasUnreadMail()
	--if (not hasUnreadMail) then
	--	return
	--end
	local mailId = GetNextMailId()
	while (mailId ~= nil) do
		RequestReadMail(mailId)
		mailId = GetNextMailId(mailId)
	end
end

local function Register()
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


