local X4D_MiniMap = LibStub:NewLibrary("X4D_MiniMap", 1000)
if (not X4D_MiniMap) then
	return
end
local X4D = LibStub("X4D")
X4D.MiniMap = X4D_MiniMap

X4D_MiniMap.NAME = "X4D_MiniMap"
X4D_MiniMap.VERSION = "1.0"

local X4D_MINIMAP_SMALLFONT = "ZoFontGameSmall"
local X4D_MINIMAP_LARGEFONT = "ZoFontGamepad22"

local _minimapWindow
local _tileScroll
local _tileContainer
local _tiles
local _mapNameLabel
local _locationNameLabel
local _playerPositionLabel
local _playerPip

local _centerX
local _centerY

local _currentMap
local _playerX
local _playerY
local _playerH
local _cameraH

local _zoomPanTimer
local _zoomPanState

local _maxZoomLevel = 20
local _userZoomLevel = 20
local _maxPipWidth = 14

local function UpdatePlayerPip(heading)
    local heading = _cameraH
    if (X4D_MiniMap.Settings:Get("UsePlayerHeading")) then
        heading = _playerH
    end
    if (_playerX ~= nil and _playerY ~= nil and _zoomPanState ~= nil) then
        local map = _currentMap
        if (map ~= nil and _zoomPanState.CurrentZoomedTileSize ~= nil) then
            local zoomedTileSize = _zoomPanState.CurrentZoomedTileSize
            local zoomedMapWidth = map.MapWidth * zoomedTileSize
            local zoomedMapHeight = map.MapHeight * zoomedTileSize
            local offsetX = (_playerX * zoomedMapWidth) - _centerX
            local offsetY = (_playerY * zoomedMapHeight) - _centerY
            if (_playerPip ~= nil) then
                _playerPip:SetTextureRotation(heading)
            end
        end
    end
end

local function UpdatePlayerPositionLabel()
    local mapSizeForPosition
    if (_playerX ~= nil and _playerY ~= nil and _playerPositionLabel ~= nil) then
        local playerPositionString = string.format("(%.02f,%.02f)",
            _playerX*100, _playerY*100)
        _playerPositionLabel:SetText(playerPositionString)
    end
end

local function UpdateMapNameLabel()
    local map = _currentMap
    if (map ~= nil and _mapNameLabel ~= nil) then
        _mapNameLabel:SetText(map.MapName)
    end
end

local function UpdateLocationNameLabel()
    local map = _currentMap
    if (map ~= nil and _locationNameLabel ~= nil) then
        _locationNameLabel:SetText(map.LocationName)
    end
end

