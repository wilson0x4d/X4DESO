
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

local X4D_MiniMap = LibStub:NewLibrary("X4D_MiniMap", "0#VERSION#")
if (not X4D_MiniMap) then
	return
end
local X4D = LibStub("X4D")
X4D.MiniMap = X4D_MiniMap

X4D_MiniMap.NAME = "X4D_MiniMap"
X4D_MiniMap.VERSION = "#VERSION#"

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
local _playerX, _playerY, _playerH = 0, 0, 0
local _cameraH

local _miniMapInteractor

local DEFAULT_PIP_WIDTH = 24
local PLAYER_PIP_WIDTH = 14

local _pipcache = { } -- 'pips' are the controls used in-game, they are recycled
local _pins = { } -- 'pins' are a subset of 'active pips', it may be less than the number of pips in the cache

-- TODO: localize/abstract table keys, I believe these are only valid for an en-US game client
local _npcTypeToTextureLookup = {
	["UNKNOWN"] = { 
		Icon = "esoui/art/progression/progression_tabicon_backup_active.dds",
		ScalingFactor = 1
	},

	-- NPCs 
	["Alchemist"] = { Icon = "EsoUI/Art/Icons/ServiceTooltipIcons/servicetooltipicon_alchemist.dds", ScalingFactor = 1 },
	["Armorer"] = { Icon = "EsoUI/Art/Icons/ServiceTooltipIcons/servicetooltipicon_heavyarmor.dds", ScalingFactor = 1 },
	["Banker"] = { Icon = "EsoUI/Art/Icons/ServiceMapPins/servicepin_bank.dds", ScalingFactor = 0.75 },
	["Blacksmith"] = { Icon = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_craftbag_blacksmithing.dds", ScalingFactor = 0.8 },
	["Brewer"] = { Icon = "EsoUI/Art/Crafting/provisioner_indexIcon_beer_down.dds", ScalingFactor = 1 },
	["Carpenter"] = { Icon = "EsoUI/Art/Icons/ServiceTooltipIcons/servicepin_woodworker_new.dds", ScalingFactor = 1 },
	["Chef"] = { Icon = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_craftbag_provisioning.dds", ScalingFactor = 0.75 },
	["Clothier"] = { Icon = "EsoUI/Art/Icons/ServiceMapPins/servicepin_clothier.dds", ScalingFactor = 0.70 },
	["Enchanter"] = { Icon = "EsoUI/Art/Icons/ServiceTooltipIcons/servicetooltipicon_enchanter.dds", ScalingFactor = 1 },
	["Fence"] = { Icon = "EsoUI/Art/Icons/ServiceMapPins/servicepin_fence.dds", ScalingFactor = 0.75 },
	["Grocer"] = { Icon = "EsoUI/Art/Icons/ServiceTooltipIcons/servicetooltipicon_generalgoods.dds", ScalingFactor = 1 },
	["Hall Steward"] = { Icon = "EsoUI/Art/Icons/ServiceTooltipIcons/servicetooltipicon_hallsteward.dds", ScalingFactor = 1 },
	["Innkeeper"] = { Icon = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_consumables.dds", ScalingFactor = 1 },
	["Leatherworker"] = { Icon = "EsoUI/Art/Icons/ServiceTooltipIcons/servicetooltipicon_mediumarmor.dds", ScalingFactor = 1.15 },
	["Magus"] = { Icon = "EsoUI/Art/Icons/ServiceTooltipIcons/servicetooltipicon_magesguild.dds", ScalingFactor = 1 },
	["Merchant"] = { Icon = "EsoUI/Art/Icons/ServiceMapPins/servicepin_vendor.dds", ScalingFactor = 0.75 },
	["Moneylender"] = { Icon = "EsoUI/Art/Icons/ServiceMapPins/servicepin_bank.dds", ScalingFactor = 0.75 },
	["Mystic"] = { Icon = "EsoUI/Art/Icons/ServiceTooltipIcons/servicepin_arcanist.dds", ScalingFactor = 1 },
	["Stablemaster"] = { Icon = "EsoUI/Art/Icons/ServiceMapPins/servicepin_stable.dds", ScalingFactor = 0.75 },
	["Tailor"] = { Icon = "EsoUI/Art/Icons/ServiceTooltipIcons/servicetooltipicon_lightarmor.dds", ScalingFactor = 1.1 },
	["Weaponsmith"] = { Icon = "EsoUI/Art/Icons/ServiceTooltipIcons/servicetooltipicon_swords.dds", ScalingFactor = 1 },
	["Woodworker"] = { Icon = "EsoUI/Art/Icons/ServiceTooltipIcons/servicepin_woodworker_new.dds", ScalingFactor = 1 },
	["Vendor"] = { Icon = "EsoUI/Art/Icons/ServiceMapPins/servicepin_vendor.dds", ScalingFactor = 0.75 },

	-- these still need review

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

local function CreateMiniMapPin(texture, size)	
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
	pip:SetDimensions(size, size)
	return {
		PIP = pip,
		Texture = texture,
		Size = size
	}
end

local function ConvertNPCToPin(npc, map)
	local texture = _npcTypeToTextureLookup[npc.Type] or _npcTypeToTextureLookup["UNKNOWN"]
	local pipSize = texture.ScalingFactor * DEFAULT_PIP_WIDTH
	local pipCenter = pipSize / 2;
	local pin = CreateMiniMapPin(texture.Icon, pipSize)
	if (pin ~= nil) then
		pin.NPC = npc
		-- local pip = pin.PIP
		-- pip:ClearAnchors()
		-- pip:SetAnchor(TOPLEFT, _tileContainer, CENTER, (npc.Position.X * map.MapWidth) - pipCenter, (npc.Position.Y * map.MapHeight) - pipCenter)
		-- pip:SetHidden(false)
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
		pin.PIP:SetDimensions(pin.Size, pin.Size)
		pin.PIP:ClearAnchors()
		if (pin.Location ~= nil) then
			pin.PIP:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, (pin.Location.X * _currentMap.MapWidth) - (pin.Size/2), (pin.Location.Y * _currentMap.MapHeight) - (pin.Size/2))
			pin.PIP:SetHidden(false)
		elseif (pin.NPC ~= nil) then
			if (pin.NPC.Position ~= nil) then
				pin.PIP:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, (pin.NPC.Position.X * _currentMap.MapWidth) - (pin.Size/2), (pin.NPC.Position.Y * _currentMap.MapHeight) - (pin.Size/2))
				pin.PIP:SetHidden(false)
			else
				X4D.Log:Error("LayoutMapPins cannot access `NPC::Position`", "MiniMap")
				pin.PIP:SetHidden(true)
			end
		elseif (pin.POI ~= nil) then
			if (pin.POI.normalizedX ~= nil and pin.POI.normalizedY ~= nil) then
				pin.PIP:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, (pin.POI.normalizedX * _currentMap.MapWidth) - (pin.Size/2), (pin.POI.normalizedY * _currentMap.MapHeight) - (pin.Size/2))
				pin.PIP:SetHidden(false)
			else
				X4D.Log:Error("LayoutMapPins cannot access `POI::normalizedX`", "MiniMap")
				pin.PIP:SetHidden(true)
			end
		else 
			X4D.Log:Warning({"Unsupported pin during `LayoutMapPins`", pin}, "MiniMap")
		end
	end
end

local X4D_MiniMap_BuildNPCPins = function(pins, map)
	local nearbyNPCs = X4D.NPCs.NearbyNPCs()
	if (nearbyNPCs ~= nil) then
		nearbyNPCs:ForEach(function (npc)
			-- X4D.Log:Debug(npc, "MiniMap")
			local pin = ConvertNPCToPin(npc, map)
			if (pin ~= nil) then
				pins[npc.Key] = pin
			end
		end)
	end
end

local function ConvertPOIMapInfoToPin(poi, currentMap)	
	local pin = CreateMiniMapPin(poi.texture, 1)
	if (pin ~= nil) then
		pin.POI = poi
	end
	return pin
end

local X4D_MiniMap_BuildPOIPins = function(pins, currentMap)
	-- X4D.Log:Verbose("X4D_MiniMap_BuildPOIPins", "MiniMap")
	local zoneIndex = GetCurrentMapZoneIndex()
	local poiCount = GetNumPOIs(zoneIndex)
	for poiIndex = 1, poiCount do
		local normalizedX, normalizedY, pinType, texture, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = GetPOIMapInfo(zoneIndex, poiIndex)
		local pin = ConvertPOIMapInfoToPin({
			normalizedX = normalizedX,
			normalizedY = normalizedY,
			texture = texture
		}, currentMap)		
		pins["poi:"..poiIndex] = pin
	end
end

local function AllocateQuestPins(questInfo, currentMap)	
	local allocatedPins = {}
	if (questInfo.Locations ~= nil) then
		for k,v in pairs(questInfo.Locations) do
			if (v.Pin == nil and v.Icon ~= nil) then
				-- TODO: how to draw "area radius" circles?
				local pin = CreateMiniMapPin(v.Icon, DEFAULT_PIP_WIDTH)
				if (pin ~= nil) then
					pin.Quest = questInfo
					pin.Location = v
					v.Pin = pin
					table.insert(allocatedPins, pin)
					-- X4D.Log:Warning("Allocated Quest Pin", "Quest")
				end
			end
		end
	end
	return allocatedPins
end

local function X4D_MiniMap_BuildJournalQuestPins(pins, currentMap)
	-- X4D.Log:Verbose("X4D_MiniMap_BuildJournalQuestPins", "MiniMap")
	local questInfo = X4D.Quest.TrackedQuest()
	if (questInfo ~= nil) then
		local allocatedPins = AllocateQuestPins(questInfo, currentMap)
		for k,v in pairs(questInfo.Locations) do
			if (v.Pin ~= nil) then
				local exists = pins["quest:"..questInfo.Index..":"..k]
				if (exists ~= nil) then
					exists:SetHidden(true)
					exists:ClearAnchors()
					exists:SetTexture(nil)
				end
				pins["quest:"..questInfo.Index..":"..k] = v.Pin
			end
		end
	end
end

function X4D_MiniMap_RebuildAllPins()
	-- X4D.Log:Warning("X4D_MiniMap_RebuildAllPins")

	if (_currentMap == nil) then
		X4D.Log:Verbose("X4D_MiniMap_RebuildAllPins - `_currentMap` was not set yet", "MiniMap")
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

	-- X4D.Log:Verbose("Rebuilding MiniMap NPC Pins", "MiniMap")
	X4D_MiniMap_BuildNPCPins(pins, _currentMap)

	-- X4D.Log:Verbose("Rebuilding MiniMap POI Pins", "MiniMap")
	X4D_MiniMap_BuildPOIPins(pins, _currentMap)

	-- X4D.Log:Verbose("Rebuilding MiniMap Quest Pins", "MiniMap")
	X4D_MiniMap_BuildJournalQuestPins(pins, _currentMap)

	_pins = pins
	LayoutMapPins()
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
			-- X4D.Log:Debug{"X4D_MiniMap::ScheduleUpdateForPOIPins" }
			X4D_MiniMap_RebuildAllPins()
		end, delayMilliseconds, {}, "X4D_MiniMap::ScheduleUpdateForPOIPins")
		_timerForScheduledUpdatePOIPins:Start(delayMilliseconds)
	end
