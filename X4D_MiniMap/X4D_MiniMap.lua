local X4D_MiniMap = LibStub:NewLibrary("X4D_MiniMap", 1002)
if (not X4D_MiniMap) then
	return
end
local X4D = LibStub("X4D")
X4D.MiniMap = X4D_MiniMap

X4D_MiniMap.NAME = "X4D_MiniMap"
X4D_MiniMap.VERSION = "1.2"

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

local _centerX, _centerY = 0, 0

local _currentMap
local _lastPlayerX, _lastPlayerY = 0, 0
local _playerX, _playerY, _playerH = 0, 0, 0
local _cameraH

local _zoomPanTimer
local _zoomPanState
local _mapControllerTimer

local _minZoomLevel = 0.1 -- TODO: theoretical max, actual max is determined by ability to keep minimap window entirely covered with map contents
local _maxZoomLevel = 1
local _maxPipWidth = 14


local function UpdatePlayerPip(heading)
    local heading = _cameraH
    if (X4D_MiniMap.Settings:Get("UsePlayerHeading")) then
        heading = _playerH
    end
    if (_playerPip ~= nil) then
        _playerPip:SetTextureRotation(heading)
    end
end 

local function UpdatePlayerPositionLabel()
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

local function UpdateLocationNameLabel(v)
    if (v == nil) then
        v = GetPlayerLocationName()
    end
    if (_locationNameLabel ~= nil) then
        _locationNameLabel:SetText(v)
    end
end

local function UpdateZoomPanState(timer, state)
    local map = _currentMap
    if (map == nil or state == nil or _tiles == nil) then
        --X4D.Log:Debug({"map, state or tiles are nil", map == nil, state == nil, _tiles == nil}, "UpdateZoomPanState")
        return
    end
    state.ZoomLevel = 1
    -- NOTE: no longer dynamically changing zoom-level, this will be made a user-setting instead
    --state.ZoomIncrement = state.ZoomIncrement * 0.01
    --if (state.ZoomIncrement <= 0.01) then 
    --    state.ZoomIncrement = 0.01
    --end
    --local maxZoomLevel = _maxZoomLevel
    --if (map.MaxZoomLevel ~= nil) then
    --    maxZoomLevel = map.MaxZoomLevel
    --elseif (X4D.Cartography.IsSubZone()) then
    --    maxZoomLevel = 1
    --end
    --state.ZoomLevel = state.ZoomLevel + state.ZoomIncrement
    --if (state.ZoomLevel >= maxZoomLevel) then
    --    state.ZoomLevel = maxZoomLevel
    --end
    _zoomPanState = state
        
    local mapWidth = (map.HorizontalTileCount * map.TileWidth)
    local zoomedWidth = (mapWidth) * state.ZoomLevel
    local mapHeight = (map.VerticalTileCount * map.TileHeight)
    local zoomedHeight = (mapHeight) * state.ZoomLevel

    if ((_playerX ~= nil and _playerY ~= nil) and ((_playerX ~= _lastPlayerX or _playerY ~= _lastPlayerY) or (state.ZoomLevel ~= maxZoomLevel))) then
        if (_tileContainer ~= nil) then
            local zoomLevel = state.ZoomLevel
            if (map.IsSubZone) then
                -- we get a great deal of 'jitter' in subzone maps due to their size, so scale them out a bit
                zoomLevel = zoomLevel * 0.8
            end
            _tileContainer:SetScale(state.ZoomLevel)
            for _,tile in ipairs(_tiles) do
                tile:SetScale(state.ZoomLevel)
            end
        end
        _lastPlayerX = _playerX
        _lastPlayerY = _playerY

        local offsetX = (_playerX * zoomedWidth) - _centerX
        local offsetY = (_playerY * zoomedHeight) - _centerY
        local pipWidth = (_maxPipWidth / _maxZoomLevel) * state.ZoomLevel -- pip size for current zoom level -- TODO: this should be calculated when zoom level changes and cached inside ZoomPanState (optimization)
        local pipX = (offsetX + _centerX - (pipWidth / 2))
        local pipY = (offsetY + _centerY - (pipWidth / 2))
        -- clamp map position
        if (offsetX < 0) then
            offsetX = 0
        elseif (offsetX > (zoomedWidth - (_centerX * 2))) then
            offsetX = (zoomedWidth - (_centerX * 2))
        end
        if (offsetY < 0) then
            offsetY = 0
        elseif (offsetY > (zoomedHeight - (_centerY * 2))) then
            offsetY = (zoomedHeight - (_centerY * 2))
        end
        _tileContainer:ClearAnchors()
        _tileContainer:SetAnchor(TOPLEFT, _tileScroll, TOPLEFT, -1 * offsetX, -1 * offsetY)
        _playerPip:ClearAnchors()
        _playerPip:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, pipX, pipY)
        UpdatePlayerPip()
    end
end

local function StartZoomPanController()
    -- auto-zoom/pan map ~10fps
    if (_zoomPanTimer == nil) then
        _zoomPanTimer = X4D.Async:CreateTimer(UpdateZoomPanState)
    end
    _zoomPanTimer:Start(100, { ZoomLevel = 1 }, "X4D_MiniMap::ZoomPanController")
end

