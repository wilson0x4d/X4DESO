local X4D_DB = LibStub:NewLibrary("X4D_DB", 1015)
if (not X4D_DB) then
	return
end
local X4D = LibStub("X4D")
X4D.DB = X4D_DB

local _databases = nil

-- NOTE: not valid to call except during addon loaded events, unless the input is a Lua table object, in which case it can be called at any time
-- "non-persistent" databases can be created by providing a reference to a Lua "table", X4D_DB delegates access to the table
-- "persistent" databases are opened when a database name (string) is provided
function X4D_DB:Open(database, version)
    if (database == nil) then
        database = {
            _version = version
        }
    end
    if (type(database) ~= "table") then
        if (_databases == nil) then
            _databases = X4D.InternalSettings:Get("X4DB")
            if (_databases == nil) then
                _databases = {}
                X4D.InternalSettings:Set("X4DB", _databases)
            end
        end
        local databaseName = database -- yes, assumes is a string, or other valid key, but not a table object
        database = _databases[databaseName]
        if (database == nil or (version ~= nil and (database._version == nil or database._version < version))) then
            database = {
                _version = version
            }
            _databases[database] = database
        end
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

function X4D_DB:Count()
    return #(self._table)
end

-- discouraged, potential memory hog on very large data sets, may be cheaper to pay for a closure and use :ForEach unless you *really* need to perform a translation (cleaning up data between DB versions, e.g. removing/renaming properties from existing entities)
function X4D_DB:Select(builder)
    local results = X4D_DB:Create()
    for key,entity in pairs(self._table) do
        local value = builder(entity, key)
        local L_key = value.Id or value.Key or value.id or value.key or value.ID or key        
        results:Add(L_key, value)
    end
    return results
end

-- discouraged, memory hog. use :ForEach and :FirstOrDefault instead.
function X4D_DB:Where(predicate, silence)
    if (silence ~= true) then
        -- warning: this method creates a new table even when returning no results, it is a memory hog when used to query large datasets (use :ForEach or :FirstOrDefault instead.)
        X4D.Log:Warning("Use of 'X4D_DB::Where' function is discouraged, it negatively impacts performance when used incorrectly. (use :ForEach or :FirstOrDefault instead, please read the code comments to understand your options.)")
    end
    local results = {}
    for key,entity in pairs(self._table) do
        if (predicate(entity, key)) then
            local L_key = entity.Id or entity.Key or entity.id or entity.key or entity.ID or key        
            results[L_key] = entity
        end
    end
    return X4D_DB:Create(results)
end

X4D_DB.Create = X4D_DB.Open
