local X4D_Players = LibStub:NewLibrary('X4D_Players', 1001)
if (not X4D_Players) then
	return
end

function X4D_Players.GetPlayerByName(self, name)
	return self.Players[name]
end