local function StartWorldMapController()
    -- test world map
    if (_mapControllerTimer == nil) then
        _mapControllerTimer = X4D.Async:CreateTimer(function(timer, state)
            if (_playerX == 0 or _playerY == 0 or ZO_WorldMap_IsWorldMapShowing()) then
                return
            end
            if ((_playerX <= 0.04 or _playerX >= 0.96) or (_playerY <= 0.04 or _playerY >= 0.96)) then
                MapZoomOut()
            else
                ProcessMapClick(_playerX, _playerY)
            end
        end)
    end
    _mapControllerTimer:Start(2000, { }, "X4D_MiniMap::WorldMapController")
end

X4D.Cartography.PlayerX:Observe(function (v)
    _playerX = v
--    if (_zoomPanState ~= nil) then
--        UpdateZoomPanState(nil, _zoomPanState)
--    end
    --UpdatePlayerPip()
    UpdatePlayerPositionLabel()
end)


X4D.Cartography.PlayerY:Observe(function (v)
    _playerY = v
--    if (_zoomPanState ~= nil) then
--        UpdateZoomPanState(nil, _zoomPanState)
--    end
    --UpdatePlayerPip()
    UpdatePlayerPositionLabel()
end)

X4D.Cartography.PlayerHeading:Observe(function (v)
    if (X4D_MiniMap.Settings:Get("UsePlayerHeading")) then
        _playerH = v
        UpdatePlayerPip()
    end
end, 5000)

X4D.Cartography.CameraHeading:Observe(function (v)
    if (not X4D_MiniMap.Settings:Get("UsePlayerHeading")) then
        _cameraH = v
        UpdatePlayerPip()
    end
end, 5000)

X4D.Cartography.CurrentMap:Observe(function (map)
    --X4D.Log:Warning(map,"MiniMap")
    if (_minimapWindow == nil or _tileScroll == nil) then
        X4D.Log:Error("Tile Container not initialized", "MiniMap")
        return
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
        local scaleToFitTileSize = _tileScroll:GetWidth() / map.HorizontalTileCount
        if (map.Tiles ~= nil) then
            for tileRow = 0, (map.VerticalTileCount-1) do
                for tileCol = 0, (map.HorizontalTileCount-1) do
                    local tileIndex = (tileRow * map.HorizontalTileCount) + (tileCol+1)
                    local tileFilename = map.Tiles[tileIndex]
                    local tile = WINDOW_MANAGER:GetControlByName("TILE" .. tileIndex)
                    if (tile == nil) then
                        tile = WINDOW_MANAGER:CreateControl("TILE" .. tileIndex, _tileContainer, CT_TEXTURE)
                    end
                    tile:SetHidden(false)
                    tile:SetTextureReleaseOption(RELEASE_TEXTURE_AT_ZERO_REFERENCES)
                    tile:SetTexture(tileFilename)
                    if ((map.TileWidth == nil or map.TileHeight == nil) or (map.TileWidth <= scaleToFitTileSize)) then
                        map.TileWidth, map.TileHeight = X4D.Cartography:GetTileDimensions(tileTexture)
                        if (map.TileWidth ~= nil and map.TileHeight ~= nil) then
                            if (map.TileWidth <= scaleToFitTileSize) then
                                -- assume map could not be sized correctly, so force defaults which scale to fit minimap window
                                map.TileWidth = scaleToFitTileSize
                                map.TileHeight = scaleToFitTileSize
                            end
                            map.NativeWidth = map.TileWidth * map.HorizontalTileCount
                            map.NativeHeight = map.TileHeight * map.VerticalTileCount
                        end
                        _tileContainer:SetDimensions(map.NativeWidth, map.NativeHeight)
                    end
                    tile:SetDimensions(map.TileWidth, map.TileHeight)
                    tile:ClearAnchors()
                    tile:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, tileCol * map.TileWidth, tileRow * map.TileHeight)
                    tile:SetDrawLayer(DL_BACKGROUND)
                    tile:SetDrawTier(DT_LOW)
                    tile:SetDrawLevel(DL_BELOW)
                    table.insert(_tiles, tile)
                    tile:SetHidden(false)
                end
            end
        end
    end
end)

X4D.Cartography.MapName:Observe(UpdateMapNameLabel)
X4D.Cartography.LocationName:Observe(UpdateLocationNameLabel)

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
    _mapNameLabel:SetText("|")
    local mapNameHeight = _mapNameLabel:GetTextHeight()
    _mapNameLabel:SetAnchor(CENTER, _minimapWindow, CENTER, 0, -1 * (_centerY + (mapNameHeight / 2)))

    _locationNameLabel = WINDOW_MANAGER:CreateControl("X4D_MiniMap_LocationName", _minimapWindow, CT_LABEL)
    _locationNameLabel:SetDrawLayer(DL_TEXT)
    _locationNameLabel:SetDrawTier(DT_HIGH)
    _locationNameLabel:SetFont(X4D_MINIMAP_SMALLFONT)
    _locationNameLabel:SetAnchor(CENTER, _minimapWindow, CENTER, 0, -1 * (_centerY - 7))
    _locationNameLabel:SetText("|")

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
    local stopwatch = X4D.Stopwatch:StartNew()
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
    StartZoomPanController()
    StartWorldMapController()
    X4D_MiniMap.Took = stopwatch.ElapsedMilliseconds()
end)

X4D.UI.CurrentScene:Observe(function (scene) 
    if (_minimapWindow ~= nil) then
        local scene = X4D.UI.CurrentScene()
        local isHudScene = scene ~= nil and (scene:GetName() == "hud" or scene:GetName() == "hudui")
        _minimapWindow:SetHidden(not isHudScene)
    end
end)

EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_PLAYER_ACTIVATED, function()
    StartZoomPanController()
    StartWorldMapController()
end)
