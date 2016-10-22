---
-- X4D ETA Helpers
---
-- Helper code for tracking and calculating gain rates and ETAs
--
local X4D_ETA = LibStub:NewLibrary("X4D_ETA", 1015)
if (not X4D_ETA) then
	return
end
local X4D = LibStub("X4D")
X4D.ETA = X4D_ETA

EVENT_MANAGER:RegisterForEvent("X4D_ETA", EVENT_ADD_ON_LOADED, function(event, name)
    if (name ~= "X4D_Core") then
		return
	end
    X4D_ETA.DB = X4D.DB:Open("X4D_ETA")
end)

local _sessionStartTime = GetGameTimeMilliseconds()

function X4D_ETA:GetOrCreate(name)
    local key = base58(sha1(GetRawUnitName("player") .. "_" .. name):FromHex())
    local eta = X4D.ETA.DB:Find(key);
    if (eta == nil) then
        local currentTime = GetGameTimeMilliseconds()
        local secondSeq = math.floor(currentTime / 1000)
        local minuteSeq = math.floor(currentTime / 60000)
        local hourSeq = math.floor(currentTime / 3600000)
        local daySeq = math.floor(currentTime / 86400000)
        local weekSeq = math.floor(currentTime / 604800000)
        local monthSeq = math.floor(currentTime / 2678400000) -- poor approximation, see lhf's answer http://stackoverflow.com/questions/17872997/how-do-i-convert-seconds-since-epoch-to-current-date-and-time
        eta = {
            Key = key,
            SecondCount = 0,
            SecondSeq = secondSeq,
            MinuteCount = 0,
            MinuteSeq = minuteSeq,
            HourCount = 0,
            HourSeq = hourSeq,
            DayCount = 0,
            DaySeq = daySeq,
            WeekCount = 0,
            WeekSeq = weekSeq,
            MonthCount = 0,
            MonthSeq = monthSeq,
            AllTimeCount = 0,
            -- 
            TargetCount = 0,
            LastResetTime = currentTime,
            CountSinceReset = 0,
            SessionSeq = _sessionStartTime,
            SessionCount = 0
        }
        X4D.ETA.DB:Add(eta)
    end
    setmetatable(eta, { __index = X4D_ETA })
    return eta
end

function X4D_ETA:Increment(count)
    local currentTime = GetGameTimeMilliseconds()
    local secondSeq = math.floor(currentTime / 1000)
    local minuteSeq = math.floor(currentTime / 60000)
    local hourSeq = math.floor(currentTime / 3600000)
    local daySeq = math.floor(currentTime / 86400000)
    local weekSeq = math.floor(currentTime / 604800000)
    local monthSeq = math.floor(currentTime / 2678400000) -- poor approximation, see lhf's answer http://stackoverflow.com/questions/17872997/how-do-i-convert-seconds-since-epoch-to-current-date-and-time
    if (self.SecondSeq ~= secondSeq) then
        self.SecondSeq = secondSeq
        self.SecondCount = count
    else
        self.SecondCount = self.SecondCount + count
    end
    if (self.MinuteSeq ~= minuteSeq) then
        self.MinuteSeq = minuteSeq
        self.MinuteCount = count
    else
        self.MinuteCount = self.MinuteCount + count
    end
    if (self.HourSeq ~= hourSeq) then
        self.HourSeq = hourSeq
        self.HourCount = count
    else
        self.HourCount = self.HourCount + count
    end
    if (self.DaySeq ~= daySeq) then
        self.DaySeq = daySeq
        self.DayCount = count
    else
        self.DayCount = self.DayCount + count
    end
    if (self.WeekSeq ~= weekSeq) then
        self.WeekSeq = weekSeq
        self.WeekCount = count
    else
        self.WeekCount = self.WeekCount + count
    end
    if (self.MonthSeq ~= monthSeq) then
        self.MonthSeq = monthSeq
        self.MonthCount = count
    else
        self.MonthCount = self.MonthCount + count
    end
    if (self.SessionSeq ~= _sessionStartTime) then
        self.SessionSeq = _sessionStartTime
        self.SessionCount = count
    else    
        self.SessionCount = self.SessionCount + count
    end
    self.AllTimeCount = self.AllTimeCount + count
    self.CountSinceReset = self.CountSinceReset + count
end

function X4D_ETA:Reset(newTargetCount, initialCount)
	if (initialCount == nil) then
		initialCount = 0
	end
    self.LastResetTime = GetGameTimeMilliseconds()
    self.CountSinceReset = initialCount
    if (newTargetCount == nil) then
        self.TargetCount = 0
    else
        self.TargetCount = newTargetCount
    end
    local currentTime = GetGameTimeMilliseconds()
    self.SecondCount = 0
    self.MinuteCount = 0
    self.HourCount = initialCount
    self.HourSeq = math.floor(currentTime / 3600000)
    self.DayCount = initialCount
    self.DaySeq = math.floor(currentTime / 86400000)
    self.WeekCount = initialCount
    self.WeekSeq = math.floor(currentTime / 604800000)
    self.MonthCount = initialCount
    self.MonthSeq = math.floor(currentTime / 2678400000) -- poor approximation, see lhf's answer http://stackoverflow.com/questions/17872997/how-do-i-convert-seconds-since-epoch-to-current-date-and-time
    self.AllTimeCount = initialCount
end

function X4D_ETA:GetSessionAverage(interval) 
    if (interval == nil or interval < 1000) then
        interval = 1000 -- default return average count per second, interval is in milliseconds
    end
    local divisor = (GetGameTimeMilliseconds() - self.SessionSeq) / interval
    return self.SessionCount / divisor
end

function X4D_ETA:GetAverage(interval) 
    if (interval == nil or interval < 1000) then
        interval = 1000 -- default return average count per second, interval is in milliseconds
    end
    local divisor = (GetGameTimeMilliseconds() - self.LastResetTime) / interval
    return self.CountSinceReset / divisor
end

setmetatable(X4D_ETA, { __call = X4D_ETA.GetOrCreate })

EVENT_MANAGER:RegisterForEvent("X4D_ETA", EVENT_ADD_ON_LOADED, function (event, name)
    if (name ~= "X4D_Core") then
		return
	end
    _sessionStartTime = GetGameTimeMilliseconds()
end)
