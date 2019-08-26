local X4D_Async = LibStub:NewLibrary("X4D_Async", 1015)
if (not X4D_Async) then
	return
end
local X4D = LibStub("X4D")
X4D.Async = X4D_Async

local _nextTimerId = 0
local _timers = {}
X4D_Async.ActiveTimers = X4D.DB:Open(_timers)

local X4D_Timer = {}
local DEFAULT_TIMER_INTERVAL = 1000

--- <summary>
--- <para>Create a new instance of X4D_Timer</para>
--- <para>Timer continues to elapse until stopped.</para>
--- </summary>
--- <params>
--- <param name="callback">the callback to execute when the timer elapses, receives a reference to Timer instance and user state object</param>
--- <param name="interval">the interval at which the timer elapses</param>
--- </params>
function X4D_Timer:New(callback, interval, state, name)
    if (name ~= nil) then
        self.Name = name
    elseif (self.Name == nil) then
        self.Name = "$timer_" .. tostring(GetGameTimeMilliseconds())
    end
    local timerId = _nextTimerId
    _nextTimerId = _nextTimerId + 1
	local proto = {
        _id = timerId,
        _timestamp = 0,
--        _memory = 0, -- for diagnostic purposes only, requires retuning of GC to be of any value, and so commented out for Release
		_enabled = false,
		_callback = callback or (function(L_timer) self:Stop() end),
		_interval = interval or DEFAULT_TIMER_INTERVAL,
		_state = state or {},
	}
	setmetatable(proto, { __index = X4D_Timer })
	return proto
end

function X4D_Timer:IsEnabled()
	return self._enabled
end

function X4D_Timer:Elapsed(expectedId)	
	if (self._id ~= expectedId or not self._enabled) then
		--X4D.Log:Debug("Timer'"..expectedId.."' was intercepted and cancelled.")
		return
	end

    self._timestamp = GetGameTimeMilliseconds()
	if (not self._callback) then
		self:Stop()
		return
	end
	local success, err = pcall(self._callback, self, self._state)
	if (not success) then
		X4D.Log:Error(err, self.Name)
		return
	end
	if (self._enabled) then		
		zo_callLater(function()
			self:Elapsed(expectedId)
		end, self._interval)
	end
--    memory = (collectgarbage("count") - memory)
--    if (memory >= 100 or memory <= -100) then
--        X4D.Log:Debug(self.Name .. " memory delta: " .. (memory * 1024))
--    end
--    self._memory = memory

	if (self._id ~= expectedId) then
		--X4D.Log:Debug("Timer'"..expectedId.."' was NOT intercepted/cancelled, and may have overlapped with a later event.")
		return
	end

end

-- "state" is passed into timer callback
-- "interval" is optional, and can be used to change the timer interval during execution
function X4D_Timer:Start(interval, state, name)
	if (self._enabled or self._id ~= nil) then
		-- attempt cancellation of enabled/active task
		self:Stop()
	end
	-- schedule new
	local timerId = _nextTimerId
	_nextTimerId = _nextTimerId + 1
	self._id = timerId
    if (name ~= nil) then
        self.Name = name
    end
	if (state ~= nil) then
		self._state = state
    end
	if (interval ~= nil) then
		self._interval = interval
	end
	if (self._interval == nil or self._interval <= 0) then
		-- NOTE: enforcing a sane default
		self._interval = DEFAULT_TIMER_INTERVAL; 
	end
	if (self._enabled) then
		return
	end
	self._enabled = true
	X4D_Async.ActiveTimers:Add(timerId, self)
	zo_callLater(function() self:Elapsed(timerId) end, self._interval)
    return self
end

function X4D_Timer:Stop()
	if (self._id ~= nil) then
		X4D_Async.ActiveTimers:Remove(self._id)
		self._enabled = false
		self._id = nil
	end
    return self
end

setmetatable(X4D_Timer, { __call = X4D_Timer.New })

function X4D_Async:CreateTimer(callback, interval, state, name)
    return X4D_Timer:New(callback, interval, state, name)
end
