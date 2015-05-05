local X4D_StatusBar = LibStub:NewLibrary("X4D_StatusBar", 1001)
if (not X4D_StatusBar) then
    return
end
local X4D = LibStub("X4D")
X4D.UI.StatusBar = X4D_StatusBar

local _statusBarWindow

X4D_StatusBar.Panels = {}

--region X4D_StatusBarPanel

local X4D_StatusBarPanel = {}

--- 
--- param onUpdateStatusCallback == no args, state management onus of caller
function X4D_StatusBarPanel:New(name, onUpdateStatusCallback)
    local panel = {
        OnUpdateStatus = onUpdateStatusCallback,
        Label = CreateControl(name, _statusBarWindow, CT_LABEL),
    }
    panel.Label:SetFont("ZoFontGameSmall")
    panel.Label:SetDrawLayer(DL_TEXT)
    panel.Label:SetColor(1,1,1,0.5)
    panel.Label:SetAnchor(BOTTOMRIGHT)
    panel.Label:SetText(name)
    panel.Label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    panel.Label:SetHidden(false)
    panel.Label:SetMouseEnabled(true)
    setmetatable(panel, { __index = X4D_StatusBarPanel })
    X4D_StatusBar.Panels[name] = panel
    return panel
end

--endregion

function X4D_StatusBar:CreatePanel(name, onUpdateStatusCallback)
    return X4D_StatusBarPanel:New(name, onUpdateStatusCallback)
end

function X4D_StatusBar:Initialize()
    if (_statusBarWindow == nil) then
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

        local statusBarUpdateTimer = X4D.Async:CreateTimer(function (timer, state)
            --X4D.Log:Verbose{"X4D_StatusBar", "Updating Status Bar Panels"}
            for panelName,statusBarPanel in pairs(self.Panels) do
                if (statusBarPanel.OnUpdateStatus ~= nil) then
                    statusBarPanel.OnUpdateStatus()
                end
            end            
        end, 4700, {}) 
        statusBarUpdateTimer:Start()
    end
end

EVENT_MANAGER:RegisterForEvent("X4D_StatusBar", EVENT_ADD_ON_LOADED, function (event, name) 
    if (name ~= "X4D_UI") then
        return
    end
    X4D_StatusBar:Initialize()
end)
