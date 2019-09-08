local X4D_Guilds = LibStub:NewLibrary("X4D_Guilds", 1020)
if (not X4D_Guilds) then
	return
end
local X4D = LibStub("X4D")
X4D.Guilds = X4D_Guilds

EVENT_MANAGER:RegisterForEvent("X4D_Guilds", EVENT_ADD_ON_LOADED, function(event, name)
    if (name ~= "X4D_Core") then
		return
	end
    X4D_Guilds.DB = X4D.DB:Open("X4D_Guilds")
end)
