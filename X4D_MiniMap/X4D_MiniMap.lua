
-- TODO: minimap shows misbehavior when user opens map window and
--		  zooms out several times, then closes map window. there's
--		  no reason for minimap state to be updated like this when
--		  the map window is open.

-- TODO: switch to using a "composite texture" control for minimap
--		  tiles and pips, possibly also for driving position within
--		  the minimap view (less jitter than anchoring child in 
--		  the parent/container?)

-- TODO: player pip in minimap does not match map window inside 
--		  dark brotherhood sanctuary, possibly other locations. this
--		  location's exit door is a better point of reference than
--		  map contents (clearly showing POI/exit PIP is accurate even
--		  when Player PIP is not.)

local X4D_MiniMap = LibStub:NewLibrary("X4D_MiniMap", 1006)
if (not X4D_MiniMap) then
	return
end
local X4D = LibStub("X4D")
X4D.MiniMap = X4D_MiniMap

X4D_MiniMap.NAME = "X4D_MiniMap"
X4D_MiniMap.VERSION = "1.6"

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

local _miniMapInteractor

local DEFAULT_PIP_WIDTH = 30
local PLAYER_PIP_WIDTH = 15

local _pipcache = { } -- 'pips' are the controls used in-game, they are recycled
local _pins = { } -- 'pins' are a subset of 'active pips', it may be less than the number of pips in the cache

-- TODO: localize/abstract table keys, I believe these are only valid for an en-US game client
local _npcTypeToTextureNameLookup = {
	["UNKNOWN"] = "esoui/art/progression/progression_tabicon_backup_active.dds",
	
	-- NPCs 
	["Vendor"] = "EsoUI/Art/Icons/ServiceMapPins/servicepin_vendor.dds",
	["Banker"] = "EsoUI/Art/Icons/ServiceMapPins/servicepin_bank.dds",
	["Moneylender"] = "EsoUI/Art/Icons/ServiceMapPins/servicepin_bank.dds",
	["Fence"] = "EsoUI/Art/Icons/ServiceMapPins/servicepin_fence.dds",
	["Merchant"] = "EsoUI/Art/Icons/ServiceMapPins/servicepin_vendor.dds",
	["Innkeeper"] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_consumables.dds",
	["Brewer"] = "EsoUI/Art/Crafting/provisioner_indexIcon_beer_down.dds",
	["Blacksmith"] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_craftbag_blacksmithing.dds",
	["Stablemaster"] = "EsoUI/Art/Icons/ServiceMapPins/servicepin_stable.dds", -- TODO: add event handler for storing stablemasters, then exclude from POI-to-pin converter
	["Woodworker"] = "EsoUI/Art/Icons/ServiceMapPins/servicepin_woodworking.dds",
	["Carpenter"] = "EsoUI/Art/Icons/ServiceMapPins/servicepin_woodworking.dds",
	["Alchemist"] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_craftbag_alchemy.dds",
	["Clothier"] = "EsoUI/Art/Icons/ServiceMapPins/servicepin_clothier.dds",
	["Tailor"] = "EsoUI/Art/Icons/ServiceMapPins/servicepin_clothier.dds",

	-- these still need review
	["Enchanter"] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_craftbag_enchanting.dds",
	["Weaponsmith"] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_weapons.dds",
	["Armorer"] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_apparel.dds",
	["Mystic"] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_craftbag_alchemy.dds",
	["Leatherworker"] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_apparel.dds",
	["Grocer"] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_craftbag_provisioning.dds",
	["Chef"] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_craftbag_provisioning.dds",

	[""] = "EsoUI/Art/Vendor/tabIcon_mounts_down.dds",
}

local _nextPipCacheId = 1

local function ResetPipCache()
	_nextPipCacheId = 1
end

local function GetNextPipCacheId()
	local result = _nextPipCacheId
	_nextPipCacheId = _nextPipCacheId + 1
	return result
end

