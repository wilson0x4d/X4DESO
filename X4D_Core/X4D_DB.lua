local X4D_DB = LibStub:NewLibrary('X4D_DB', 1001)
if (not X4D_DB) then
	return
end
local X4D = LibStub('X4D')
X4D.DB = X4D_DB

local _databases = nil

-- NOTE: not valid to call except during addon loaded events, unless the input is a Lua table object, in which case it can be called at any time
-- 'non-persistent' databases can be created by providing a reference to a Lua 'table', X4D_DB delegates access to the table
-- 'persistent' databases are opened when a database name (string) is provided
function X4D_DB:Open(database)
    if (database == nil) then
        database = {}
    end
    if (type(database) ~= 'table') then
        if (_databases == nil) then
            local sv = X4D_Options:Create('X4D_CORE_SV')
            if (sv.Saved.X4DB == nil) then
                sv.Saved.X4DB = {}
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
	setmetatable(proto, self)
	self.__index = self
	return proto
end

function X4D_DB:Where(predicate)
    local results = {}
    for _,entity in self._table do
        -- TODO: pcall
        if (predicate(entity)) then
            table.insert(results, _, entity)
        end
    end
    return X4D_DB:Create(results)
end

function X4D_DB:Select(builder)
    local results = X4D_DB:Create()
    for key,entity in self._table do
        -- TODO: pcall
        results:Add(builder(key, entity))
    end
    return results
end

function X4D_DB:FirstOrDefault(predicate)
    for _,entity in self._table do
        if ((predicate == nil) or predicate(entity)) then
            return entity
        end
    end
    return nil
end

function X4D_DB:ForEach(visitor)
    for _,entity in self._table do
        visitor(entity)
    end
end

function X4D_DB:Add(key, value)
    -- if single arg, assume key == value and attempt to resolve key via conventions
    if (value == nil) then
        value = key
        key = value.id
        if (key == nil) then
            key = value.Id
            if (key == nil) then
                key = value.id
                if (key == nil) then
                    -- NOTE: error conventional members not found - call will throw error
                end
            end
        end
    end
    self._table[key] = value;
end

function X4D_DB:Remove(key)
    self._table[key] = nil
end

setmetatable(X4D_DB, { __call = X4D_DB.Open })

X4D_DB.Create = X4D_DB