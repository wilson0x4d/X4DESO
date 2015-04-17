local X4D_Guilds = LibStub:NewLibrary("X4D_Guilds", 1001)
if (not X4D_Guilds) then
	return
end
local X4D = LibStub("X4D")
X4D.Guilds = X4D_Guilds

EVENT_MANAGER:RegisterForEvent("X4D_Guilds.DB", EVENT_ADD_ON_LOADED, function(event, name)
    if (name == "X4D_Core") then
        X4D_Guilds.DB = X4D.DB("X4D_Guilds.DB")
    end
end )
