local X4D_Stopwatches = LibStub:NewLibrary("X4D_Stopwatches", 1015)
if (not X4D_Stopwatches) then
	return
end
local X4D = LibStub("X4D")
X4D.Stopwatches = X4D_Stopwatches

--region X4D_Stopwatch

local X4D_Stopwatch = {}

function X4D_Stopwatch:New()
    local stopwatch = {
        _timestamp = 0,
        ElapsedMilliseconds = X4D.Observable(0),
        IsRunning = X4D.Observable(false)
    }
    setmetatable(stopwatch, { __index = X4D_Stopwatch })
    return stopwatch, stopwatch.Timestamp
end

function X4D_Stopwatch:GetTimestamp()
    return self._timestamp
end

function X4D_Stopwatch:Reset()
    self._elapsed = 0
    return self
end

function X4D_Stopwatch:Start()
    self._timestamp = GetGameTimeMilliseconds()
    return self
end

function X4D_Stopwatch:Restart()
    self:Reset()
    self:Start()
    return self
end

function X4D_Stopwatch:Stop()
    self.IsRunning(false)
    self.ElapsedMilliseconds(self.ElapsedMilliseconds() + (GetGameTimeMilliseconds() - self._timestamp))
    self._timestamp = 0
    return self
end

function X4D_Stopwatch:IsRunning() 
    return self._timestamp > 0
end

--endregion

function X4D_Stopwatches:Create()
    return X4D_Stopwatch:New()
end

function X4D_Stopwatches:StartNew()
    return X4D_Stopwatch
        :New()
        :Start()
end
