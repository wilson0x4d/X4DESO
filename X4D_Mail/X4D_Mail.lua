local X4D_Mail = LibStub:NewLibrary("X4D_Mail", "0#VERSION#")
if (not X4D_Mail) then
	return
end
local X4D = LibStub("X4D")
X4D.Mail = X4D_Mail

X4D_Mail.NAME = "X4D_Mail"
X4D_Mail.VERSION = "#VERSION#"

-- 1.0
-- X4D_Mail:IsMailReadable(mailId)
-- X4D_Mail:HandleMailAttachments(mailId)
-- X4D_Mail:HandleSpam(mailId)

if (X4D.AntiSpam == nil) then
	X4D.Log:Warning("No usable AntiSpam Library was detected.", "X4D Mail")
end

local function DefaultChatCallback(color, text)
	X4D.Log:Info(color .. text, "X4D Mail")
end 

local _chatCallback = DefaultChatCallback

function X4D_Mail:RegisterChatCallback(callback)
	if (callback ~= nil) then
		_chatCallback = callback
	else
		_chatCallback = DefaultChatCallback
	end
end

function X4D_Mail:UnregisterChatCallback(callback)
	if (_chatCallback == callback) then
		self:RegisterChatCallback(nil)
	end
end

local function InvokeChatCallback(color, text)
	local callback = _chatCallback
	if (color == nil) then
		color = "|cFF0000"
	end
	if (color:len() < 8) then
		color = "|cFF0000"
	end
	if (callback ~= nil) then	
		callback(color, text)
	end
end

local function formatnum(n)
	local left, num, right = string.match(n,"^([^%d]*%d)(%d*)(.-)$")
	return left .. (num:reverse():gsub("(%d%d%d)","%1,"):reverse()) .. right
end

local _readableMail = { }

function X4D_Mail:IsMailReadable(mailId)
	return _readableMail[mailId] ~= nil
end

function X4D_Mail:HandleMailAttachments(mailId)
	if (not X4D_Mail:IsMailReadable(mailId)) then
		--X4D.Log:Verbose({ "HandleMailAttachments", "!IsMailReadable", mailId }, "X4D Mail")
		return
	end
	local mail = _readableMail[mailId]
	if (mail.IsReturnedMail and X4D_Mail.Settings:Get("LeaveReturnedMailAlone")) then
		--X4D.Log:Verbose({ "HandleMailAttachments", "IsReturnedMail and LeaveReturnedMailAlone", mailId }, "X4D Mail")
		return
	end
	local shouldDelete = false
	if (X4D_Mail.Settings:Get("AutoAcceptAttachments")) then
		--X4D.Log:Verbose({ "HandleMailAttachments", "AutoAcceptAttachments", mailId }, "X4D Mail")
		if (mail.IsFromSystem and (not mail.IsCustomerService)) then
			shouldDelete = true
			if (mail.AttachedItemsCount > 0 or mail.AttachedMoney > 0) then
				if (mail.AttachedItemsCount > 0) then
					if (CheckInventorySpaceSilently(mail.AttachedItemsCount)) then
						for attachmentIndex = 1, mail.AttachedItemsCount do
							local itemIcon, stackCount, creatorName = GetAttachedItemInfo(mailId, attachmentIndex)
							local itemLink = GetAttachedItemLink(mailId, attachmentIndex, LINK_STYLE_BRACKETS)
                            -- TODO: X4D.Items:FromLink(item)
							local itemColor = X4D.Colors:ExtractLinkColor(itemLink)
                            local message = zo_strformat("<<1>> <<2>><<t:3>> <<4>>x<<5>> from <<6>>",
                                "Accepted", X4D.Icons:CreateString(itemIcon), itemLink, X4D.Colors.StackCount, stackCount, mail.SenderDisplayName)
			                InvokeChatCallback(itemColor, message)
						end
						TakeMailAttachedItems(mailId)
					else
						shouldDelete = false
						InvokeChatCallback("|cFFFFFF", "Could not accept Attachments from " .. mail.SenderDisplayName .. ", not enough bag space.")
					end
				end
				if (mail.AttachedMoney > 0) then
					if (X4D.Loot == nil) then
						local newMoney = GetCurrentMoney() + mail.AttachedMoney
						InvokeChatCallback(X4D.Colors.Gold, string.format("%s %s%s %s  (%s total)", "Accepted", formatnum(mail.AttachedMoney), X4D.Icons:CreateString("EsoUI/Art/currency/currency_gold.dds"), X4D.Colors.Subtext, formatnum(newMoney)))
					end				
					TakeMailAttachedMoney(mailId)
				end
			end
		end
	end
    if (shouldDelete and X4D_Mail.Settings:Get("AutoDeleteMail")) then
	    X4D.Log:Verbose("Deleting mail from: " .. mail.SenderDisplayName, "X4D Mail")
	    DeleteMail(mailId, false)
    end