end

local function UpdatePlayerPip(heading)
	if (_playerPip ~= nil) then
		_playerPip:SetTextureRotation(_cameraH)
	end
end 

local function OnLocationNameChanged(locationName)
	if (_locationNameLabel ~= nil) then
		_locationNameLabel:SetText(locationName)
		_locationNameLabel:SetHidden(X4D.Cartography.LocationName() == X4D.Cartography.MapName())
	else
		X4D.Log:Warning("OnLocationNameChanged - Label Not Ready", "MiniMap")
	end
end

local function OnMapNameChanged(mapName)
	if (_mapNameLabel ~= nil) then
		_mapNameLabel:SetText(mapName)
		_locationNameLabel:SetHidden(X4D.Cartography.LocationName() == X4D.Cartography.MapName())
	else
		X4D.Log:Warning("OnMapNameChanged - Label Not Ready", "MiniMap")
	end
end

local function OnInteractWithMiniMap(timer, state)
	-- X4D.Log:Debug("OnInteractWithMiniMap", "MiniMap")

	if (_currentMap == nil) then
		-- X4D.Log:Debug("OnInteractWithMiniMap - _currentMap is nil", "MiniMap")
		return
	end
	if (_currentMap.MapWidth == nil or _currentMap.MapHeight == nil) then
		-- X4D.Log:Debug("OnInteractWithMiniMap - Map Width/Height Unknown", "MiniMap")
		return
	end
	if (_playerX == nil or _playerY == nil) then
		-- X4D.Log:Debug("OnInteractWithMiniMap - No Player Position", "MiniMap")
		return
	end

	local offsetX = (_playerX * _currentMap.MapWidth) - _centerX
	local offsetY = (_playerY * _currentMap.MapHeight) - _centerY

	-- calc panning position/offsets
	if (offsetX < 0 or offsetX == nil) then
		offsetX = 0
	elseif (offsetX > (_currentMap.MapWidth - (_centerX * 2))) then
		offsetX = (_currentMap.MapWidth - (_centerX * 2))
	end
	if (offsetY < 0 or offsetX == nil) then
		offsetY = 0
	elseif (offsetY > (_currentMap.MapHeight - (_centerY * 2))) then
		offsetY = (_currentMap.MapHeight - (_centerY * 2))
	end
	
	-- X4D.Log:Debug("LayoutTileScroll", "MiniMap")
	_tileContainer:ClearAnchors()
	_tileContainer:SetAnchor(TOPLEFT, _tileScroll, TOPLEFT, -1 * offsetX, -1 * offsetY) -- TODO: need to interpolate

	-- X4D.Log:Debug("LayoutPlayerPip", "MiniMap")
	local playerPipX = (_playerX * _currentMap.MapWidth) - (PLAYER_PIP_WIDTH / 2)
	local playerPipY = (_playerY * _currentMap.MapHeight) - (PLAYER_PIP_WIDTH / 2)
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

