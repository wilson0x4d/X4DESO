local X4D_Cartography = LibStub:NewLibrary("X4D_Cartography", 1015)
if (not X4D_Cartography) then
    return
end
local X4D = LibStub("X4D")
X4D.Cartography = X4D_Cartography

-- current player map, zone and position
X4D_Cartography.IsSubZone = X4D.Observable(nil) -- current is a 'sub zone' (one in which we have to rely on non-standard mechanisms for map determination)
X4D_Cartography.MapIndex = X4D.Observable(nil) -- current map index
X4D_Cartography.MapName = X4D.Observable(nil) -- current map name
X4D_Cartography.LocationName = X4D.Observable(nil) -- current location name
X4D_Cartography.ZoneIndex = X4D.Observable(nil) -- current map zone index
X4D_Cartography.PlayerX = X4D.Observable(0) -- player position (x-coordinate)
X4D_Cartography.PlayerY = X4D.Observable(0) -- player position (y-coordinate)
X4D_Cartography.PlayerHeading = X4D.Observable(0) -- player heading
X4D_Cartography.CameraHeading = X4D.Observable(0) -- camera heading

X4D_Cartography.CurrentMap = X4D.Observable(nil) -- reference to current map from Cartography DB

local _currentMapTile
local _currentLocationName

local _private_texture
function X4D_Cartography:GetTileDimensions(filename)
     if (_private_texture == nil) then
        return nil, nil
     end
    _private_texture:SetTexture(filename)
    return _private_texture:GetTextureFileDimensions()
end

function X4D_Cartography:GetCurrentMap()
    --[[
        TODO: "zone fencing" to auto-detect the need for a map transition, each can have zero or more fences, each fence being a collection of coordinates in clockwise order which form a closed loop
    ]]
    local mapIndex = X4D.Cartography.MapIndex()
    if (mapIndex == nil) then
        -- when mapIndex is null, there is no current map
        return nil
    end
    local mapName = X4D.Cartography.MapName()
    local isSubZone = X4D.Cartography.IsSubZone()

    local dirty = false
    local map = X4D.Cartography.DB:Find(mapIndex)
    if (map == nil) then
        dirty = true
        map = {
            MapIndex = mapIndex,
            MapName = zo_strformat("<<1>>", mapName),
            HorizontalTileCount = nil,
            VerticalTileCount = nil,
            Tiles = {},
            Zones = {},
            Locations = {},
            IsSubZone = tonumber(mapIndex) == nil
        }
        local mapZones = X4D.DB:Create(map.Zones)
        if (mapZones:Count() == 0) then
            -- not tested and/or bugged temporarily removed
            --if (isSubZone) then
            --    -- do not enumerate zones
            --    local zoneIndex = GetCurrentMapZoneIndex()
            --    local zoneKey = mapIndex .. "-" .. zoneIndex
            --    local zone = {
            --        MapIndex = mapIndex,
            --        ZoneIndex = mapIndex,
            --        Description = GetZoneDescription(zoneIndex),
            --    }
            --    mapZones:Add(zoneKey, zone)
            --else
            --    -- enumerate zones
            --    for zoneIndex = 1, GetNumZonesForDifficultyLevel(difficulty) do
            --        local zoneKey = mapIndex .. "-" .. zoneIndex
            --        local zone = {
            --            MapIndex = mapIndex,
            --            ZoneIndex = zoneIndex,
            --            Description = GetZoneDescription(zoneIndex),
            --        }
            --        mapZones:Add(zoneKey, zone)
            --    end
            --end
        end
        local mapLocations = X4D.DB:Create(map.Locations)
        if (mapLocations:Count() == 0) then
--            -- attempt to enumerate locations
--            for locationIndex = 1, GetNumMapLocations() do
--                -- location icon
--                local iconFilename, iconWidth, iconHeight = GetMapLocationIcon(locationIndex)