end

function X4D_Mail:HandleSpam(mailId)
	if (not X4D_Mail:IsMailReadable(mailId)) then
		X4D.Log:Error({ "HandleSpam", "!IsMailReadable", mailId }, "X4D Mail")
		return
	end
	local mail = _readableMail[mailId]
	if (X4D_Mail.Settings:Get("EnableAntiSpam")) then
		if (not (mail.IsCustomerService or mail.IsFromSystem)) then
			if (X4D.AntiSpam ~= nil) then
				local isSpam = X4D.AntiSpam:Check({
						Text = mail.SubjectText .. " " .. mail.BodyText,
						Name = mail.SenderDisplayName,
						Reason = "Mail",
						NoFlood = true, -- we do not want mail to result in flood triggering
					})
				if (isSpam) then
					mail.IsSpam = true
					X4D.Log:Verbose("Deleting mail from spammer: " .. mail.SenderDisplayName, "X4D Mail")
					DeleteMail(mailId, false)
				end
			end
		end	
	end
	return mail.IsSpam
end

local function OnMailReadableAsync(timer, mailId)
    timer:Stop();
    X4D_Mail:HandleMailAttachments(mailId)
    X4D_Mail:HandleSpam(mailId)
end

local function OnMailReadable(eventCode, mailId)
	local senderDisplayName, senderCharacterName, subjectText, mailIcon, unread, fromSystem, fromCustomerService, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived = GetMailItemInfo(mailId)
	local bodyText = ReadMail(mailId)
    --local alreadyHandled = _readableMail[mailId]
    --if (alreadyHandled == nil) then
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
        X4D.Async:CreateTimer(OnMailReadableAsync):Start(337, mailId, "MailHandler")
    --end
end

local function OnOpenMailbox(eventCode)
	local mailId = GetNextMailId()
	while (mailId ~= nil) do
		RequestReadMail(mailId)
		mailId = GetNextMailId(mailId)
	end
end

local function Register()
	EVENT_MANAGER:RegisterForEvent(X4D_Mail.NAME, EVENT_MAIL_OPEN_MAILBOX, OnOpenMailbox)
    EVENT_MANAGER:RegisterForEvent(X4D_Mail.NAME, EVENT_MAIL_READABLE, OnMailReadable)
end

local function Unregister()
end