local function OnCurrentMapChanged(map)	
	-- X4D.Log:Debug("OnCurrentMapChanged", "MiniMap")
	if (_currentMap == map) then
		return
	end
	_currentMap = map	
	if (_currentMap == nil) then
		return
	end

	-- determine if MiniMap UI initialized yet, or defer processing
	if (_minimapWindow == nil or _tileScroll == nil) then
		X4D.Log:Error("Tile Container Not Ready", "MiniMap")
		return
	end

	-- determine if Tile Dimensions initialized yet, or defer processing
	if (_currentMap.VerticalTileCount == nil or _currentMap.HorizontalTileCount == nil) then
		X4D.Log:Error("Tiles Not Ready", "MiniMap")
		return
	end

	-- layout tiles
	-- X4D.Log:Debug("LayoutTiles", "MiniMap")
	if (map.Tiles == nil) then
		return
	end

	-- small optimization to ensure player position is accurate for map
	_playerX, _playerY, _ = GetMapPlayerPosition("player")

	local offsetX = (_playerX * _currentMap.MapWidth) - _centerX
	local offsetY = (_playerY * _currentMap.MapHeight) - _centerY

	-- calc panning position/offsets
	if (offsetX < 0 or offsetX == nil) then
		offsetX = 0
	elseif (offsetX > (_currentMap.MapWidth - (_centerX * 2))) then
		offsetX = (_currentMap.MapWidth - (_centerX * 2))
	end
	if (offsetY < 0 or offsetX == nil) then
		offsetY = 0
	elseif (offsetY > (_currentMap.MapHeight - (_centerY * 2))) then
		offsetY = (_currentMap.MapHeight - (_centerY * 2))
	end

	X4D_MiniMap_RebuildAllPins()

	-- X4D.Log:Debug("LayoutPlayerPip", "MiniMap")
	local playerPipX = (offsetX + _centerX - (PLAYER_PIP_WIDTH / 2))
	local playerPipY = (offsetY + _centerY - (PLAYER_PIP_WIDTH / 2))
	_playerPip:ClearAnchors()
	_playerPip:SetAnchor(TOPLEFT, _tileContainer, TOPLEFT, playerPipX, playerPipY) -- TODO: need to interpolate

	-- X4D.Log:Debug("LayoutTileScroll", "MiniMap")
	_tileContainer:ClearAnchors()
	_tileContainer:SetAnchor(TOPLEFT, _tileScroll, TOPLEFT, -1 * offsetX, -1 * offsetY) -- TODO: need to interpolate

	-- release old tiles
	if (_tiles ~= nil) then
		for _, tile in pairs(_tiles) do
			tile:SetHidden(true)
		end
	end
	_tiles = nil

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
			tile:SetHidden(true)
		end
	end
	_tiles = tiles

	if (_tiles ~= nil) then
		for _, tile in pairs(_tiles) do
			tile:SetHidden(false)
		end
	end