local function CreateMiniMapPin(texture)
	local id = GetNextPipCacheId()
    local pip = _pipcache["pip:"..id]
	if (pip == nil) then
		pip = WINDOW_MANAGER:CreateControl(nil, _tileContainer, CT_TEXTURE)
		pip:SetDrawLayer(DL_BACKGROUND)
		pip:SetDrawTier(DT_MEDIUM)
		pip:SetTextureReleaseOption(RELEASE_TEXTURE_AT_ZERO_REFERENCES)
		_pipcache["pip:"..id] = pip
	end
	-- NOTE: just because we're using a cached pip does not mean it has the state we require
	pip:SetTexture(texture)
	pip:SetDimensions(DEFAULT_PIP_WIDTH, DEFAULT_PIP_WIDTH) -- TODO: reset dimensions whenever zoom-level/position changes?
	return {
		PIP = pip,
		Texture = texture,
		Size = DEFAULT_PIP_WIDTH
	}
end

local function ConvertNPCToPin(npc, map)
	local textureName = _npcTypeToTextureNameLookup[npc.Type] or _npcTypeToTextureNameLookup["UNKNOWN"]
	local pin = CreateMiniMapPin(textureName)
	if (pin ~= nil) then
		pin.NPC = npc
		local pip = pin.PIP
		pip:ClearAnchors()
		pip:SetAnchor(TOPLEFT, _tileContainer, CENTER, (npc.Position.X * map.MapWidth) - (DEFAULT_PIP_WIDTH/2), (npc.Position.Y * map.MapHeight) - (DEFAULT_PIP_WIDTH/2))
		pip:SetHidden(false)
	end

	return pin
end

local function ReclaimPin(pin)
	-- assume the pin will be left unused in the pool, so hide it
	pin.PIP:SetHidden(true)
end

local function LayoutMapPins()
	-- X4D.Log:Debug("LayoutMapPins", "MiniMap")
	if (_currentMap == nil) then
		X4D.Log:Warning("LayoutMapPins - Not Initialized", "MiniMap")
		return
	end
	local pins = _pins
	for _,pin in pairs(pins) do
		pin.PIP:SetDimensions(DEFAULT_PIP_WIDTH, DEFAULT_PIP_WIDTH)
		pin.PIP:ClearAnchors()
		if (pin.NPC ~= nil) then
			if (pin.NPC.Position ~= nil) then
				pin.PIP:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, (pin.NPC.Position.X * _currentMap.MapWidth) - (DEFAULT_PIP_WIDTH/2), (pin.NPC.Position.Y * _currentMap.MapHeight) - (DEFAULT_PIP_WIDTH/2))
				pin.PIP:SetHidden(false)
			else
				X4D.Log:Error("LayoutMapPins cannot access `NPC::Position`", "MiniMap")
				pin.PIP:SetHidden(true)
			end
		elseif (pin.POI ~= nil) then
			if (pin.POI.normalizedX ~= nil and pin.POI.normalizedY ~= nil) then
				pin.PIP:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, (pin.POI.normalizedX * _currentMap.MapWidth) - (DEFAULT_PIP_WIDTH/2), (pin.POI.normalizedY * _currentMap.MapHeight) - (DEFAULT_PIP_WIDTH/2))
				pin.PIP:SetHidden(false)
			else
				X4D.Log:Error("LayoutMapPins cannot access `POI::normalizedX`", "MiniMap")
				pin.PIP:SetHidden(true)
			end
		end
	end
end

local RebuildMiniMapPOIPins = nil

function RebuildMiniMapPins()
	-- X4D.Log:Debug("RebuildMiniMapPins")

	if (_currentMap == nil) then
		X4D.Log:Warning("RebuildMiniMapPins - `_currentMap` was not set yet", "MiniMap")
		return
	end

	ResetPipCache()

	-- reclaim pin controls
	local pins = _pins
	if (pins ~= nil) then
		for _,pin in pairs(pins) do
			ReclaimPin(pin)
		end
	end

	local pins = { }

	X4D.Log:Verbose("Rebuilding MiniMap NPC Pins", "MiniMap")
	local npcIndex = 0 -- TODO: use npc name as pin key
	local nearbyNPCs = X4D.NPCs.NearbyNPCs()
	if (nearbyNPCs ~= nil) then
		nearbyNPCs:ForEach(function (npc)
			local pin = ConvertNPCToPin(npc, _currentMap)
			if (pin ~= nil) then
				npcIndex = npcIndex + 1
				pins["npc:"..npcIndex] = pin
			end
		end)
	end

	X4D.Log:Verbose("Rebuilding MiniMap POI Pins", "MiniMap")
	RebuildMiniMapPOIPins(pins, _currentMap)

	_pins = pins
	LayoutMapPins()
