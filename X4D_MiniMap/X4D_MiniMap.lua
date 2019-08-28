
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
local _worldMapInteractor

local DEFAULT_PIP_WIDTH = 20

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

local function ConvertNPCToPin(npc, sequence, map)
	if (npc.IsFence) then
		-- NOTE: "fence" NPCs appear as "ZO WorldMap Pins", thus, we exclude them by returning nil
		X4D.Log:Debug{"ConvertNPCToPin !Excluded!", sequence, npc}
		return nil
	end
--	X4D.Log:Warning{ "ConvertNPCToPin", npc.Name, npc.Position, npc}

	local textureName = _npcTypeToTextureNameLookup[npc.Type] or _npcTypeToTextureNameLookup["UNKNOWN"]

	-- every "X4D MiniMap Pin" has a corresponding texture, currently loaded into a single CT_TEXTURE control
    local pip = _pipcache["pip:"..sequence]
	if (pip == nil) then
		pip = WINDOW_MANAGER:CreateControl(nil, _tileContainer, CT_TEXTURE)
		pip:SetDrawLayer(DL_BACKGROUND)
		pip:SetDrawTier(DT_MEDIUM)
		pip:SetTextureReleaseOption(RELEASE_TEXTURE_AT_ZERO_REFERENCES)
		_pipcache["pip:"..sequence] = pip
	end
	-- NOTE: just because we're using a cached pip does not mean it has the state we require
	pip:SetTexture(textureName)
	pip:SetDimensions(DEFAULT_PIP_WIDTH, DEFAULT_PIP_WIDTH) -- TODO: reset dimensions whenever zoom-level/position changes?
	pip:ClearAnchors()
	pip:SetAnchor(TOPLEFT, _tileContainer, CENTER, (npc.Position.X * map.MapWidth) - (DEFAULT_PIP_WIDTH/2), (npc.Position.Y * map.MapHeight) - (DEFAULT_PIP_WIDTH/2))
	pip:SetHidden(false)

	return {
		PIP = pip, 
		NPC = npc,
		Texture = textureName,
		Size = DEFAULT_PIP_WIDTH,
	}
end

local _gameNotReady = false
local function ConvertPOIToPin(poi, sequence, map)
	-- `poi` == `m_pin` from worldmap
	if (poi.__x4d_ignore) then
--		X4D.Log:Information("ConvertPOIToPin was optimized away.")
		return nil
	end
	if (poi:IsUnit()) then
		-- TODO: add support for these? does this include group members?
		-- X4D.Log:Verbose{"ConvertWorldMapPinToMiniMapPin !EXCLUDE! IS_UNIT", sequence, poi}
		-- poi.__x4d_excluded = true
		return nil
	end
	local zoPinType = poi:GetPinType()
	if (zoPinType == nil or zoPinType == "") then
 		X4D.Log:Error{"ConvertPOIToPin", sequence, "pinType=(nil)" }
		_gameNotReady = true
		if (poi.__x4d_retry) then
			poi.__x4d_ignore = true --optimization for next call
		else
			poi.__x4d_retry = true --allow for one retry per poi before giving up on the failing poi
		end
		return nil
	end
	local zoPinData = ZO_MapPin.PIN_DATA[zoPinType]
	if (zoPinData == nil) then
		X4D.Log:Verbose{"ConvertPOIToPin", sequence, "zoPinData=(nil)", zoPinType, poi }
		return nil
	end

	local zoPinTexture = zoPinData.texture
	if (type(zoPinTexture) == "function") then
		zoPinTexture = zoPinTexture(poi)
	end
	if (type(zoPinTexture) == "table") then
		zoPinTexture = zoPinTexture[1] -- not certain this is something we need to do..
	end
	local size = (zoPinData.size or zoPinData.minSize or 64) / 1.47 -- NOTE: this is an approximation that seems to scale default map textures well enough

	-- here we apply some exclusions because we intend to map certain pins separate from ZO (otherwise they appear as dupes on the map)
	-- TODO: when inside a hideout, do not render fence POI, but when outside of a hideout, rander hideout POI
	if (zoPinTexture:EndsWith("_vendor.dds") or zoPinTexture:EndsWith("_bank.dds") or zoPinTexture:EndsWith("_inn.dds") or zoPinTexture:EndsWith("_woodworking.dds") or zoPinTexture:EndsWith("_alchemy.dds")  or zoPinTexture:EndsWith("_stable.dds")) then
		X4D.Log:Debug{"ConvertPOIToPin !ExcludedByDesign!", sequence, zoPinType, zoPinTexture, size, zoPinData}
		poi.__x4d_ignore = true --optimization for next call
		return nil
	end
    local pip = _pipcache[sequence]
	if (pip == nil) then
		pip = WINDOW_MANAGER:CreateControl(nil, _tileContainer, CT_TEXTURE)
		pip:SetDrawLayer(DL_BACKGROUND)
		pip:SetDrawTier(DT_MEDIUM)
		pip:SetTextureReleaseOption(RELEASE_TEXTURE_AT_ZERO_REFERENCES)
		_pipcache[sequence] = pip
	end
	pip:SetTexture(zoPinTexture)		
	pip:SetDimensions(size, size) -- TODO: reset dimensions whenever soom-level/position changes?
	pip:ClearAnchors()
	pip:SetAnchor(TOPLEFT, _tileContainer, CENTER, (poi.normalizedX * map.MapWidth) - (size/2), (poi.normalizedY * map.MapHeight) - (size/2))
	pip:SetHidden(false)
	return {
		PIP = pip, 
		POI = poi,
		Texture = zoPinTexture,
		Size = size,
	}
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
		pin.PIP:SetDimensions(pin.Size or pinPipWidth, pin.Size or pinPipWidth)
		pin.PIP:ClearAnchors()
		if (pin.NPC ~= nil) then
			pin.PIP:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, (pin.NPC.Position.X * _currentMap.MapWidth) - (pinPipWidth/2), (pin.NPC.Position.Y * _currentMap.MapHeight) - (pinPipWidth/2))
		elseif (pin.POI ~= nil) then
			pin.PIP:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, (pin.POI.normalizedX * _currentMap.MapWidth) - (pinPipWidth/2), (pin.POI.normalizedY * _currentMap.MapHeight) - (pinPipWidth/2))
		end
		pin.PIP:SetHidden(false)