end

local function InitializeMiniMapWindow()
	_minimapWindow = WINDOW_MANAGER:CreateTopLevelWindow("X4D_MiniMap")
	X4D_MiniMap.Window = _minimapWindow -- NOTE: so that it can be accessed by X4D_MiniMap
	_minimapWindow:SetDimensions(300, 240)
	_minimapWindow:SetAnchor(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, -4, -3)
	X4D.UI.StatusBar.PaddingRight(298)
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
	local isHudScene = scene ~= nil and (scene:GetName() == "hud" or scene:GetName() == "hudui")
	_minimapWindow:SetHidden(not isHudScene)
end

local function OnNearbyNPCsChanged(nearbyNPCs)
	X4D_MiniMap_RebuildAllPins()
end

local function OnCurrentSceneChanged(scene) 
	-- TODO: is this the preferred way to detect hud visibility?
	if (_minimapWindow ~= nil) then
		local isHudScene = scene ~= nil and (scene:GetName() == "hud" or scene:GetName() == "hudui")
		_minimapWindow:SetHidden(not isHudScene)
	end
end	

local function OnTrackedQuestChanged(quest)
	X4D.Log:Debug({"OnTrackedQuestChanged", quest}, "MiniMap")
	X4D_MiniMap_RebuildAllPins()
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
		name = "Enable MiniMap",
		tooltip = "When enabled, a minimap is displayed in the bottom-right of the screen (except when interacting with a HUD/Menu/etc.) |cFF0000This is a beta-grade feature, currently in development. Feel free to use, test, and provide feedback for it.",
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
		EnableMiniMap = true,
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
	X4D.Quest.TrackedQuest:Observe(OnTrackedQuestChanged)

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
EVENT_MANAGER:RegisterForEvent(X4D_MiniMap.NAME, EVENT_ZONE_CHANGED, function()
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