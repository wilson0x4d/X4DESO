local X4D_StatusBar = LibStub:NewLibrary("X4D_StatusBar", 1001)
if (not X4D_StatusBar) then
    return
end
local X4D = LibStub("X4D")
X4D.UI.StatusBar = X4D_StatusBar

local _statusBarWindow
local _private_label

X4D_StatusBar.Panels = {}

local X4D_STATUSBAR_DEFAULTFONT = "ZoFontGameSmall"

--region X4D_StatusBarPanel

local X4D_StatusBarPanel = {}


--- 
--- param onUpdateStatusCallback == no args, state management onus of caller
function X4D_StatusBarPanel:New(name, onUpdateStatusCallback)
    -- TODO: if _statusBarWinow == nil then throw InvalidOperation
    local panel = {
        OnUpdateStatus = onUpdateStatusCallback,
        Label = CreateControl(name, _statusBarWindow, CT_LABEL),
        Order = 0,
        Width = 0,
        Offset = 0,
        AnchorPoint = BOTTOMRIGHT, -- default layout from bottomright, will also layout from bottomleft
        SetText = function (self, text)
            _private_label:SetText(text)
            self.Width = _private_label:GetTextWidth() + 8
            self.Label:SetWidth(self.Width)
            self.Label:SetText(text)
            self.Label:ClearAnchors()
            local negate = 1
            if (self.AnchorPoint == BOTTOMRIGHT) then
                negate = -1
            end
            self.Label:SetAnchor(self.AnchorPoint, _statusBarWindow, self.AnchorPoint, negate * self.Offset, 0)
        end, 
    }
    panel.Label:SetFont(X4D_STATUSBAR_DEFAULTFONT)
    panel.Label:SetDrawLayer(DL_TEXT)
    panel.Label:SetColor(1,1,1,1)
    panel:SetText(name)
    panel.Label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    panel.Label:SetHidden(false)
    panel.Label:SetMouseEnabled(true)
    setmetatable(panel, { __index = X4D_StatusBarPanel })
    X4D_StatusBar.Panels[name] = panel
    return panel
end

--endregion

function X4D_StatusBar:CreatePanel(name, onUpdateStatusCallback)
    self:Initialize()
    return X4D_StatusBarPanel:New(name, onUpdateStatusCallback)
end

local function UpdateStatusBarPanels()
    local leftOffset = 0
    local rightOffset = 0
    for panelName,statusBarPanel in pairs(X4D_StatusBar.Panels) do
        if (statusBarPanel.OnUpdateStatus ~= nil) then
            if (statusBarPanel.AnchorPoint == BOTTOMRIGHT) then
                statusBarPanel.Offset = rightOffset
                statusBarPanel.OnUpdateStatus()
                rightOffset = rightOffset + statusBarPanel.Width
            else
                statusBarPanel.Offset = leftOffset
                statusBarPanel.OnUpdateStatus()
                leftOffset = leftOffset + statusBarPanel.Width
            end
            -- TODO: use panel.Order instead of natural order
        end
    end            
end

--region performance panel

local _performancePanel

local _latencyMeterIcons = {
    [0] = X4D.Icons:CreateString("/esoui/art/campaign/campaignbrowser_hipop.dds", 16, 16),
    [1] = X4D.Icons:CreateString("/esoui/art/campaign/campaignbrowser_medpop.dds", 16, 16),
    [2] = X4D.Icons:CreateString("/esoui/art/campaign/campaignbrowser_lowpop.dds", 16, 16),
}

local function UpdatePerformancePanel()
    local framerate = GetFramerate()
    --local framerateLevel = 0
    local framerateColor = X4D.Colors.DarkGray
    if (framerate <= 14) then
        --framerateLevel = 1
        framerateColor = X4D.Colors.Red
    elseif (framerate < 20) then
        --framerateLevel = 1
        framerateColor = X4D.Colors.Orange
    elseif (framerate < 26) then
        --framerateLevel = 2
        framerateColor = X4D.Colors.Yellow
    end
    local framerateString = framerateColor .. zo_strformat(SI_FRAMERATE_METER_FORMAT, framerateColor .. math.floor(framerate))
    local latency = GetLatency()
    --local latencyLevel = 0
    local latencyColor = X4D.Colors.DarkGray
    if (latency > 500) then
        --latencyLevel = 1
        latencyColor = X4D.Colors.Red
    elseif (latency > 350) then
        --latencyLevel = 1
        latencyColor = X4D.Colors.Orange
    elseif (latency > 175) then
        --latencyLevel = 2
        latencyColor = X4D.Colors.Yellow
    end
    local latencyString = latencyColor .. "PING: " .. latency --.. _latencyMeterIcons[latencyLevel]
    local text = "   " .. framerateString .. "   " .. latencyString
    _performancePanel:SetText(text)
end

local function CreateBuiltInPerformancePanel()
    _performancePanel = X4D.UI.StatusBar:CreatePanel("X4D_UI_PerformancePanel", UpdatePerformancePanel)
    _performancePanel.AnchorPoint = BOTTOMLEFT
end

--endregion

function X4D_StatusBar:Initialize()
    if (_statusBarWindow == nil) then
        if (_private_label == nil) then
            _private_label = CreateControl("X4D_Private_Label", GuiRoot, CT_LABEL)
            _private_label:SetFont(X4D_STATUSBAR_DEFAULTFONT)
            _private_label:SetHidden(true)
        end
        _statusBarWindow = WINDOW_MANAGER:CreateTopLevelWindow("X4D_StatusBar")
        local screenWidth, screenHeight = GuiRoot:GetDimensions()
        _statusBarWindow:SetDimensions(screenWidth, 21) -- TODO: on window resize, update
        _statusBarWindow:SetAnchor(BOTTOMRIGHT)
        _statusBarWindow:SetDrawLayer(DL_BACKGROUND)
        _statusBarWindow:SetHidden(false)
        local backgroundImage = WINDOW_MANAGER:CreateControl("X4D_StatusBar_Background", _statusBarWindow, CT_TEXTURE)
        backgroundImage:SetAnchorFill(_statusBarWindow)
        backgroundImage:SetTexture("EsoUI/Art/Tooltips/UI-TooltipCenter.dds")
        local borderImage = WINDOW_MANAGER:CreateControl("X4D_StatusBar_Border", _statusBarWindow, CT_TEXTURE)
        borderImage:SetTexture("X4D_UI/FizzBuzz.dds")
        borderImage:SetAnchor(TOPRIGHT)
        borderImage:SetDimensions(screenWidth, 3) -- TODO: on window resize, update
        --borderImage:SetDrawLayer(DL_BACKGROUND)
        borderImage:SetDrawTier(DT_LOW)
        --_statusBarWindow:SetEdgeTexture("EsoUI/Art/Tooltips/UI-Border.dds", screenWidth, 16)

        --ZO_AlphaAnimation

        CreateBuiltInPerformancePanel()
        UpdateStatusBarPanels()
        local statusBarUpdateTimer = X4D.Async:CreateTimer(function (timer, state)
            --X4D.Log:Verbose{"X4D_StatusBar", "Updating Status Bar Panels"}
            state.Ticks = state.Ticks + 1
            if (state.Ticks % 3 == 0) then
                UpdateStatusBarPanels()
            end
        end, 1000, { Ticks = 0 }) 
        statusBarUpdateTimer:Start()
    end
end

EVENT_MANAGER:RegisterForEvent("X4D_StatusBar", EVENT_ADD_ON_LOADED, function (event, name) 
    if (name ~= "X4D_UI") then
        return
    end
    X4D_StatusBar:Initialize()
end)