local _lastPlayerX, _lastPlayerY = 0, 0
local function UpdateZoomPanState(timer, state)
        local map = _currentMap
        if (map == nil or state == nil) then
            return
        end
        if (state.ZoomIncrement <= 0.1) then 
            state.ZoomIncrement = 0.1
        else
            state.ZoomIncrement = state.ZoomIncrement * 0.73
        end
        if (X4D.Cartography.IsSubZone()) then
            _maxZoomLevel = 1
        else
            _maxZoomLevel = 20
        end
        state.ZoomLevel = state.ZoomLevel + state.ZoomIncrement
        if (state.ZoomLevel >= _maxZoomLevel) then
            state.ZoomLevel = _maxZoomLevel
        end
        local tileSize = _tileScroll:GetWidth() / map.MapWidth -- tile-size when zoomed out all the way
        state.CurrentZoomedTileSize = tileSize * state.ZoomLevel -- tile-size for current zoom level
        _zoomPanState = state
        
        -- NOTE: everything beyond this point is presentation related
        local zoomedTileSize = _zoomPanState.CurrentZoomedTileSize
        local zoomedMapWidth = map.MapWidth * zoomedTileSize
        local zoomedMapHeight = map.MapHeight * zoomedTileSize -- TODO: what if map.Width ~= map.Height? i think cartographer should pad the map dimension, e.g. if map is 2x3 actual x4d would normalize to 3x3
        if (_tileContainer ~= nil) then
            _tileContainer:SetDimensions(zoomedMapWidth, zoomedMapHeight)
            if (_tiles ~= nil) then
                for tileRow = 0, (map.MapHeight - 1) do
                    for tileCol = 0, (map.MapWidth - 1) do
                        local tileIndex = (tileRow * map.MapWidth) + (tileCol+1)
                        local tile = _tiles[tileIndex]
                        -- TODO: ONLY DO THIS WHEN ACTUALLY CHANGED
                        tile:ClearAnchors()
                        tile:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, (tileCol * zoomedTileSize), (tileRow * zoomedTileSize))
                        tile:SetDimensions(zoomedTileSize, zoomedTileSize)
                    end
                end
            end
        end

        if ((_playerX ~= nil and _playerY ~= nil) and ((_playerX ~= _lastPlayerX or _playerY ~= _lastPlayerY) or (state.ZoomLevel ~= _maxZoomLevel))) then
            _lastPlayerX = _playerX 
            _lastPlayerY = _playerY
            local scrollH, scrollV = _tileScroll:GetScrollExtents()

            local offsetX = (_playerX * zoomedMapWidth) - _centerX
            local offsetY = (_playerY * zoomedMapHeight) - _centerY
            if (offsetX < 0) then
                offsetX = 0
            elseif (offsetX > (zoomedMapWidth - (_centerX * 2))) then
                offsetX = (zoomedMapWidth - (_centerX * 2))
            end
            if (offsetY < 0) then
                offsetY = 0
            elseif (offsetY > (zoomedMapHeight - (_centerY * 2))) then
                offsetY = (zoomedMapHeight - (_centerY * 2))
            end
            local pipWidth = (_maxPipWidth / _maxZoomLevel) * state.ZoomLevel -- pip size for current zoom level -- TODO: this should be calculated when zoom level changes and cached inside ZoomPanState (optimization)
            _tileContainer:ClearAnchors()
            _tileContainer:SetAnchor(TOPLEFT, _tileScroll, TOPLEFT, -1 * offsetX, -1 * offsetY)
            _playerPip:ClearAnchors()
            _playerPip:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, offsetX + _centerX - (pipWidth / 2), offsetY + _centerY - (pipWidth / 2))
            UpdatePlayerPip()
        end
end

local function StartZoomPanTimer()
    -- auto-zoom/pan map ~10fps
    if (_zoomPanTimer ~= nil) then
        return
    end
    _zoomPanTimer = X4D.Async:CreateTimer(UpdateZoomPanState):Start(100, { ZoomLevel = 1, ZoomIncrement = 7 }, "X4D_MiniMap::ZoomPanTimer")
end

X4D.Cartography.IsSubZone:Observe(function (v)
    -- TODO:
end)

X4D.Cartography.PlayerX:SetRateLimit(1000/13):Observe(function (v)
    _playerX = v
    if (_zoomPanState ~= nil) then
        UpdateZoomPanState(nil, _zoomPanState)
    end
    --UpdatePlayerPip()
    UpdatePlayerPositionLabel()
end)


X4D.Cartography.PlayerY:SetRateLimit(1000/13):Observe(function (v)
    _playerY = v
    if (_zoomPanState ~= nil) then
        UpdateZoomPanState(nil, _zoomPanState)
    end
    UpdatePlayerPip()
    UpdatePlayerPositionLabel()
end)

X4D.Cartography.PlayerHeading:SetRateLimit(1000/13):Observe(function (v)
    if (X4D_MiniMap.Settings:Get("UsePlayerHeading")) then
        _playerH = v
        UpdatePlayerPip()
    end
end, 5000)

X4D.Cartography.CameraHeading:SetRateLimit(1000/13):Observe(function (v)
    if (not X4D_MiniMap.Settings:Get("UsePlayerHeading")) then
        _cameraH = v
        UpdatePlayerPip()
    end
end, 5000)