end

local function ConvertPOIMapInfoToPin(poi, map)	
	local pin = CreateMiniMapPin(poi.texture)
	if (pin ~= nil) then
		pin.POI = poi
		local pip = pin.PIP
		pip:ClearAnchors()
		pip:SetAnchor(TOPLEFT, _tileContainer, CENTER, (poi.normalizedX * map.MapWidth) - (DEFAULT_PIP_WIDTH/2), (poi.normalizedY * map.MapHeight) - (DEFAULT_PIP_WIDTH/2))
		pip:SetHidden(false)
	end
	return pin
end

RebuildMiniMapPOIPins = function(pins, map)
	-- X4D.Log:Verbose("RebuildMiniMapPOIPins", "MiniMap")
	local zoneIndex = GetCurrentMapZoneIndex()
	local poiCount = GetNumPOIs(zoneIndex)
	for poiIndex = 1, poiCount do
		local normalizedX, normalizedY, pinType, texture, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = GetPOIMapInfo(zoneIndex, poiIndex)
		local pin = ConvertPOIMapInfoToPin({
			normalizedX = normalizedX,
			normalizedY = normalizedY,
			texture = texture
		}, map)		
		pins["poi:"..poiIndex] = pin
	end
end

local _timerForScheduledUpdatePOIPins = nil
local ScheduleUpdateForPOIPins = function (delayMilliseconds)
	if (delayMilliseconds == nil) then
		delayMilliseconds = 500
	end
	if (_timerForScheduledUpdatePOIPins ~= nil) then
		_timerForScheduledUpdatePOIPins:Stop()
	else
		_timerForScheduledUpdatePOIPins = X4D.Async:CreateTimer(function (timer, state) 
			timer:Stop()
			-- X4D.Log:Debug{"X4D_MiniMap::ScheduleUpdateForPOIPins"}
			RebuildMiniMapPins()
		end, delayMilliseconds, {}, "X4D_MiniMap::ScheduleUpdateForPOIPins")
		_timerForScheduledUpdatePOIPins:Start(delayMilliseconds)
	end
end

local function UpdatePlayerPip(heading)
	if (_playerPip ~= nil) then
		_playerPip:SetTextureRotation(_cameraH)
	end
end 

local function OnMapNameChanged(mapName)
	if (_mapNameLabel ~= nil) then
		_mapNameLabel:SetText(mapName)
	else
		X4D.Log:Warning("OnMapNameChanged - Label Not Ready", "MiniMap")
	end
end

local function OnLocationNameChanged(locationName)
	if (_locationNameLabel ~= nil) then
		_locationNameLabel:SetText(locationName)
	else
		X4D.Log:Warning("OnLocationNameChanged - Label Not Ready", "MiniMap")
	end
end

local function OnInteractWithMiniMap(timer, state)
	-- X4D.Log:Debug("OnInteractWithMiniMap", "MiniMap")
	local map = _currentMap
	
	-- these are expected cases, we are effectively waiting for state to pop
	if (map == nil) then
		-- X4D.Log:Debug("OnInteractWithMiniMap - _currentMap is nil", "MiniMap")
		return
	end
	if (_playerX == nil or _playerY == nil) then
		-- X4D.Log:Debug("OnInteractWithMiniMap - No Player Position", "MiniMap")
		return
	end

	_lastPlayerX = _playerX
	_lastPlayerY = _playerY

	if (map.MapWidth == nil or map.MapHeight == nil) then
		-- X4D.Log:Debug("OnInteractWithMiniMap - Map Width/Height Unknown", "MiniMap")
		return
	end

	local offsetX = (_playerX * map.MapWidth) - _centerX
	local offsetY = (_playerY * map.MapHeight) - _centerY

	-- calc panning position/offsets
	if (offsetX < 0) then
		offsetX = 0
	elseif (offsetX > (map.MapWidth - (_centerX * 2))) then
		offsetX = (map.MapWidth - (_centerX * 2))
	end
	if (offsetY < 0) then
		offsetY = 0
	elseif (offsetY > (map.MapHeight - (_centerY * 2))) then
		offsetY = (map.MapHeight - (_centerY * 2))
	end
	
	-- X4D.Log:Debug("LayoutTileScroll", "MiniMap")
	_tileContainer:ClearAnchors()
	_tileContainer:SetAnchor(TOPLEFT, _tileScroll, TOPLEFT, -1 * offsetX, -1 * offsetY) -- TODO: need to interpolate

	-- X4D.Log:Debug("LayoutPlayerPip", "MiniMap")
	local playerPipX = (offsetX + _centerX - (PLAYER_PIP_WIDTH / 2))
	local playerPipY = (offsetY + _centerY - (PLAYER_PIP_WIDTH / 2))
	_playerPip:ClearAnchors()
	_playerPip:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, playerPipX, playerPipY) -- TODO: need to interpolate
