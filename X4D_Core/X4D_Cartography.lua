local X4D_Cartography = LibStub:NewLibrary("X4D_Cartography", 1000)
if (not X4D_Cartography) then
    return
end
local X4D = LibStub("X4D")
X4D.Cartography = X4D_Cartography

-- current player zone and position
X4D_Cartography.MapIndex = X4D.Observables(nil) -- current map index
X4D_Cartography.MapName = X4D.Observables(nil) -- current map name
X4D_Cartography.ZoneIndex = X4D.Observables(nil) -- current map zone index
X4D_Cartography.PlayerX = X4D.Observables(0) -- player position (x-coordinate)
X4D_Cartography.PlayerY = X4D.Observables(0) -- player position (y-coordinate)
X4D_Cartography.PlayerHeading = X4D.Observables(0) -- player heading (???)

X4D_Cartography.CurrentMap = X4D.Observables(nil) -- reference to current map from Cartography DB

-- TODO: Player Speed "ZoneSpeed"

function X4D_Cartography:GetMap(mapIndex)
    local isZoneMap = false
    local mapName, mapType, mapContentType, currentZoneIndex = GetMapInfo(mapIndex)
    if (mapIndex == nil or mapIndex == 0) then
        -- if mapIndex is invalid, convert to current map zone index, this may or may not work as expected
        -- TODO: check if maptype/maptcontentype do not require us to partition mapindex/zoneindex into separate buckets
        mapName = GetMapName()
        mapIndex = base58(sha1(mapName):FromHex())
        isZoneMap = true
        --X4D.Log:Verbose({"Using ZoneIndex and MapName for Map Identity :(", mapIndex, mapName}, "Cartography")
    end
    local map = X4D.Cartography.DB:Find(mapIndex)
    if (map == nil) then
        map = {
            MapIndex = mapIndex,
            MapName = zo_strformat("<<1>>", mapName),
            MapType = mapType,
            MapContentType = MapContentType,
            MapWidth = nil,
            MapHeight = nil,
            Tiles = {},
            Zones = {},
            IsDungeon = isZoneMap -- *sigh*
        }
        X4D_Cartography.DB:Add(mapIndex, map)
    end
    local mapZones = X4D.DB:Create(map.Zones)
    if (mapZones:Count() == 0) then
        if (isZoneMap) then
            -- only add single zone, do not enumerate
            local zoneIndex = GetCurrentMapZoneIndex()
            local zoneKey = mapIndex .. "-" .. zoneIndex
            local zone = {
                MapIndex = mapIndex,
                ZoneIndex = mapIndex,
                Description = GetZoneDescription(zoneIndex),
            }
            mapZones:Add(zoneKey, zone)
        else
            -- attempt to enumerate zones
            for zoneIndex = 1, GetNumZonesForDifficultyLevel(difficulty) do
                local zoneKey = mapIndex .. "-" .. zoneIndex
                local zone = {
                    MapIndex = mapIndex,
                    ZoneIndex = zoneIndex,
                    Description = GetZoneDescription(zoneIndex),
                }
                mapZones:Add(zoneKey, zone)
            end
        end
    end
    if (GetCurrentMapIndex() == mapIndex or isZoneMap) then
        local mapTiles = X4D.DB:Create(map.Tiles)
        if (mapTiles:Count() == 0) then
            local numHorizontalTiles, numVerticalTiles = GetMapNumTiles()
            if (numHorizontalTiles ~= nil and numVerticalTiles ~= nil) then
                map.MapHeight = numVerticalTiles
                map.MapWidth = numHorizontalTiles
                for i = 1, (map.MapHeight * map.MapWidth) do
                    local tileTexture = GetMapTileTexture(i)
                    if (tileTexture ~= nil) then
                        --X4D.Log:verbose({i, tileTexture}, "Cartography")
                        mapTiles:Add(i, tileTexture)
                    end
                end
            end
        end
    end
    return map
end

function X4D_Cartography:GetCurrentMap()
    local mapIndex = GetCurrentMapIndex()
    if (mapIndex == nil) then
        mapIndex = 0
    end
    return self:GetMap(mapIndex)
end

EVENT_MANAGER:RegisterForEvent(X4D_Cartography.NAME, EVENT_PLAYER_ACTIVATED, function()
    X4D.Async:CreateTimer(function (timer, state) 
        if (ZO_WorldMap_IsWorldMapShowing()) then
            --NOP
        else
            local mapIndex = GetCurrentMapIndex()
            if (mapIndex == nil) then
                mapIndex = 0
            end
            local map = X4D.Cartography:GetMap(mapIndex)
            local zoneIndex = GetCurrentMapZoneIndex()
            local playerX, playerY, playerU = GetMapPlayerPosition("player")
            X4D.Cartography.MapIndex(mapIndex)
            X4D.Cartography.MapName(map.MapName)
            X4D.Cartography.ZoneIndex(zoneIndex)
            X4D.Cartography.PlayerX(playerX)
            X4D.Cartography.PlayerY(playerY)
            X4D.Cartography.PlayerHeading(GetPlayerCameraHeading())
        end
    end, 50, {}):Start()
end)

EVENT_MANAGER:RegisterForEvent("X4D_Cartography.DB", EVENT_ADD_ON_LOADED, function(event, name)
    if (name ~= "X4D_Core") then
        return
    end
    X4D_Cartography.DB = X4D.DB:Open("X4D_Cartography.DB")
    -- scrape from API
    for mapIndex = 1, GetNumMaps() do
        local map = X4D.Cartography:GetMap(mapIndex)
    end
end)

X4D.Cartography.MapIndex:Observe(function (v)
    X4D.Log:Verbose({"MapIndex", v}, "Cartography")
    local map = X4D.Cartography:GetMap(v)
    X4D.Cartography.CurrentMap(map)
end)
X4D.Cartography.MapName:Observe(function (v) 
    X4D.Log:Verbose({"MapName", v}, "Cartography")
end)
X4D.Cartography.ZoneIndex:Observe(function (v) 
    X4D.Log:Verbose({"ZoneIndex", v}, "Cartography")
end)
X4D.Cartography.PlayerX:Observe(function (v) 
    X4D.Log:Verbose({"PlayerX", v}, "Cartography")
end)
X4D.Cartography.PlayerY:Observe(function (v) 
    X4D.Log:Verbose({"PlayerY", v}, "Cartography")
end)