local function InitializeSettingsUI()
	local LAM = LibStub("LibAddonMenu-2.0")
	local cplId = LAM:RegisterAddonPanel("X4D_MAIL_CPL", {
        type = "panel",
        name = "X4D |cFFAE19Mail |c4D4D4D" .. X4D_Mail.VERSION,
    })

    local panelControls = { }

    table.insert(panelControls, {
            type = "checkbox",
            name = "Auto-Accept Attachments", 
            tooltip = "When enabled, mail attachments are automatically accepted.", 
            getFunc = function() 
                return X4D.Mail.Settings:Get("AutoAcceptAttachments")
            end,
            setFunc = function()
                X4D.Mail.Settings:Set("AutoAcceptAttachments", not X4D.Mail.Settings:Get("AutoAcceptAttachments")) 
            end,
        })

    table.insert(panelControls, {
            type = "checkbox",
            name = "Ignore Return Mail", 
            tooltip = "When enabled, mail returned to you is ignored (attachments are not auto-accepted, and the message will not be auto-deleted.)", 
            getFunc = function() 
                return X4D.Mail.Settings:Get("LeaveReturnedMailAlone")
            end,
            setFunc = function()
                X4D.Mail.Settings:Set("LeaveReturnedMailAlone", not X4D.Mail.Settings:Get("LeaveReturnedMailAlone")) 
            end,
        })

    table.insert(panelControls, {
            type = "checkbox",
            name = "Auto-Delete System Messages", 
            tooltip = "When enabled, System Messages are automatically deleted after all attachments are received, this includes messages from Crown Store, Guild Store and Hirelings. |cFFFFFFThis option does NOT apply to messages from Customer Support, nor messages from other users.", 
            getFunc = function() 
                return X4D.Mail.Settings:Get("AutoDeleteMail")
            end,
            setFunc = function()
                X4D.Mail.Settings:Set("AutoDeleteMail", not X4D.Mail.Settings:Get("AutoDeleteMail")) 
            end,
        })

    table.insert(panelControls, {
            type = "checkbox",
            name = "Use AntiSpam Library", 
            tooltip = "When enabled, if an AntiSpam Library is detected it will be used to filter spam from your mailbox. Use with Auto-Delete option for spam removal.",
            getFunc = function() 
                return X4D.Mail.Settings:Get("EnableAntiSpam")
            end,
            setFunc = function()
                X4D.Mail.Settings:Set("EnableAntiSpam", not X4D.Mail.Settings:Get("EnableAntiSpam")) 
            end,
        })

    LAM:RegisterOptionControls(
        "X4D_MAIL_CPL",
        panelControls
    )
end

local function OnAddOnLoaded(eventCode, addonName)
	if (addonName ~= X4D_Mail.NAME) then
		return
	end	
    X4D.Log:Debug({"OnAddonLoaded", eventCode, addonName}, X4D_Mail.NAME)
    local stopwatch = X4D.Stopwatch:StartNew()
	X4D_Mail.Settings = X4D.Settings:Open(
		X4D_Mail.NAME .. "_SV",
		{
            SettingsAre = "Account-Wide",
			AutoAcceptAttachments = true,
			AutoDeleteMail = false,
			EnableAntiSpam = false,
			LeaveReturnedMailAlone = true,
        }, 
        2)

    InitializeSettingsUI()

	Register()
    X4D_Mail.Took = stopwatch.ElapsedMilliseconds()
end

local function OnPlayerActivated()
end

-- ZO bug fix: prevent nil reference error for deleted mail
function MAIL_INBOX:RefreshMoneyControls()
    local mailData = self:GetMailData(self.mailId)
    self.sentMoneyControl:SetHidden(true)
    self.codControl:SetHidden(true)
    if (mailData == nil) then
        return
    end
    if(mailData.attachedMoney > 0) then
        self.sentMoneyControl:SetHidden(false)
        ZO_CurrencyControl_SetSimpleCurrency(GetControl(self.sentMoneyControl, 'Currency'), CURRENCY_TYPE_MONEY, mailData.attachedMoney, MAIL_COD_ATTACHED_MONEY_OPTIONS)
    elseif(mailData.codAmount > 0) then
        self.codControl:SetHidden(false)
        ZO_CurrencyControl_SetSimpleCurrency(GetControl(self.codControl, 'Currency'), CURRENCY_TYPE_MONEY, mailData.codAmount, MAIL_COD_ATTACHED_MONEY_OPTIONS)
    end
end

EVENT_MANAGER:RegisterForEvent(X4D_Mail.NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(X4D_Mail.NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
