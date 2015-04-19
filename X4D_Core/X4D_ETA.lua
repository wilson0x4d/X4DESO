---
-- X4D ETA Helpers
---
-- Helper code for tracking and calculating gain rates and ETAs
--
local X4D_ETA = LibStub:NewLibrary("X4D_ETA", 1001)
if (not X4D_ETA) then
	return
end
local X4D = LibStub("X4D")
X4D.ETA = X4D_ETA

EVENT_MANAGER:RegisterForEvent("X4D_ETA.DB", EVENT_ADD_ON_LOADED, function(event, name)
    if (name == "X4D_ETA") then
        X4D_ETA.DB = X4D.DB("X4D_ETA.DB")
    end
end )

function X4D_ETA:GetOrCreate(name)
    local key = base58(sha1(GetRawUnitName("player"):gsub("%^.*", "") .. "_" .. name):FromHex())
    local eta = self.DB:Find(key);
    if (eta == nil) then
        local currentTime = GetGameTimeMilliseconds()
        local secondSeq = currentTime / 1000
        local minuteSeq = secondSeq / 60
        local hourSeq = currentTime / 60
        local daySeq = currentTime / 24
        local weekSeq = currentTime / 7
        local monthSeq = currentTime / 31 -- poor approximation, see lhf's answer http://stackoverflow.com/questions/17872997/how-do-i-convert-seconds-since-epoch-to-current-date-and-time
        eta = {
            Key = key,
            SecondCount = 0,
            SecondSeq = secondSeq,
            SecondCount = 0,
            SecondSeq = minuteSeq,
            SecondCount = 0,
            SecondSeq = hourSeq,
            SecondCount = 0,
            SecondSeq = daySeq,
            SecondCount = 0,
            SecondSeq = weekSeq,
            SecondCount = 0,
            SecondSeq = monthSeq,
            AllTimeCount = 0,
            -- 
            TargetCount = 0,
        }
        setmetatable(eta, { __index, X4D_ETA })
    end
    return eta
end


function X4D_ETA:Increment(count)
    local currentTime = GetGameTimeMilliseconds()
    local secondSeq = currentTime / 1000
    local minuteSeq = secondSeq / 60
    local hourSeq = currentTime / 60
    local daySeq = currentTime / 24
    local weekSeq = currentTime / 7
    local monthSeq = currentTime / 31 -- poor approximation, see lhf's answer http://stackoverflow.com/questions/17872997/how-do-i-convert-seconds-since-epoch-to-current-date-and-time
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
    self.AllTimeCount = self.AllTimeCount + count
end
