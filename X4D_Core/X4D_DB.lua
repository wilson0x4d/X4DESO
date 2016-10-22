local X4D_DB_VERSION = 1015
local X4D_DB = LibStub:NewLibrary("X4D_DB", X4D_DB_VERSION)
if (not X4D_DB) then
	return
end
local X4D = LibStub("X4D")
X4D.DB = X4D_DB

local function countof(table)
    local count = 0
    for key,entity in pairs(table) do
        if ((type(key) ~= "string") or (not key:StartsWith("_"))) then
            count = count + 1
        end
    end
    return count
end

local _databases = nil

-- NOTE: not valid to call except during addon loaded events, unless the input is a Lua table object, in which case it can be called at any time
-- "persistent" databases are opened when a database name (string) is provided, this can only be done successfully during addon loaded event
-- "transient" databases can be created AT ANY TIME by providing a reference to a Lua "table", X4D_DB delegates access to the table
function X4D_DB:Open(database, version)
--	X4D.Log:Debug{"X4D_DB:Open", database, version}
    if (database == nil) then
        database = { }
    end
    local databaseName = database -- yes, assumes is a string, or other valid key, but not a table object
    if (type(databaseName) == "table") then
		databaseName = "TRANSIENT" .. GetGameTimeMilliseconds()
	else
        if (version == nil) then
            version = 0
        end
		version = X4D_DB_VERSION + version
        if (_databases == nil) then
            _databases = X4D.InternalSettings:Get("X4DB")
            if (_databases == nil) then
				X4D.Log:Verbose{"X4D_DB:Open", "Creating Missing SavedVar"}
                _databases = { }
                X4D.InternalSettings:Set("X4DB", _databases)
            end
        end
		-- NOTE: the following line is useful for confirming (1) that savedvars are saving and (2) that the right number of persistent databases are being opened
		-- _databases["_seq"] = (tonumber(_databases["_seq"]) or 1) + 1
        database = _databases[databaseName]
        if (database == nil) then
			X4D.Log:Verbose{"X4D_DB:Open", "Database Not Found", databaseName, version}
            database = {
                _version = version
            }
            _databases[databaseName] = database
		elseif (database._version == nil or database._version < version) then
			X4D.Log:Verbose{"X4D_DB:Open", "Bad/Missing Version", databaseName, version}
        end
        database._name = databaseName
		X4D.InternalSettings:Set("X4DB", _databases)
    end
    if (database._count == nil or database._count == 0) then
        database._count = countof(database)
    end
    if (database._name == nil) then
        database._name = databaseName
    end
	local proto = {
		_table = database
	}
	setmetatable(proto, { __index = X4D_DB })
	return proto
end

function X4D_DB:Find(key) -- most efficient way to look up an item is if you already have its key
	X4D.Log:Debug{"X4D_DB:Find", self._table._name, key}
    return self._table[key]
end

function X4D_DB:FirstOrDefault(predicate)
    for key,entity in pairs(self._table) do
        if ((type(entity) == "table") and ((predicate == nil) or predicate(entity, key))) then
            return entity, key
        end
    end
    return nil
end

function X4D_DB:ForEach(visitor)
    for key,entity in pairs(self._table) do
        if (type(entity) == "table") then
            visitor(entity, key)
        end
    end
end

function X4D_DB:Add(key, value)
    -- if single arg, assume "key" contains the value (not a key): attempt to resolve the key using conventions
    if (value == nil) then
        value = key
        key = value.Id or value.Key or value.id or value.key or value.ID
    end
	X4D.Log:Verbose{"X4D_DB:Add", self._table._name, key}
    self._table[key] = value
    self._table._count = self._table._count + 1
    return value, key
end

function X4D_DB:Remove(key)
	if (type(key) == "table") then
		-- assume an entity was passed in, and apply conventions to resolve entity key
        key = key.Id or key.Key or key.id or key.key or key.ID
	end
	X4D.Log:Debug{"X4D_DB:Remove", self._table._name, key}
    self._table[key] = nil
    self._table._count = self._table._count - 1
end

function X4D_DB:Count()
	X4D.Log:Debug{"X4D_DB:Count", self._table._name}
    -- NOTE: do not perform direct insertions/removals against _table, or you skew _count
    return self._table._count or countof(self._table)
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

-- discouraged, memory hog. use :ForEach and :FirstOrDefault instead. this exists for very specific cases where you need a long-lived copy of results anyway, this is BAD for transient data/operations.
function X4D_DB:Where(predicate, silence)
    if (silence ~= true) then
        -- warning: this method creates a new table even when returning no results, it is a memory hog when used to query large datasets (use :ForEach or :FirstOrDefault instead.)
        X4D.Log:Warning("Use of 'X4D_DB::Where' function is discouraged, it negatively impacts performance when used incorrectly. (use :ForEach or :FirstOrDefault instead, please read the code comments to understand your options.)")
    end
    local results = {}
    for key,entity in pairs(self._table) do
        if ((type(entity) == "table") and predicate(entity, key)) then
            local L_key = entity.Id or entity.Key or entity.id or entity.key or entity.ID or key        
            results[L_key] = entity
        end
    end
    return X4D_DB:Create(results)
end

X4D_DB.Create = X4D_DB.Open

X4DB = X4D_DB.Open

SLASH_COMMANDS["/x4db"] = function (parameters, other)
    X4D.Log:Warning("X4DB v" .. X4D.VERSION)
    local args = nil
    if (parameters ~= nil and parameters:len() > 0) then
        args = parameters:Split(" ")
        X4D.Log:Information("/x4db " .. parameters, "X4DB")
        --region /x4db reset X4D_Items.DB
        if (parameters:StartsWith("reset")) then
            if ((#args > 2) and (args[3] == "-accept")) then
                local databaseName = args[2]
                if (databaseName ~= nil) then
                    local database = _databases[databaseName]
                    if (database ~= nil) then
                        local databaseVersion = database._table._version
                        database._table = {
                            _version = databaseVersion,
                            _name = databaseName,
							_count = 0
                        }
                        X4D.Log:Information("Reset of '" .. databaseName .. "' complete.")
                        return
                    end
                end
            end
            X4D.Log:Error("ERROR: Performing a RESET on a DB in this manner may have unintended side-effects, and may further require you to delete savedvars to correct the issue.", "X4DB")
            X4D.Log:Error("WARNING: If you understand the implications of using this command, enter '-accept' as the last command parameter. Fx: |cFFFFFF/x4db reset X4D_Items.DB -accept", "X4DB")
        end
        --endregion
        --region /x4db count [X4D_Items.DB]
        if (parameters:StartsWith("count")) then
            if (#args == 2) then
                local databaseName = args[2]
                if (databaseName ~= nil) then
                    local table = _databases[databaseName]
                    if (table ~= nil) then
                        local database = X4D_DB:Create(table)
                        X4D.Log:Information(databaseName .. " contains " .. database:Count() .. " entities.")
                    end
                end
            else
                for _,table in pairs(_databases) do
                    if (table ~= nil and type(table) == "table") then
                        local databaseName = table._name
                        local database = X4D_DB:Create(table)
                        X4D.Log:Information((databaseName or "(nil)") .. " contains " .. database:Count() .. " entities.")
                    end
                end
           end
        end
        --endregion
    end
end