end

local function StartMiniMapInteractor()
	-- auto-zoom/pan map
	if (_miniMapInteractor == nil) then
		_miniMapInteractor = X4D.Async:CreateTimer(OnInteractWithMiniMap, 1000/16, { }, "X4D_MiniMap::ZoomPanController")
	end
	_miniMapInteractor:Start()
end

local function OnPlayerPositionChanged(playerPosition)
	-- X4D.Log:Debug{"OnPlayerPositionChanged", v}
	_playerX = playerPosition.X
	_playerY = playerPosition.Y
	_playerH = playerPosition.Heading
	_cameraH = playerPosition.CameraHeading
	if (X4D_MiniMap.Settings:Get("UsePlayerHeading")) then
		UpdatePlayerPip(_playerH)
	else
		UpdatePlayerPip(_cameraH)
	end
	if (_playerPositionLabel ~= nil) then
		local playerPositionString = string.format("(%.02f,%.02f)",
			(playerPosition.X or 1) * 100,
			(playerPosition.Y or 1) * 100)
		_playerPositionLabel:SetText(playerPositionString)
	else
		X4D.Log:Warning("UpdatePlayerPositionLabel - Label Not Ready", "MiniMap")
	end
end

local _onCurrentMapChangedAsyncTask = nil
local function OnCurrentMapChangedAsync(timer, state)
	-- X4D.Log:Debug("OnCurrentMapChangedAsync", "MiniMap")
	if (timer ~= nil) then
		timer:Stop()
	end

	-- release old tiles
	if (_tiles ~= nil) then
		for _, tile in pairs(_tiles) do
			tile:SetHidden(true)
		end
	end
	_tiles = nil

	-- determine if map has been set yet, or defer processing
	local map = _currentMap
	if (map == nil) then
		X4D.Log:Error("Current Map Not Set", "MiniMap")
		_onCurrentMapChangedAsyncTask:Start(250)
		return
	end

	-- determine if MiniMap UI initialized yet, or defer processing
	if (_minimapWindow == nil or _tileScroll == nil) then
		X4D.Log:Error("Tile Container Not Ready", "MiniMap")
		_onCurrentMapChangedAsyncTask:Start(250)
		return
	end

	-- determine if Tile Dimensions initialized yet, or defer processing
	if (map.VerticalTileCount == nil or map.HorizontalTileCount == nil) then
		X4D.Log:Error("Tiles Not Ready", "MiniMap")
		_onCurrentMapChangedAsyncTask:Start(250)
		return
	end

	-- layout tiles
	-- X4D.Log:Debug("LayoutTiles", "MiniMap")
	if (map.Tiles ~= nil) then
		local tiles = { }
		for tileRow = 0,(map.VerticalTileCount - 1) do
			for tileCol = 0,(map.HorizontalTileCount - 1) do
				local tileIndex = (tileRow * map.HorizontalTileCount) + (tileCol + 1)
				local tileFilename = map.Tiles[tileIndex]
				
				local tile = WINDOW_MANAGER:GetControlByName("TILE" .. tileIndex)
				if (tile == nil) then
					tile = WINDOW_MANAGER:CreateControl("TILE" .. tileIndex, _tileContainer, CT_TEXTURE)
					tile:SetTextureReleaseOption(RELEASE_TEXTURE_AT_ZERO_REFERENCES)
					tile:SetDrawLayer(DL_BACKGROUND)
					tile:SetDrawTier(DT_LOW)
					tile:SetDrawLevel(DL_BELOW)
				end
				table.insert(tiles, tile)
				tile:ClearAnchors()
				tile:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, tileCol * map.TileWidth, tileRow * map.TileHeight)
				tile:SetTexture(tileFilename)
				tile:SetDimensions(map.TileWidth, map.TileHeight)
				tile:SetHidden(false)
			end
		end
		_tiles = tiles

		OnInteractWithMiniMap(_miniMapInteractor, {})
		-- RebuildMiniMapPins()
		-- LayoutMapPins()
	end
