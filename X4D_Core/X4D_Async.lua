local X4D_Async = LibStub:NewLibrary("X4D_Async", 1001)
if (not X4D_Async) then
	return
end
local X4D = LibStub("X4D")
X4D.Async = X4D_Async

local X4D_Timer = {}

--- <summary>
--- <para>Create a new instance of X4D_Timer</para>
--- <para>Timer continues to elapse until stopped.</para>
--- </summary>
--- <params>
--- <param name="callback">the callback to execute when the timer elapses, receives a reference to Timer instance and user state object</param>
--- <param name="interval">the interval at which the timer elapses</param>
--- </params>
function X4D_Timer:New(callback, interval, state)
	local proto = {
		_enabled = false,
		_callback = callback or (function(L_timer) self:Stop() end),
		_interval = interval or 1000,
		_state = state or {},
	}
	setmetatable(proto, { __index = X4D_Timer })
	return proto
end

function X4D_Timer:IsEnabled()
	return self._enabled
end

function X4D_Timer:Elapsed()
	local start = GetGameTimeMilliseconds()
	if (not self._callback) then
		self:Stop()
		return
	end
	local success, err = pcall(self._callback, self, self._state)
	if (not success) then
		X4D.Log:Error(err)
		return
	end
	if (self._enabled) then
		--local spent = GetGameTimeMilliseconds() - start
		local interval = self._interval -- -spent

		--if (interval <= 0) then
		--	interval = 1
		--end
        --d(type(interval)
        --d(interval)
		zo_callLater(function() self:Elapsed() end, interval)
	end
end

-- "state" is passed into timer callback
-- "interval" is optional, and can be used to change the timer interval during execution
function X4D_Timer:Start(interval, state)
	if (state ~= nil) then
		self._state = state
	end
	if (interval ~= nil) then
		self._interval = interval
	end
	if (self._enabled) then
		return
	end
	self._enabled = true

--    if (self._interval ~= nil) then
--        X4D.Log:Warning("Timer interval: " .. type(self._interval) .. " " .. tostring(self._interval))
--    else
--        X4D.Log:Warning("Timer Interval: nil")
--    end

	zo_callLater(function() self:Elapsed() end, self._interval)
    return self
end

function X4D_Timer:Stop()
	self._enabled = false
    return self
end

setmetatable(X4D_Timer, { __call = X4D_Timer.New })

function X4D_Async:CreateTimer(callback, interval, state)
    return X4D_Timer:New(callback, interval, state)
end
