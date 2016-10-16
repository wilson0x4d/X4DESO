local X4D_NPCs = LibStub:NewLibrary("X4D_NPCs", 1000)
if (not X4D_NPCs) then
	return
end
local X4D = LibStub("X4D")
X4D.NPCs = X4D_NPCs

X4D_NPCs.NAME = "X4D_NPCs"
X4D_NPCs.VERSION = "1.0"

local _currentMapId = nil
local _currentZoneIndex = nil

--[[ NOTE:
	we have the need to store data common to all NPC types (name, location, etc)
	we may interpret certain NPCs special later on if we find the same NPC exists, in game, for more than one purpose (for example, the Prophet manifests all over the place but only at key points in player progression.)

	this data will be used form minimap module.

	in the case of "NPC type-specific data" such data will be recorded by a dedicated module (the same module which feeds into this module, as this module does nothing to aggregate data itself.)

	this module is responsible for provisioning a shared database for all other X4D modules to rely upon,
	it hooks events to know certain state variables
	it delegates to the DB API, providing the same syntax, to inject said "state variables" into each stored entity
	it provides observables which list all "nearby" NPCs, where "nearby" is determined as a combination of "`Map ID` and `Zone Index`"
]]

function X4D_NPCs:Create(tag)
	local unitName = GetRawUnitName(tag)
	if (unitName == nil or unitName:len() == 0) then
		unitName = tag
	end
	local key = "npc:" .. _currentMapId .. ":" .. _currentZoneIndex .. ":" .. unitName
	local entity = {
		Name = unitName,
		Key = key,
		MapId = _currentMapId,
		ZoneIndex = _currentZoneIndex,
		Position = {
			X = X4D.Cartography.PlayerX(),
			Y = X4D.Cartography.PlayerY()
		}
	}
	return entity, entity.Key
end

-- region Nearby NPCs

X4D_NPCs.NearbyNPCs = X4D.Observable(nil) -- NOTE: used by X4D_MiniMap to create "NPC pins", and elsewhere, instead of polling/querying again and again
X4D_NPCs.CurrentNPC = X4D.Observable(nil) -- NOTE: when another module detects interaction with an NPC, it *may* place a module-specific entity here

local function IsNPCNearby(npc, key)
	local isNearby = npc ~= nil and npc.MapId == _currentMapId and npc.ZoneIndex == _currentZoneIndex
	if (isNearby) then
		X4D.Log:Warning { "IsNPCNearby", npc.Name, key, isNearby }
	end
	return isNearby
end

local function OnCurrentMapChanged(map, oldMap)
	_currentMapId = X4D.Cartography.MapIndex()
	_currentZoneIndex = X4D.Cartography.ZoneIndex()
	X4D.Log:Verbose { "OnCurrentMapChanged", _currentMapId, _currentZoneIndex }
	local nearby = X4D_NPCs.DB:Where(IsNPCNearby, true)
	X4D_NPCs.NearbyNPCs(nearby)
end

-- endregion Nearby NPCs

-- region Database
--[[
	X4D_NPC "mimics" the interface exposed by the X4D_DB module
	it does this so that `Map ID` and `Zone Index` can be baked into basic operations (Add, Find, etc)
	this region of code contains the delegation required to simulate the X4D_DB interface
]]

function X4D_NPCs:Find(key)
	if (not key:StartsWith("npc:")) then
--		X4D.Log:Information{"X4D_NPCs:Find", _currentMapId, _currentZoneIndex, key}
		key = "npc:" .. _currentMapId .. ":" .. _currentZoneIndex .. ":" .. key
	end
	return self.DB:Find(key)
end

function X4D_NPCs:FirstOrDefault(predicate)
	return self.DB:FirstOrDefault(predicate)
end

function X4D_NPCs:ForEach(visitor)
	self.DB:ForEach(visitor)
end

function X4D_NPCs:Add(key, value)
	local entity = value
	if (entity == nil) then
		entity = key
	else
		X4D.Log:Warning { "X4D_NPCs:Add", "The NPC DB does not accept caller-supplied keys, keys are inferred using NPC-specific conventions", key }
	end
	if (entity.Class == nil) then
		X4D.Log:Error { "X4D_NPCs:Add", "The NPC entity provided does not have a Class property, the NPC is not saved." }
		return nil
	end
	if (entity.Name == nil) then
		X4D.Log:Error { "X4D_NPCs:Add", "The NPC entity provided does not have a Name property, the NPC is not saved." }
		return nil
	end
	if (entity ~= nil) then
		-- TODO: there may be special NPCs which we do not do this for, or we may one day track multiple locations?
		entity.Key = "npc:" .. _currentMapId .. ":" .. _currentZoneIndex .. ":" .. entity.Name
		entity.MapId = _currentMapId
		entity.ZoneIndex = _currentZoneIndex
		entity.Position = {
			X = X4D.Cartography.PlayerX(),
			Y = X4D.Cartography.PlayerY()
		}
	end
	return self.DB:Add(entity.Key, entity)
end

function X4D_NPCs:Remove(key)
	self.DB:Remove(key)
end

function X4D_NPCs:Count()
	return self.DB:Count()
end

function X4D_NPCs:Select(builder)
	return self.DB:Select(builder)
end

function X4D_NPCs:Where(predicate, silence)
	return self.DB:Where(predicate, silence)
end

-- endregion

EVENT_MANAGER:RegisterForEvent(X4D_NPCs.NAME, EVENT_ADD_ON_LOADED, function(event, name)
	if (name ~= "X4D_Core") then
		return
	end
	local stopwatch = X4D.Stopwatch:StartNew()

	-- initialize NPC database
	X4D_NPCs.DB = X4D.DB:Open(X4D_NPCs.NAME)

	-- observe `CurrentMap` for changes to rebuild lists, consumers must ensure init before use
	-- X4D.Cartography:Initialize()
	X4D.Cartography.CurrentMap:Observe(OnCurrentMapChanged)

	-- record module load time
	X4D_NPCs.Took = stopwatch.ElapsedMilliseconds()
end)
