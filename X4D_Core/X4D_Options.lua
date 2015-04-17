local X4D_Options = LibStub:NewLibrary('X4D_Options', 1001)
if (not X4D_Options) then
	return
end
local X4D = LibStub('X4D')
X4D.Options = X4D_Options


function X4D_Options:GetOption(name)
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

function X4D_Options:SetOption(name, value)
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
end

function X4D_Options:Create(savedVarsName, defaults, version)
    if (version == nil) then
        version = 1 -- changing this causes settings to wipe
    end	
    if (defaults == nil) then
        defaults = {}
    end
    local proto = {
		Saved = ZO_SavedVars:NewAccountWide(savedVarsName, version, nil, {}),
		Default = defaults,
	}

    -- TODO: if Saved is missing members contained in Default, perform merge of missing members (e.g. apply new defaults)
    -- TODO: if members of 'Default' are assigned the value of 'retired-variable' and it exists in 'Saved', then is is removed from 'Saved'

	setmetatable(proto, self)
	self.__index = self
	return proto
end