X4D.Cartography.CurrentMap:Observe(function (map)
    --X4D.Log:Warning(map,"MiniMap")
    if (_minimapWindow == nil) then
        X4D.Log:Error("Tile Container not initialized", "MiniMap")
    end 
    _currentMap = map
    UpdateMapNameLabel()
    UpdateLocationNameLabel()
    -- release old tiles
    if (_tiles ~= nil) then
        for _, tile in pairs(_tiles) do
            tile:ClearAnchors()
            tile:SetHidden(true)
        end
    end
    -- allocate new tiles
    _tiles = {}
    if (map ~= nil) then
        local tileSize = _tileContainer:GetWidth() / map.MapWidth
        if (map.Tiles ~= nil) then
            for tileRow = 0, (map.MapHeight-1) do
                for tileCol = 0, (map.MapWidth-1) do
                    local tileIndex = (tileRow * map.MapWidth) + (tileCol+1)
                    local tileFilename = map.Tiles[tileIndex]
                    local tile = WINDOW_MANAGER:GetControlByName("TILE" .. tileIndex)
                    if (tile == nil) then
                        tile = WINDOW_MANAGER:CreateControl("TILE" .. tileIndex, _tileContainer, CT_TEXTURE)
                    end
                    tile:SetHidden(false)
                    tile:SetTextureReleaseOption(RELEASE_TEXTURE_AT_ZERO_REFERENCES)
                    tile:SetTexture(tileFilename)
                    tile:SetDimensions(tileSize,tileSize)
                    tile:ClearAnchors()
                    tile:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, tileCol * tile:GetWidth(), tileRow * tile:GetHeight())
                    tile:SetDrawLayer(DL_BACKGROUND)
                    tile:SetDrawTier(DT_LOW)
                    tile:SetDrawLevel(DL_BELOW)
                    table.insert(_tiles, tile)
                    tile:SetHidden(false)
                end
            end
        end
    end
    StartZoomPanTimer()
end)

X4D.Cartography.MapName:Observe(function (v) 
    UpdateMapNameLabel()
end)
X4D.Cartography.LocationName:Observe(function (v)
    UpdateLocationNameLabel()
end)
--X4D.Cartography.ZoneIndex:Observe(function (v) 
--    X4D.Log:Verbose({"ZoneIndex", v}, "MiniMap")
--end)
--X4D.Cartography.PlayerX:Observe(function (v) 
--    X4D.Log:Verbose({"PlayerX", v}, "MiniMap")
--end)
--X4D.Cartography.PlayerY:Observe(function (v) 
--    X4D.Log:Verbose({"PlayerY", v}, "MiniMap")
--end)

local function InitializeMiniMapWindow()
    _minimapWindow = WINDOW_MANAGER:CreateTopLevelWindow("X4D_MiniMap")
    _minimapWindow:SetDimensions(240, 240) -- TODO: allow resize?
    _minimapWindow:SetAnchor(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, -32, -32)
    _minimapWindow:SetDrawLayer(DL_BACKGROUND)
    _minimapWindow:SetDrawTier(DT_LOW)
    local backgroundImage = WINDOW_MANAGER:CreateControl("X4D_MiniMap_Background", _minimapWindow, CT_TEXTURE)
    backgroundImage:SetAnchorFill(_minimapWindow)
    backgroundImage:SetTexture("EsoUI/Art/Tooltips/UI-TooltipCenter.dds")
    _tileScroll = WINDOW_MANAGER:CreateControl("X4D_MiniMap_TileScroll", _minimapWindow, CT_SCROLL)
    _tileScroll:SetDimensions(_minimapWindow:GetWidth()-8, _minimapWindow:GetHeight()-8) -- TODO: update when minimap window dimensions change
    _tileScroll:SetAnchor(CENTER, _minimapWindow, CENTER, 0, 0)
    local _tileBG = WINDOW_MANAGER:CreateControl("X4D_MiniMap_TileBackground", _tileScroll, CT_TEXTURE)
    _tileBG:SetAnchorFill(_tileScroll)
    _tileBG:SetTexture("EsoUI/Art/WorldMap/worldmap_map_background_512tile.dds")

    local containerL, containerT, containerR, containerB = _tileScroll:GetScreenRect()
    local centerX, centerY = _tileScroll:GetCenter()
    _centerX = centerX - containerL
    _centerY = centerY - containerT

    _tileContainer = WINDOW_MANAGER:CreateControl("X4D_MiniMap_TileContainer", _tileScroll, CT_CONTROL)
    _tileContainer:SetAnchor(TOPLEFT, _tileScroll, TOPLEFT, 0, 0)
    _playerPip = WINDOW_MANAGER:CreateControl("X4D_MiniMap_playerHeading", _tileContainer, CT_TEXTURE)
    _playerPip:SetDimensions(_maxPipWidth, _maxPipWidth)
    _playerPip:SetTexture("EsoUI/Art/MapPins/UI-WorldMapPlayerPip.dds")
    _playerPip:SetDrawLayer(DL_BACKGROUND)
    _playerPip:SetDrawTier(DT_HIGH)
    _tileContainer:SetMouseEnabled(true)

    _mapNameLabel = WINDOW_MANAGER:CreateControl("X4D_MiniMap_MapName", _minimapWindow, CT_LABEL)
    _mapNameLabel:SetDrawLayer(DL_TEXT)
    _mapNameLabel:SetDrawTier(DT_LOW)
    _mapNameLabel:SetFont(X4D_MINIMAP_LARGEFONT)
    _mapNameLabel:SetAnchor(CENTER, _minimapWindow, CENTER, 0, -1 * (_centerY))
    _mapNameLabel:SetText("")
    local mapNameHeight = _mapNameLabel:GetTextHeight()
    UpdateMapNameLabel()

    _locationNameLabel = WINDOW_MANAGER:CreateControl("X4D_MiniMap_LocationName", _minimapWindow, CT_LABEL)
    _locationNameLabel:SetDrawLayer(DL_TEXT)
    _locationNameLabel:SetDrawTier(DT_LOW)
    _locationNameLabel:SetFont(X4D_MINIMAP_SMALLFONT)
    _locationNameLabel:SetAnchor(CENTER, _minimapWindow, CENTER, 0, -1 * (_centerY - mapNameHeight))
    _locationNameLabel:SetText("")
    UpdateLocationNameLabel()

    _playerPositionLabel = WINDOW_MANAGER:CreateControl("X4D_MiniMap_PlayerPosition", _minimapWindow, CT_LABEL)
    _playerPositionLabel:SetDrawLayer(DL_TEXT)
    _playerPositionLabel:SetDrawTier(DT_LOW)
    _playerPositionLabel:SetFont(X4D_MINIMAP_SMALLFONT)
    _playerPositionLabel:SetAnchor(BOTTOMLEFT, _minimapWindow, BOTTOMLEFT, 8, -8)
    _playerPositionLabel:SetText("")
    UpdatePlayerPositionLabel()

    local scene = X4D.UI.CurrentScene()
    local isHudScene = scene ~= nil and (scene:GetName() == "hud" or scene:GetName() == "hudui")
    _minimapWindow:SetHidden(not isHudScene)