end
local function OnCurrentMapChanged(map)	
	if (_currentMap ~= map) then
		_currentMap = map
		-- ScheduleUpdateForPOIPins()
		if (_onCurrentMapChangedAsyncTask == nil) then
			_onCurrentMapChangedAsyncTask = X4D.Async:CreateTimer(OnCurrentMapChangedAsync, 250, { }, "X4D_MiniMap!OnCurrentMapChanged")
		else
			_onCurrentMapChangedAsyncTask:Stop()
		end
		_onCurrentMapChangedAsyncTask:Start()
	end
end

local function InitializeMiniMapWindow()
	_minimapWindow = WINDOW_MANAGER:CreateTopLevelWindow("X4D_MiniMap")
	X4D_MiniMap.Window = _minimapWindow -- NOTE: so that it can be accessed by X4D_MiniMapPOI
	_minimapWindow:SetDimensions(240, 240) -- TODO: allow resize? affects minimum scaling, may require map recalc as if new map load
	_minimapWindow:SetAnchor(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, -32, -32)
	_minimapWindow:SetDrawLayer(DL_BACKGROUND)
	_minimapWindow:SetDrawTier(DT_LOW)
	local backgroundImage = WINDOW_MANAGER:CreateControl("X4D_MiniMap_Background", _minimapWindow, CT_TEXTURE)
	backgroundImage:SetAnchorFill(_minimapWindow)
	backgroundImage:SetTexture("EsoUI/Art/Tooltips/UI-TooltipCenter.dds")
	_tileScroll = WINDOW_MANAGER:CreateControl("X4D_MiniMap_TileScroll", _minimapWindow, CT_SCROLL)
	_tileScroll:SetDimensions(_minimapWindow:GetWidth() -8, _minimapWindow:GetHeight() -8)
	-- TODO: update when minimap window dimensions change
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
	_playerPip:SetDimensions(PLAYER_PIP_WIDTH, PLAYER_PIP_WIDTH)
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
	_mapNameLabel:SetAnchor(CENTER, _minimapWindow, CENTER, 0, -1 *(_centerY + (mapNameHeight / 2)))

	_locationNameLabel = WINDOW_MANAGER:CreateControl("X4D_MiniMap_LocationName", _minimapWindow, CT_LABEL)
	_locationNameLabel:SetDrawLayer(DL_TEXT)
	_locationNameLabel:SetDrawTier(DT_HIGH)
	_locationNameLabel:SetFont(X4D_MINIMAP_SMALLFONT)
	_locationNameLabel:SetAnchor(CENTER, _minimapWindow, CENTER, 0, -1 *(_centerY - 7))
	_locationNameLabel:SetText("|")

	_playerPositionLabel = WINDOW_MANAGER:CreateControl("X4D_MiniMap_PlayerPosition", _minimapWindow, CT_LABEL)
	_playerPositionLabel:SetDrawLayer(DL_TEXT)
	_playerPositionLabel:SetDrawTier(DT_LOW)
	_playerPositionLabel:SetFont(X4D_MINIMAP_SMALLFONT)
	_playerPositionLabel:SetAnchor(BOTTOMLEFT, _minimapWindow, BOTTOMLEFT, 8, -8)
	_playerPositionLabel:SetText("|")

	local scene = X4D.UI.CurrentScene()
	local isHudScene = scene ~= nil and(scene:GetName() == "hud" or scene:GetName() == "hudui")
	_minimapWindow:SetHidden(not isHudScene)