--            --    X4D.Log:Warning{GetMapLocation(locationIndex)}
--            --    local locationKey = mapIndex .. "-" .. locationIndex
--            --    local iconFilename, iconX, iconY = GetMapLocationIcon(locationIndex)
--            --    local locationName = GetLocationName(locationIndex)
--            --    local location = {
--            --        MapIndex = mapIndex,
--            --        LocationIndex = locationIndex,
--            --        Name = locationName,
--            --        LocationX = iconX,
--            --        LocationY = iconY,
--            --        Icon58 = X4D.Icons:ToIcon58(iconFilename),
--            --    }
--            --    mapLocations:Add(locationKey, location)
--            end
        end
        if (GetCurrentMapIndex() == mapIndex or isSubZone) then
            local mapTiles = X4D.DB:Create(map.Tiles)
            if (mapTiles:Count() == 0) then
                local numHorizontalTiles, numVerticalTiles = GetMapNumTiles()
                if (numHorizontalTiles ~= nil and numVerticalTiles ~= nil) then
                    map.VerticalTileCount = numVerticalTiles
                    map.HorizontalTileCount = numHorizontalTiles
                    for i = 1, (map.VerticalTileCount * map.HorizontalTileCount) do
                        local tileTexture = GetMapTileTexture(i)
                        if (tileTexture ~= nil) then
                            mapTiles:Add(i, tileTexture)
                            if (map.TileWidth == nil or map.TileHeight == nil) then
                                map.TileWidth, map.TileHeight = X4D_Cartography:GetTileDimensions(tileTexture)
                                if (map.TileWidth ~= nil and map.TileHeight ~= nil) then
                                    map.NativeWidth = map.TileWidth * map.HorizontalTileCount
                                    map.NativeHeight = map.TileHeight * map.VerticalTileCount
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if (dirty) then
        X4D.Cartography.DB:Add(mapIndex, map)
    end
    return map
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
    if (mapIndex ~= _currentMapIndex) then
        _currentMapIndex = mapIndex
    end
    return mapIndex
end

local function TryUpdateMapState(timer, state)
    --X4D.Log:Warning("TryUpdateMapState")
    if (ZO_WorldMap_IsWorldMapShowing()) then
        --NOP
        --TODO: this doesn't prevent state changes from occurring, since the 'map api calls' exposed by ZO are representative of ZO_WorldMap state prior to closure. le sigh.
        --TODO: for example, if the user zooms out all the way to top level minimap will be broken until user re-opens/closes
        return
    end

    -- relying on map tile and location name changes to determine if there was a map/zone change before updating relevant properties - not crucial, just an optimization
    local locationName = GetPlayerLocationName()
    X4D.Cartography.LocationName(locationName)
    local mapTile = GetMapTileTexture()
    if (mapTile ~= nil) then
        mapTile = mapTile:match("maps/[%w%-]+/(.-)_0.dds")
    end
    if (_currentMapTile ~= mapTile or _currentLocationName ~= locationName) then
        _currentMapTile = mapTile
        _currentLocationName = locationName
        local zoneIndex = GetCurrentMapZoneIndex()
        local mapIndex = GetMapIndexByZoneIndex(zoneIndex)
	    X4D_Cartography.IsSubZone(tonumber(mapIndex) == nil)
        mapName = GetMapName()
        X4D.Cartography.MapIndex(mapIndex)
        X4D.Cartography.ZoneIndex(zoneIndex)
        X4D.Cartography.MapName(mapName)
        local currentMap = X4D.Cartography:GetCurrentMap()
        X4D.Cartography.CurrentMap(currentMap)
    end

    local playerX, playerY, playerHeading = GetMapPlayerPosition("player")
    local cameraHeading = GetPlayerCameraHeading()
    X4D.Cartography.PlayerX(playerX)
    X4D.Cartography.PlayerY(playerY)
    X4D.Cartography.PlayerHeading(playerHeading)
    X4D.Cartography.CameraHeading(cameraHeading)
    --X4D.Log:Information({mapIndex,zoneIndex,mapName,locationName,playerX,playerY,playerH,locationName, mapTile}, "Cartography")
end

local _timer

--EVENT_MANAGER:RegisterForEvent(X4D_Cartography.NAME, EVENT_PLAYER_ACTIVATED, function()
--end)

EVENT_MANAGER:RegisterForEvent("X4D_Cartography.DB", EVENT_ADD_ON_LOADED, function(event, name)
    if (name ~= "X4D_Core") then
        return
    end
    X4D_Cartography.DB = X4D.DB:Open("X4D_Cartography.DB")
end)

function X4D_Cartography:Initialize()
    if (_private_texture == nil) then
        local tex = WINDOW_MANAGER:GetControlByName("X4D_PVT_TEX")
        if (tex == nil) then
            tex = WINDOW_MANAGER:CreateControl("X4D_PVT_TEX", GuiRoot, CT_TEXTURE)
        end
        tex:SetHidden(true)
        tex:SetTextureReleaseOption(RELEASE_TEXTURE_AT_ZERO_REFERENCES)
        _private_texture = tex
    end
    if (_timer == nil) then
        _timer = X4D.Async:CreateTimer(TryUpdateMapState):Start(1000/15, {}, "X4D_Cartography")
    end
end