--		X4D.Log:Verbose{"LayoutMapPins", pin.NPC.Position.X, pin.NPC.Position.Y, pinPipWidth}
	end
end

function RebuildMiniMapPins()
	-- X4D.Log:Debug("RebuildMiniMapPins")

	_gameNotReady = false

	-- reclaim pin controls
	local pins = _pins
	if (pins ~= nil) then
		for _,pin in pairs(pins) do
			ReclaimPin(pin)
		end
	end

	local sequence = 0
	local pins = { }

	local nearbyNPCs = X4D.NPCs.NearbyNPCs()
	if (nearbyNPCs ~= nil) then
		-- X4D.Log:Debug("Enumerating Nearby NPCs", "MiniMap")
		nearbyNPCs:ForEach(function (npc)
			sequence = sequence + 1
			local pin = ConvertNPCToPin(npc, sequence, _currentMap)
			if (pin ~= nil) then
				pins["pip:"..sequence] = pin
			end
		end)
	end

	-- TODO: perform this only once when map changes, before processing NPCs, if we then record "start sequence #" from POIs processed we can perform NPC (re-)processing without much concern for the POIs (which should be relatively static for the current map)
	local poiCount = ZO_WorldMapContainer:GetNumChildren()
	for poiIndex=1,poiCount do
		local worldMapContainerChild = ZO_WorldMapContainer:GetChild(poiIndex)
		if (worldMapContainerChild.m_Pin ~= nil) then
			sequence = sequence + 1
			local pin = ConvertPOIToPin(worldMapContainerChild.m_Pin, sequence, _currentMap)
			if (pin ~= nil) then
				table.insert(pins, pin)
			elseif (_gameNotReady) then
				ScheduleUpdateForPOIPins()
				X4D.Log:Warning("RecalculateMiniMapPinsAsync - game was not ready for ConvertPOIToPin call sequence #"..sequence)
				return
			else
				sequence = sequence - 1 -- ensure we use correct pipcache slot on next POI, since some POIs may not be rendered
			end
		end
	end

	_pins = pins
	LayoutMapPins()
end

local function ResetWorldMapPinExclusions()
	-- NOTE: this ensures that when we change the current map, zone, location, OR when we detect unexpected game state/etc we attempt to create state for all "ZO World Map Pins" (aveoi 'false exclusions' due to caching)
	local poiCount = ZO_WorldMapContainer:GetNumChildren()
	for poiIndex=1,poiCount do
		local worldMapContainerChild = ZO_WorldMapContainer:GetChild(poiIndex)
		if (worldMapContainerChild.m_Pin ~= nil) then
			worldMapContainerChild.m_Pin.__x4d_ignore = nil
		end
	end	
end

local _timerForScheduledUpdateNPCPins = nil
ScheduleUpdateForPOIPins = function ()
	if (_timerForScheduledUpdateNPCPins == nil) then
		_timerForScheduledUpdateNPCPins = X4D.Async:CreateTimer(function (timer, state) 
			timer:Stop()
			X4D.Log:Verbose{"X4D_MiniMap::ScheduleUpdateForPOIPins"}
			-- NOTE: this misnomer exists due to a series of refactors
			RecalculateMiniMapPinsAsync()
		end, 850, {}, "X4D_MiniMap::ScheduleUpdateForPOIPins")
	end
	_timerForScheduledUpdateNPCPins:Start()
