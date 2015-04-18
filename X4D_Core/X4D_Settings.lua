local X4D_Settings = LibStub:NewLibrary("X4D_Settings", 1001)
if (not X4D_Settings) then
	return
end
local X4D = LibStub("X4D")
X4D.Settings = X4D_Settings

function X4D_Settings:Get(name)
	if (self.Saved == nil) then
		return nil
	end
    if (name == "SettingsAre") then
        return self.Saved.SettingsAre or self.Default.SettingsAre or "Account-Wide"
    else
	    local scope = self.Saved.SettingsAre or "Account-Wide"
	    if (scope ~= "Account-Wide") then
            scope = GetUnitName("player")
	    end
        scope = "$" .. base58(sha1(scope):FromHex())
	    local scoped = self.Saved[scope]
	    if (scoped == nil) then
		    return self.Default[name]
	    end
	    local value = scoped[name]
	    return value or self.Default[name]
    end
end

function X4D_Settings:Set(name, value)
	if (self.Saved == nil) then
		return nil
	end
    if (name == 'SettingsAre') then
	    self.Saved.SettingsAre = value
    else
	    local scope = self.Saved.SettingsAre or self.Default.SettingsAre or "Account-Wide"
	    if (scope ~= "Account-Wide") then
            scope = GetUnitName("player")
	    end
        scope = "$" .. base58(sha1(scope):FromHex())
	    local scoped = self.Saved[scope]
	    if (scoped == nil) then
		    scoped = {}
		    self.Saved[scope] = scoped
	    end
	    scoped[name] = value
    end
    return value
end

function X4D_Settings:GetOrSet(name, value)
    if (value ~= nil) then
        self.Set(name, value)
        return value
    else
        return self.Get(name)
    end
end

function X4D_Settings:Create(savedVarsName, defaults, version)
    if (version == nil or type(version) ~= "number") then
        version = 1 -- if you don't understand how to version configs, do NOT specify a version
    end	
    if (defaults == nil) then
        defaults = {}
    elseif (type(defaults) == "number") then
        if (version == nil) then
            version = defaults
        end
        defaults = {}
    end
    version = math.floor(version)
    local saved = ZO_SavedVars:NewAccountWide(savedVarsName, version, nil, {})
    local proto = {
		Saved = saved,
		Default = defaults,
	}

    -- TODO: if "Saved" is missing members that are present in "Default", perform merge of missing members (e.g. apply missing defaults)
    -- TODO: if members of "Default" are assigned the value of "retired-variable" and it exists in "Saved", then is to be removed from "Saved"

	setmetatable(proto, { __index = self, __call = self.GetOrSet })

	return proto
end

setmetatable(X4D_Settings, { __call = X4D_Settings.Create })
