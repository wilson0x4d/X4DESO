local X4D_Cartography = LibStub:NewLibrary("X4D_Cartography", "0#VERSION#")
if (not X4D_Cartography) then
    return
end
local X4D = LibStub("X4D")
X4D.Cartography = X4D_Cartography

X4D_Cartography.IsWorldMapVisible = X4D.Observable(nil) -- when the world map is visible there is functionality we must disable (or enable)

-- current player map, zone and position
X4D_Cartography.IsSubZone = X4D.Observable(nil) -- current is a 'sub zone' (one in which we have to rely on non-standard mechanisms for map determination)
X4D_Cartography.MapIndex = X4D.Observable(nil) -- current map index
X4D_Cartography.MapName = X4D.Observable(nil) -- current map name
X4D_Cartography.MapType = X4D.Observable(nil) -- current map type
X4D_Cartography.LocationName = X4D.Observable(nil) -- current location name
X4D_Cartography.ZoneIndex = X4D.Observable(nil) -- current map zone index
X4D_Cartography.PlayerPosition = X4D.Observable(nil) -- { X: 0, Y: 0, Heading: 0, CameraHeading }

X4D_Cartography.CurrentLocation = X4D.Observable(nil) -- reference to current Location from CurrentMap:Locations
X4D_Cartography.CurrentZone = X4D.Observable(nil) -- reference to current Zone from CurrentMap:Zones
X4D_Cartography.CurrentMap = X4D.Observable(nil) -- reference to current map from Cartography DB

