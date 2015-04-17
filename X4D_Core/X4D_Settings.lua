local X4D_Settings = LibStub:NewLibrary('X4D_Settings', 1001)
if (not X4D_Settings) then
	return
end
local X4D = LibStub('X4D')
X4D.Settings = X4D_Settings


function X4D_Settings:Get(name)
	if (self.Saved == nil) then
		return nil
	end
	local scope = 'Account-Wide'
	if (self.Saved.SettingsAre and self.Saved.SettingsAre ~= 'Account-Wide') then
		scope = GetUnitName("player")
	end
	local scoped = self.Saved[scope]
	if (scoped == nil) then
		return self.Default[name]
	end
	local value = scoped[name]
	if (value == nil) then
		value = self.Default[name]
	end
	return value
end

function X4D_Settings:Set(name, value)
	if (self.Saved == nil) then
		return nil
	end
	local scope = 'Account-Wide'
	if (self.Saved.SettingsAre and self.Saved.SettingsAre ~= 'Account-Wide') then
		scope = GetUnitName("player")
	end
	local scoped = self.Saved[scope]
	if (scoped == nil) then
		scoped = {}
		self.Saved[scope] = scoped
	end
	scoped[name] = value
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

function X4D_Settings:Create(savedVarsName, defaults, versions)
    if (version == nil) then
        version = 1 -- changing this causes settings to wipe
    end	
    if (defaults == nil) then
        defaults = {}
    end
    local saved = ZO_SavedVars:NewAccountWide(savedVarsName, version, nil, {})
    local proto = {
		Saved = saved,
		Default = defaults,
	}

    -- TODO: if 'Saved' is missing members that are present in 'Default', perform merge of missing members (e.g. apply missing defaults)
    -- TODO: if members of 'Default' are assigned the value of 'retired-variable' and it exists in 'Saved', then is to be removed from 'Saved'

	setmetatable(proto, { __index = self, __call = self.GetOrSet })

	return proto
end

setmetatable(X4D_Settings, { __call = X4D_Settings.Create })