end

local function OnNearbyNPCsChanged(nearbyNPCs)
	RebuildMiniMapPins()
end

local function OnCurrentSceneChanged(scene) 
	-- TODO: is this the preferred way to detect hud visibility?
	if (_minimapWindow ~= nil) then
		local isHudScene = scene ~= nil and (scene:GetName() == "hud" or scene:GetName() == "hudui")
		_minimapWindow:SetHidden(not isHudScene)
	end
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
			return X4D_MiniMap.Settings:Get("EnableMiniMap")
		end,
		setFunc = function()
			X4D_MiniMap.Settings:Set("EnableMiniMap", not X4D_MiniMap.Settings:Get("EnableMiniMap"))
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
			X4D_MiniMap.Settings:Set("UsePlayerHeading", not X4D_MiniMap.Settings:Get("UsePlayerHeading"))
		end,
	})

	LAM:RegisterOptionControls(
		"X4D_MINIMAP_CPL",
		panelControls
	)
end

EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_ADD_ON_LOADED, function(eventCode, addonName)
	if (addonName ~= "X4D_MiniMap") then
		return
	end

	X4D.Log:Debug("EVENT_ADD_ON_LOADED", "MiniMap")
	local stopwatch = X4D.Stopwatch:StartNew()

	X4D_MiniMap.Settings = X4D.Settings:Open(
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

	-- hooks of interest
	X4D.Cartography.CurrentMap:Observe(OnCurrentMapChanged)
	X4D.Cartography.LocationName:Observe(OnLocationNameChanged)
	X4D.Cartography.MapName:Observe(OnMapNameChanged)
	X4D.Cartography.PlayerPosition:Observe(OnPlayerPositionChanged)	
	X4D.NPCs.NearbyNPCs:Observe(OnNearbyNPCsChanged)
	X4D.UI.CurrentScene:Observe(OnCurrentSceneChanged)	

	-- explicit carto initialization by consumer(s)
	X4D.Cartography:Initialize()
	
	X4D_MiniMap.Took = stopwatch.ElapsedMilliseconds()
end)

EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_PLAYER_ACTIVATED, function()
	X4D.Log:Debug("EVENT_PLAYER_ACTIVATED", "MiniMap")
	StartMiniMapInteractor()
end)
EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_QUEST_COMPLETE, function (...) 
	X4D.Log:Debug("EVENT_QUEST_COMPLETE", "MiniMap")
end)
EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_OBJECTIVE_COMPLETED, function (...) 
	X4D.Log:Debug("EVENT_OBJECTIVE_COMPLETED", "MiniMap")
	ScheduleUpdateForPOIPins()
end)
EVENT_MANAGER:RegisterForEvent("X4D_Cartography", EVENT_ZONE_CHANGED, function()
	X4D.Log:Debug("EVENT_ZONE_CHANGED", "MiniMap")
	ScheduleUpdateForPOIPins()
end)
EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_POIS_INITIALIZED, function(...)
	X4D.Log:Debug("EVENT_POIS_INITIALIZED", "MiniMap")
	ScheduleUpdateForPOIPins()
end)
EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_POI_DISCOVERED, function(...)
	X4D.Log:Debug("EVENT_POI_DISCOVERED", "MiniMap")
	ScheduleUpdateForPOIPins()
end)
EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_POI_UPDATED, function(...)
	X4D.Log:Debug("EVENT_POI_UPDATED", "MiniMap")
	ScheduleUpdateForPOIPins()
end)


-- EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_OBJECTIVE_COMPLETED, function (...) 
-- 	X4D.Log:Information("EVENT_OBJECTIVE_COMPLETED", "MiniMap")
-- 	ScheduleUpdateForPOIPins()
-- end)
--[[

EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_CADWELL_PROGRESSION_LEVEL_CHANGED, function(...)
	X4D.Log:Information("EVENT_CADWELL_PROGRESSION_LEVEL_CHANGED", "MiniMap")
end)
EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_ZONE_UPDATE, function(...)
	X4D.Log:Information("EVENT_ZONE_UPDATE", "MiniMap")
end)

]]