end

local function InitializeSettingsUI()
	local LAM = LibStub("LibAddonMenu-2.0")
	local cplId = LAM:RegisterAddonPanel("X4D_MINIMAP_CPL", {
        type = "panel",
        name = "X4D |cFFAE19MiniMap |c4D4D4D" .. X4D_MiniMap.VERSION,
    })

    local panelControls = { }

    table.insert(panelControls, {
        type = "checkbox",
        name = "(ALPHA) Enable MiniMap",
        tooltip = "When enabled, a minimap is displayed in the bottom-right of the screen (except when interacting with a HUD/Menu/etc.) |cFF0000This is an alpha-grade feature, currently in development. Feel free to use, test, and provide feedback for it. It is disabled by default since I cannot guarantee it will work correctly in all zones in its current state.",
        getFunc = function()
            return X4D.XP.Settings:Get("EnableMiniMap")
        end,
        setFunc = function()
            X4D.XP.Settings:Set("EnableMiniMap", not X4D.XP.Settings:Get("EnableMiniMap"))
        end,
    })

    table.insert(panelControls, {
        type = "checkbox",
        name = "Use Player Heading",
        tooltip = "When enabled, the direction of travel for the player character is used on the minimap. By default, the current direction of the player camera is used.",
        getFunc = function()
            return X4D.XP.Settings:Get("UsePlayerHeading")
        end,
        setFunc = function()
            X4D.XP.Settings:Set("UsePlayerHeading", not X4D.XP.Settings:Get("UsePlayerHeading"))
        end,
    })

    LAM:RegisterOptionControls(
        "X4D_MINIMAP_CPL",
        panelControls
    )
end

EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_ADD_ON_LOADED, function(event, name)
    if (name ~= "X4D_MiniMap") then
        return
    end
	X4D_MiniMap.Settings = X4D.Settings(
		X4D_MiniMap.NAME .. "_SV",
		{
            SettingsAre = "Per-Character",
            EnableMiniMap = false,
            UsePlayerHeading = false,
            ShowMapName = true,
            ShowLocationName = true,
        })
    InitializeSettingsUI()
    InitializeMiniMapWindow()
end)

X4D.UI.CurrentScene:Observe(function (scene) 
    if (_minimapWindow ~= nil) then
        local scene = X4D.UI.CurrentScene()
        local isHudScene = scene ~= nil and (scene:GetName() == "hud" or scene:GetName() == "hudui")
        _minimapWindow:SetHidden(not isHudScene)
    end
end)