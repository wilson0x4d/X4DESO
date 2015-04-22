local X4D_DB = LibStub:NewLibrary("X4D_DB", 1001)
if (not X4D_DB) then
	return
end
local X4D = LibStub("X4D")
X4D.DB = X4D_DB

local _databases = nil

-- NOTE: not valid to call except during addon loaded events, unless the input is a Lua table object, in which case it can be called at any time
-- "non-persistent" databases can be created by providing a reference to a Lua "table", X4D_DB delegates access to the table
-- "persistent" databases are opened when a database name (string) is provided
function X4D_DB:Open(database)
    if (database == nil) then
        database = {}
    end
    if (type(database) ~= "table") then
        if (_databases == nil) then
            local sv = X4D.Settings("X4D_CORE_SV", nil, 2)
            if (sv.Saved.X4DB == nil) then
                sv.Saved["X4DB"] = {}
            end
            _databases = sv.Saved.X4DB
        end
        if (_databases[database] == nil) then
            _databases[database] = {}
        end
        database = _databases[database]
    end
	local proto = {
		_table = database
	}
	setmetatable(proto, { __index = X4D_DB })
	return proto
end

function X4D_DB:Find(key) -- most efficient way to look up an item is if you already have its key
    return self._table[key]
end

function X4D_DB:Where(predicate)
    local results = {}
    for key,entity in pairs(self._table) do
        -- TODO: pcall
        if (predicate(entity, key)) then
            local L_key = entity.Id or entity.Key or entity.id or entity.key or entity.ID or key        
            results[L_key] = entity
        end
    end
    return X4D_DB:Create(results)
end

function X4D_DB:Select(builder)
    local results = X4D_DB:Create()
    for key,entity in pairs(self._table) do
        -- TODO: pcall
        local value = builder(entity, key)
        local L_key = value.Id or value.Key or value.id or value.key or value.ID or key        
        results:Add(L_key, value)
    end
    return results
end

function X4D_DB:FirstOrDefault(predicate)
    for key,entity in pairs(self._table) do
        if ((predicate == nil) or predicate(entity, key)) then
            return entity, key
        end
    end
    return nil
end

function X4D_DB:ForEach(visitor)
    for key,entity in pairs(self._table) do
        visitor(entity, key)
    end
end

function X4D_DB:Add(key, value)
    -- if single arg, assume "key" contains the value (not a key): attempt to resolve the key using conventions
    if (value == nil) then
        value = key
        key = value.Id or value.Key or value.id or value.key or value.ID
    end
    self._table[key] = value
    return value, key
end

function X4D_DB:Remove(key)
    self._table[key] = nil
end

setmetatable(X4D_DB, { __call = X4D_DB.Open })

X4D_DB.Create = X4D_DB.Open