-- debugging helpers (please note, these are ONLY enabled if you've hand-edited the default log level in `X4D_Log.lua`)
if (X4D.Log:IsVerboseEnabled() or X4D.Log:IsDebugEnabled()) then
    local function DebugLogObservable(k, v) if (v == nil) then v = "nil" end X4D.Log:Debug(tostring(k).."="..tostring(v)) end
    X4D_Cartography.IsSubZone:Observe(function (v) DebugLogObservable("IsSubZone", v) end)
    X4D_Cartography.MapIndex:Observe(function (v) DebugLogObservable("MapIndex", v) end)
    X4D_Cartography.MapName:Observe(function (v) DebugLogObservable("MapName", v) end)
    X4D_Cartography.CurrentLocation:Observe(function (v) DebugLogObservable("CurrentLocation", v) end)
    X4D_Cartography.CurrentZone:Observe(function (v) DebugLogObservable("CurrentZone", v) end)
    if (X4D.Log:IsDebugEnabled()) then
        X4D_Cartography.MapType:Observe(function (v) DebugLogObservable("MapType", v) end)
        X4D_Cartography.PlayerPosition:Observe(function (v) DebugLogObservable("PlayerPosition", v) end)
        X4D_Cartography.LocationName:Observe(function (v) DebugLogObservable("LocationName", v) end)
        X4D_Cartography.ZoneIndex:Observe(function (v) DebugLogObservable("ZoneIndex", v) end)
    end
end

local function OnIsWorldMapVisibleChanged(isWorldMapVisible)
    -- while the ZO World Map is visible we want to freeze some state
    if (not isWorldMapVisible) then
        X4D_Cartography.IsSubZone:Thaw()
        X4D_Cartography.MapIndex:Thaw()
        X4D_Cartography.MapName:Thaw()
        X4D_Cartography.MapType:Thaw()
        X4D_Cartography.LocationName:Thaw()
        X4D_Cartography.ZoneIndex:Thaw()
        X4D_Cartography.PlayerPosition:Thaw()
        X4D_Cartography.CurrentLocation:Thaw()
        X4D_Cartography.CurrentZone:Thaw()
        X4D_Cartography.CurrentMap:Thaw()
    else
        X4D_Cartography.IsSubZone:Freeze()
        X4D_Cartography.MapIndex:Freeze()
        X4D_Cartography.MapName:Freeze()
        X4D_Cartography.MapType:Freeze()
        X4D_Cartography.LocationName:Freeze()
        X4D_Cartography.ZoneIndex:Freeze()
        X4D_Cartography.PlayerPosition:Freeze()
        X4D_Cartography.CurrentLocation:Freeze()
        X4D_Cartography.CurrentZone:Freeze()
        X4D_Cartography.CurrentMap:Freeze()
    end
end
X4D_Cartography.IsWorldMapVisible:Observe(OnIsWorldMapVisibleChanged)

local _currentMapTile
local _currentLocationName

local _mapScaleOverrides = {
    ["map:stonefallsoutlawrefuge_base"] = 0.35,
    ["map:morkhazgur_base"] = 0.5,
}
local DEFAULT_MINIMAP_SCALE = 0.25
local function X4D_Cartography_GetMapScale(mapIndex)
    if (mapIndex == nil) then
        return nil
    end
    local mapKey = "map:"..mapIndex
    local mapScaleOverride = _mapScaleOverrides[mapKey]
    if (mapScaleOverride ~= nil) then
        -- NOTE: prefer override in selection, but, should use only when required
        return mapScaleOverride
    elseif (tonumber(mapIndex) ~= nil) then
        -- TODO: there is probably an API call we could make to identify these maps
        return (DEFAULT_MINIMAP_SCALE * 5)
    elseif (X4D_Cartography.IsSubZone()) then
        return (DEFAULT_MINIMAP_SCALE * 2)
    else
        return  DEFAULT_MINIMAP_SCALE
    end
end

local function RefreshCurrentMapAndZoneAndLocation()
    local ts = GetTimeStamp()
    local mapIndex = X4D.Cartography.MapIndex()
    if (mapIndex == nil) then
        -- when mapIndex is null, there is no current map
        return nil
    end
    local mapName = X4D.Cartography.MapName()
    local isSubZone = X4D.Cartography.IsSubZone()

    local dirty = false
    local map = X4D_Cartography.DB:Find(mapIndex)
    if (map == nil or map.CreatedAt == nil or (ts - map.CreatedAt) > 30) then -- 30sec TTL
        dirty = true
        map = {
            CreatedAt = ts,
            MapIndex = mapIndex,
            MapName = zo_strformat("<<1>>", mapName),
            HorizontalTileCount = nil,
            VerticalTileCount = nil,
            Tiles = {},
            Zones = {},
            Locations = {},
            IsSubZone = isSubZone
        }

        local currentZone = nil
        local currentZoneIndex = GetCurrentMapZoneIndex()
        local mapZones = X4D.DB:Open(map.Zones)
        local playerDifficultyLevel = GetPlayerDifficultyLevel()
        for zoneIndex = 1, GetNumZonesForDifficultyLevel(playerDifficultyLevel) do                                        
            local zone = {
                MapIndex = mapIndex,
                ZoneIndex = zoneIndex,
                Description = GetZoneDescription(zoneIndex),
            }
            mapZones:Add(zoneIndex, zone)
            if (zoneIndex == currentZoneIndex) then
                currentZone = zone
            end
        end               
        X4D_Cartography.CurrentZone(currentZone)

        local currentLocation = nil
        local currentLocationName = GetPlayerLocationName()
        local mapLocations = X4D.DB:Open(map.Locations)
        for locationIndex = 1, GetNumMapLocations() do
            local iconFilename, iconWidth, iconHeight = GetMapLocationIcon(locationIndex)
            local locationName = GetLocationName(locationIndex)
            local location = {
                MapIndex = mapIndex,
                LocationIndex = locationIndex,
                Name = locationName,
                LocationX = iconX,
                LocationY = iconY,
                Icon58 = X4D.Icons:ToIcon58(iconFilename),
            }
            mapLocations:Add(locationIndex, location)
            if (locationName == currentLocationName) then
                currentLocation = location
            end
        end
        X4D_Cartography.CurrentLocation(currentLocation)

        if (GetCurrentMapIndex() == mapIndex or isSubZone) then
            local mapTiles = X4D.DB:Open(map.Tiles)
            if (mapTiles:Count() == 0) then
                local numHorizontalTiles, numVerticalTiles = GetMapNumTiles()
                if (numHorizontalTiles ~= nil and numVerticalTiles ~= nil) then
                    for i = 1, (numVerticalTiles * numHorizontalTiles) do
                        local tileTexture = GetMapTileTexture(i)
                        if (tileTexture ~= nil) then
                            mapTiles:Add(i, tileTexture)
                        end
                    end
                end

                if (map.TileWidth == nil or map.TileHeight == nil) then
                    local mapAspectRatio = numHorizontalTiles / numVerticalTiles
                    map.TileWidth = 1280 / numHorizontalTiles
                    local mapScale = X4D_Cartography_GetMapScale(mapIndex)
                    if (mapScale ~= nil and mapScale > 0) then
                        map.TileWidth = map.TileWidth * mapScale
                        --X4D.Log:Warning("Applying map scale: "..mapScale.." for an effective map size of "..(1280 * mapScale), "Quest")
                    end
                    map.TileHeight = map.TileWidth * mapAspectRatio
                    if (map.TileWidth ~= nil and map.TileHeight ~= nil) then
                        map.MapWidth = map.TileWidth * numHorizontalTiles
                        map.MapHeight = map.TileHeight * numVerticalTiles
                        -- X4D.Log:Warning({"GetMapNumTiles", numHorizontalTiles, numVerticalTiles, map.MapWidth, map.MapHeight }, "")
                    end
                end
                -- NOTE: this is done last so consumers can know that the above tile allocation is complete
                map.VerticalTileCount = numVerticalTiles
                map.HorizontalTileCount = numHorizontalTiles
            end
        end
    end
    if (dirty) then
        X4D_Cartography.DB:Add(mapIndex, map)
    end
    X4D_Cartography.CurrentMap(map)
end

local _zoneMapLookup = {

}

local function GetMapIndexByZoneIndex(zoneIndex)
    local gcmi = GetCurrentMapIndex()
    if (zoneIndex == nil) then
        X4D.Log:Error("Received nil value for 'zoneIndex', attempting to fallback on GCMI()")
        return gcmi -- blind attempt to fall back on the game for a valid map index - may fail, this is why we log above - this only exists because i'm not yet sure if it's ever possible to receive a nil value for current map zone index api call and it is NOT an ideal case
    end
    local mapIndex = _zoneMapLookup[zoneIndex]
    if (mapIndex == nil) then
        if (gcmi == nil) then
            mapIndex = _currentMapTile
        else
            mapIndex = gcmi
        end
    end
    return mapIndex
end

local function TryUpdateMapState(timer, state)
    local isWorldMapVisible = SCENE_MANAGER:IsShowing("worldMap") or SCENE_MANAGER:IsShowing("gamepad_worldMap")
    X4D_Cartography.IsWorldMapVisible(isWorldMapVisible)
    if (isWorldMapVisible) then
        -- NOP: do not update state when map is open
        return
    end

    -- relying on map tile and location name changes to determine if there was a map/zone change before updating relevant properties - not crucial, just an optimization
    local locationName = GetPlayerLocationName()
    X4D_Cartography.LocationName(locationName)
    local mapTile = GetMapTileTexture()
    if (mapTile ~= nil) then
        mapTile = mapTile:match("maps/[%w%-]+/(.-)_0.dds")
    end
    
    local zoneIndex = GetCurrentMapZoneIndex()
    local mapIndex = GetMapIndexByZoneIndex(zoneIndex)
    if (_currentMapIndex ~= mapIndex or _currentMapTile ~= mapTile or _currentLocationName ~= locationName) then
        _currentMapIndex = mapIndex
        _currentMapTile = mapTile
        _currentLocationName = locationName
        local mapType = GetMapType()
        X4D_Cartography.MapType(mapType)
	    X4D_Cartography.IsSubZone(tonumber(mapIndex) == nil or mapType == 1)
        X4D_Cartography.MapIndex(mapIndex)
        X4D_Cartography.ZoneIndex(zoneIndex)
        X4D_Cartography.MapName(GetMapName())
        -- NOTE: this MUST ALWAYS be done last
        -- NOTE: a deferral was introduced to deal with a small load delay that may have been resposible for incorrect tile sizing
        X4D.Async:Defer("X4D_Cartography//RefreshCurrentMapAndZoneAndLocation", 250, RefreshCurrentMapAndZoneAndLocation)
    end

    --X4D.Log:Debug("TryUpdateMapState -> ZO_WorldMap_UpdateMap")
    if (SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED) then
        -- local mapMode = ZO_WorldMap_GetMode()
        -- ZO_WorldMap_UpdateMap(mapMode)
        -- CALLBACK_MANAGER:FireCallbacks("OnWorldMapModeChanged", mapMode)
        CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged", 1)
    end
end

local function TryUpdatePlayerPosition(timer, state)
    local playerX, playerY, playerHeading = GetMapPlayerPosition("player")
    local cameraHeading = GetPlayerCameraHeading()
    -- NOTE: this checksum only exists to rate-limit the observable, normally the
    --       observable would not fire a change event in the case of no change, but,
    --       in this case the object reference would have change and the current
    --       observable implementation does not have a mechanism for deep compares.
    --
    --       since much code is driven from position changes, this is justified.
    local playerStateChecksum = playerX + playerY + playerHeading + cameraHeading
    if (state.Checksum ~= playerStateChecksum) then
        state.Checksum = playerStateChecksum
        X4D_Cartography.PlayerPosition({
            X = playerX,
            Y = playerY,
            Heading = playerHeading,
            CameraHeading = cameraHeading
        })
    end
end

local _timer

EVENT_MANAGER:RegisterForEvent("X4D_Cartography", EVENT_ADD_ON_LOADED, function(event, name)
    if (name ~= "X4D_Core") then
        return
    end
    X4D_Cartography.DB = X4D.DB:Open("X4D_Cartography")
end)

function X4D_Cartography:Initialize()
    if (_mapTimer == nil) then
        _mapTimer = X4D.Async:CreateTimer(TryUpdateMapState):Start(1000/10, {}, "X4D_Cartography::TryUpdateMapState")
    end
    if (_playerTimer == nil) then
        _playerTimer = X4D.Async:CreateTimer(TryUpdatePlayerPosition):Start(1000/20, {}, "X4D_Cartography::TryUpdatePlayerPosition")
    end
end

local function OnInteraction(id, result, unitName)
    -- NOTE: this is a bit brittle, but, this event fires "too soon" for us to rely on 
    --       "interact" target for reliable information, so we perform a deferral here
    --       take note that the deferral key is the TAG and not the UNIT NAME, this is 
    --       important if you wish to share this deferral in any other module.
    X4D.Log:Debug({"EVENT_CLIENT_INTERACT_RESULT", id, result, unitName}, "Cartography")
    X4D.Async:Defer("X4D_Cartography/OnInteraction", 850, function()
        X4D.NPCs:GetOrCreate("interact")
    end)
end 

EVENT_MANAGER:RegisterForEvent(X4D_Cartography.NAME, EVENT_CLIENT_INTERACT_RESULT, OnInteraction)

--EVENT_MANAGER:RegisterForEvent(X4D_Cartography.NAME, EVENT_PLAYER_ACTIVATED, function()
--end)
--EVENT_MANAGER:RegisterForEvent("X4D_Cartography", EVENT_QUEST_POSITION_REQUEST_COMPLETE, function()
--	X4D.Log:Warning{"X4D_Cartography::EVENT_QUEST_POSITION_REQUEST_COMPLETE"}
--end)
--CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function()
--	X4D.Log:Warning{"X4D_Cartography::OnWorldMapChanged"}
--end)

--[[
* GetMapFloorInfo()
** _Returns:_ *luaindex* _currentFloor_, *integer* _numFloors_

* SetMapFloor(*luaindex* _desiredFloorIndex_)
** _Returns:_ *[SetMapResultCode|#SetMapResultCode]* _setMapResult_
]]
