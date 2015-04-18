local X4D_Players = LibStub:NewLibrary("X4D_Players", 1001)
if (not X4D_Players) then
    return
end
local X4D = LibStub("X4D")
X4D.Players = X4D_Players

EVENT_MANAGER:RegisterForEvent("X4D_Players.DB", EVENT_ADD_ON_LOADED, function(event, name)
    if (name == "X4D_Core") then
        X4D_Players.DB = X4D.DB("X4D_Players.DB")
    end
end)

function X4D_Players:GetPlayerByName(self, name)
    return self.DB
        .Where(function(player) return player.Name:match(name) ~= nil end)
        .FirstOrDefault()
end

