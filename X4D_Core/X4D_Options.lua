local X4D_Options = LibStub:NewLibrary('X4D_Options', 1000)
if (not X4D_Options) then
	return
end

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

function X4D_Options:Create(savedVarsName, defaults)	
	local proto = {
		Saved = ZO_SavedVars:NewAccountWide(savedVarsName, 1.0, nil, {}),
		Default = defaults,
	}
	setmetatable(proto, self)
	self.__index = self
	return proto
end