end

local taskOnNearbyNPCsChanged = nil
local function OnNearbyNPCsChanged(nearbyNPCs)
	if (taskOnNearbyNPCsChanged == nil) then
		taskOnNearbyNPCsChanged = X4D.Async:CreateTimer(function(timer, state)
			if (_currentMap ~= nil and _lastPinPipWidth ~= nil) then -- only reason we go async is to wait for state to pop
				timer:Stop()
				RecalculateMiniMapPinsAsync()
				taskOnNearbyNPCsChanged = nil
			end
		end, 250, nearbyNPCs, "X4D_MiniMap::OnNearbyNPCsChanged"):Start()
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

	end
	end

local _lastPlayerPipWidth = 0
local function UpdateZoomPanState(timer, state)
	_zoomPanState = state
	state.map = _currentMap
	local map = _currentMap
	if (map == nil or state == nil or _tiles == nil) then
--		this is an expected case, we effectively wait for state pop
--		X4D.Log:Verbose { "UpdateZoomPanState", "map, state or tiles are nil", map == nil, state == nil, _tiles == nil }
		return
	end
	-- NOTE: no longer dynamically changing zoom-level, this will be made a user-setting instead, following code was old behavior
	-- state.ZoomIncrement = state.ZoomIncrement * 0.01
	-- if (state.ZoomIncrement <= 0.01) then
	--    state.ZoomIncrement = 0.01
	-- end
	-- local maxZoomLevel = _maxZoomLevel
	-- if (map.MaxZoomLevel ~= nil) then
	--    maxZoomLevel = map.MaxZoomLevel
	-- elseif (X4D.Cartography.IsSubZone()) then
	--    maxZoomLevel = 1
	-- end
	-- state.ZoomLevel = state.ZoomLevel + state.ZoomIncrement
	-- if (state.ZoomLevel >= maxZoomLevel) then
	--    state.ZoomLevel = maxZoomLevel
	-- end

	if ((_playerX ~= nil and _playerY ~= nil) and ((_playerX ~= _lastPlayerX or _playerY ~= _lastPlayerY))) then
--		if (_tileContainer ~= nil) then
--			local zoomLevel = state.ZoomLevel -- base zoom level (user)
--			_tileContainer:SetScale(zoomLevel)
--		end
		_lastPlayerX = _playerX
		_lastPlayerY = _playerY

		-- pip size for current zoom level -- TODO: this should be calculated when zoom level changes and cached inside ZoomPanState (optimization)
		local playerPipWidth = _maxPlayerPipWidth * _zoomPanState.ZoomLevel
		if (player ~= _lastPlayerPipWidth) then
			 _lastPlayerPipWidth = playerPipWidth
			_playerPip:SetDimensions(playerPipWidth, playerPipWidth)
		end

		if (map.MapWidth ~= nil and map.MapHeight ~= nil) then
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
			
			_tileContainer:ClearAnchors()
			_tileContainer:SetAnchor(TOPLEFT, _tileScroll, TOPLEFT, -1 * offsetX, -1 * offsetY) -- TODO: need to interpolate

			local pipX = (offsetX + _centerX - (playerPipWidth / 2))
			local pipY = (offsetY + _centerY - (playerPipWidth / 2))
			_playerPip:ClearAnchors()
			_playerPip:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, pipX, pipY) -- TODO: need to interpolate
		end
	end
end

local function StartMiniMapInteractor()
	-- auto-zoom/pan map
	if (_miniMapInteractor == nil) then
		_miniMapInteractor = X4D.Async:CreateTimer(OnInteractWithMiniMap, 1000/16, { }, "X4D_MiniMap::ZoomPanController")
	end
	_miniMapInteractor:Start()
end

local function StartWorldMapController()
	-- test world map
	if (_mapControllerTimer == nil) then
		_mapControllerTimer = X4D.Async:CreateTimer(function(timer, state)
		    local isWorldMapVisible = SCENE_MANAGER:IsShowing("worldMap") or SCENE_MANAGER:IsShowing("gamepad_worldMap")
			if (isWorldMapVisible or _playerX == 0 or _playerY == 0) then
				return
			end
			if ((_playerX <= 0.04 or _playerX >= 0.96) or (_playerY <= 0.04 or _playerY >= 0.96)) then
				if (MapZoomOut() == SET_MAP_RESULT_MAP_CHANGED) then
					X4D.Log:Verbose{"FIRE! MapZoomOut"}
					CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
				end
			else
				if (ProcessMapClick(_playerX, _playerY) == SET_MAP_RESULT_MAP_CHANGED) then
					X4D.Log:Verbose{"FIRE! ProcessMapClick"}
					CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
				end
			end
			UpdatePlayerPositionLabel()
		end, 250, { }, "X4D_MiniMap::WorldMapController"):Start()
	end
end
		
local function StartWorldMapInteractor()
	if (_worldMapInteractor ~= nil) then
		_worldMapInteractor:Stop()
	else
		_worldMapInteractor = X4D.Async:CreateTimer(OnInteractWithWorldMap, 250, { }, "X4D_MiniMap::WorldMapInteractor")
	end
	_worldMapInteractor:Start()
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
	timer:Stop()
	local map = state.Map or _currentMap
	if (_minimapWindow == nil or _tileScroll == nil) then
		X4D.Log:Error("Tile Container not initialized", "MiniMap")
		return
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
	-- allocate new tiles
	_tiles = { }
	if (map ~= nil) then
		-- layout map container and related
		map.TileWidth, map.TileHeight = X4D.Cartography:GetTileDimensions(map.Tiles[1])
		local minimimScalingFactor = (_tileScroll:GetWidth() / map.HorizontalTileCount) / map.TileWidth -- aka. "scale-to-fit viewport"
		map.ScalingFactor = _customMapScalingFactors[map.MapId] or 1
		if (map.ScalingFactor < minimimScalingFactor) then
			map.ScalingFactor = minimimScalingFactor
		end
		map.TileWidth, map.TileHeight = map.TileWidth * map.ScalingFactor, map.TileHeight * map.ScalingFactor
		map.MapWidth = map.TileWidth * map.HorizontalTileCount
		map.MapHeight = map.TileHeight * map.VerticalTileCount
--		X4D.Log:Verbose { "MiniMap!OnCurrentMapChanged", _currentMapId, _currentZoneIndex, map.IsSubZone, map.MapWidth, map.MapHeight, map.ScalingFactor  }

		_tileContainer:SetDimensions(map.MapWidth, map.MapHeight)

		-- layout map tiles
		if (map.Tiles ~= nil) then
			for tileRow = 0,(map.VerticalTileCount - 1) do
				for tileCol = 0,(map.HorizontalTileCount - 1) do
					local tileIndex = (tileRow * map.HorizontalTileCount) + (tileCol + 1)
					local tileFilename = map.Tiles[tileIndex]
					local tile = WINDOW_MANAGER:GetControlByName("TILE" .. tileIndex)
					if (tile == nil) then
						tile = WINDOW_MANAGER:CreateControl("TILE" .. tileIndex, _tileContainer, CT_TEXTURE)
					end
					tile:SetHidden(false)
					tile:SetTexture(tileFilename)
					tile:SetTextureReleaseOption(RELEASE_TEXTURE_AT_ZERO_REFERENCES)
					tile:SetDimensions(map.TileWidth, map.TileHeight)
					tile:ClearAnchors()
					tile:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, tileCol * map.TileWidth, tileRow * map.TileHeight)
					tile:SetDrawLayer(DL_BACKGROUND)
					tile:SetDrawTier(DT_LOW)
					tile:SetDrawLevel(DL_BELOW)
					table.insert(_tiles, tile)
	-- layout tiles
	-- X4D.Log:Debug("LayoutTiles", "MiniMap")
	if (map.Tiles ~= nil) then
				end
			end
		end

		-- layout map pins, ideally we only do this once if the state defaults are never changed
		LayoutMapPins(_zoomPanState)
	end
end
local function OnCurrentMapChanged(map)	
	if (_currentMap ~= map) then
		_currentMap = map
		ResetWorldMapPinExclusions()
		ScheduleUpdateForPOIPins()
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
	_playerPip:SetDimensions(DEFAULT_PIP_WIDTH-4, DEFAULT_PIP_WIDTH-4)
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
	
	StartMiniMapInteractor()
	StartWorldMapInteractor()


	X4D_MiniMap.Took = stopwatch.ElapsedMilliseconds()
end)

EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_PLAYER_ACTIVATED, function()
	X4D.Log:Debug("EVENT_PLAYER_ACTIVATED", "MiniMap")
	StartMiniMapInteractor()
	StartWorldMapInteractor()
end)
EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_QUEST_COMPLETE, function (...) 
	X4D.Log:InformDebugation("EVENT_QUEST_COMPLETE", "MiniMap")
	ScheduleUpdateForPOIPins()
end)
EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_OBJECTIVE_COMPLETED, function (...) 
	X4D.Log:Debug("EVENT_OBJECTIVE_COMPLETED", "MiniMap")
	ScheduleUpdateForPOIPins()
end)
EVENT_MANAGER:RegisterForEvent("X4D_Cartography", EVENT_ZONE_CHANGED, function()
	X4D.Log:Debug("EVENT_ZONE_CHANGED", "MiniMap")
	ResetWorldMapPinExclusions()
	ScheduleUpdateForPOIPins()
end)
