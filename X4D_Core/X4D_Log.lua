local X4D_Log = LibStub:NewLibrary("X4D_Log", 1020)
if (not X4D_Log) then
	return
end
local X4D = LibStub("X4D")
X4D.Log = X4D_Log 

X4D_Log.TRACE_LEVELS = {
	DEBUG = 0,
	VERBOSE = 1,
	INFORMATION = 2,
	WARNING = 3,
	ERROR = 4,
	CRITICAL = 5,
    SYSTEM = 512,
    RAW = 8192,
}
local _minTraceLevel = 
    X4D_Log.TRACE_LEVELS.INFORMATION
    --X4D_Log.TRACE_LEVELS.VERBOSE
    --X4D_Log.TRACE_LEVELS.DEBUG

local TRACE_COLORS = {
	[X4D_Log.TRACE_LEVELS.DEBUG] = X4D.Colors.TRACE_DEBUG,	
	[X4D_Log.TRACE_LEVELS.VERBOSE] = X4D.Colors.TRACE_VERBOSE,	
	[X4D_Log.TRACE_LEVELS.INFORMATION] = X4D.Colors.TRACE_INFORMATION,	
	[X4D_Log.TRACE_LEVELS.WARNING] = X4D.Colors.TRACE_WARNING,	
	[X4D_Log.TRACE_LEVELS.ERROR] = X4D.Colors.TRACE_ERROR,	
	[X4D_Log.TRACE_LEVELS.CRITICAL] = X4D.Colors.TRACE_CRITICAL,	
	[X4D_Log.TRACE_LEVELS.SYSTEM] = X4D.Colors.SYSTEM,
	[X4D_Log.TRACE_LEVELS.RAW] = "",
	[X4D_Log.TRACE_LEVELS.DEBUG+100] = X4D.Colors:DeriveHighlight(X4D.Colors.TRACE_DEBUG),	
	[X4D_Log.TRACE_LEVELS.VERBOSE+100] = X4D.Colors:DeriveHighlight(X4D.Colors.TRACE_VERBOSE),	
	[X4D_Log.TRACE_LEVELS.INFORMATION+100] = X4D.Colors:DeriveHighlight(X4D.Colors.TRACE_INFORMATION),	
	[X4D_Log.TRACE_LEVELS.WARNING+100] = X4D.Colors:DeriveHighlight(X4D.Colors.TRACE_WARNING),	
	[X4D_Log.TRACE_LEVELS.ERROR+100] = X4D.Colors:DeriveHighlight(X4D.Colors.TRACE_ERROR),	
	[X4D_Log.TRACE_LEVELS.CRITICAL+100] = X4D.Colors:DeriveHighlight(X4D.Colors.TRACE_CRITICAL),	
	[X4D_Log.TRACE_LEVELS.SYSTEM+100] = X4D.Colors:DeriveHighlight(X4D.Colors.TRACE_SYSTEM),	
	[X4D_Log.TRACE_LEVELS.RAW+100] = "",	
}

local TRACE_FORMATS = {
	[X4D_Log.TRACE_LEVELS.DEBUG] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.DEBUG] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.DEBUG+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.DEBUG] .. "] (%s) %s",	
	[X4D_Log.TRACE_LEVELS.VERBOSE] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.VERBOSE] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.VERBOSE+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.VERBOSE] .. "] (%s) %s",	
	[X4D_Log.TRACE_LEVELS.INFORMATION] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.INFORMATION] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.INFORMATION+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.INFORMATION] .. "] (%s) %s",	
	[X4D_Log.TRACE_LEVELS.WARNING] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.WARNING] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.WARNING+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.WARNING] .. "] (%s) %s",	
	[X4D_Log.TRACE_LEVELS.ERROR] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.ERROR] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.ERROR+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.ERROR] .. "] (%s) %s",	
	[X4D_Log.TRACE_LEVELS.CRITICAL] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.CRITICAL] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.CRITICAL+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.CRITICAL] .. "] (%s) %s",	
	[X4D_Log.TRACE_LEVELS.SYSTEM] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.SYSTEM] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.SYSTEM+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.SYSTEM] .. "] (%s) %s",	
	[X4D_Log.TRACE_LEVELS.RAW] = "%s",	
}

local TRACE_FORMATS_NOSOURCE = {
	[X4D_Log.TRACE_LEVELS.DEBUG] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.DEBUG] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.DEBUG+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.DEBUG] .. "] %s",	
	[X4D_Log.TRACE_LEVELS.VERBOSE] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.VERBOSE] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.VERBOSE+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.VERBOSE] .. "] %s",	
	[X4D_Log.TRACE_LEVELS.INFORMATION] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.INFORMATION] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.INFORMATION+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.INFORMATION] .. "] %s",	
	[X4D_Log.TRACE_LEVELS.WARNING] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.WARNING] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.WARNING+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.WARNING] .. "] %s",	
	[X4D_Log.TRACE_LEVELS.ERROR] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.ERROR] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.ERROR+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.ERROR] .. "] %s",	
	[X4D_Log.TRACE_LEVELS.CRITICAL] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.CRITICAL] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.CRITICAL+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.CRITICAL] .. "] %s",	
	[X4D_Log.TRACE_LEVELS.SYSTEM] = TRACE_COLORS[X4D_Log.TRACE_LEVELS.SYSTEM] .. "[" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.SYSTEM+100] .. "%s" .. TRACE_COLORS[X4D_Log.TRACE_LEVELS.SYSTEM] .. "] %s",	
	[X4D_Log.TRACE_LEVELS.RAW] = "%s",	
}

function X4D_Log:SetTraceLevel(level)
	_minTraceLevel = level
end

function X4D_Log:IsDebugEnabled()
	return _minTraceLevel == X4D_Log.TRACE_LEVELS.DEBUG
end
function X4D_Log:IsVerboseEnabled()
	return _minTraceLevel == X4D_Log.TRACE_LEVELS.VERBOSE
end

local _buffer = nil
local _initialized = false

local function TryFlushMessageBuffer()
    if (_initialized) then
        local buf = _buffer
        _buffer = nil
        if (buf ~= nil) then
            for _,msg in pairs(buf) do
                CHAT_SYSTEM:AddMessage(msg)
            end
        end
    end
end

local function LogInternal(source, level, message)
	local L_level = level or X4D_Log.TRACE_LEVELS.VERBOSE
	if (L_level < _minTraceLevel) then
		return false
	end
    if (level ~= X4D_Log.TRACE_LEVELS.RAW) then
        message = message:gsub("\n", "\n" .. TRACE_COLORS[L_level])
	    if (source == nil or source:len() == 0) then
            message = string.format(TRACE_FORMATS_NOSOURCE[L_level], GetTimeString(), message)        
	    else
            message = string.format(TRACE_FORMATS[L_level], GetTimeString(), source, message)
	    end
    end
    if ((CHAT_SYSTEM == nil) or (not _initialized)) then
        if (_buffer == nil) then
            _buffer = {}
        end
        table.insert(_buffer, message)
    	return false
    end

    TryFlushMessageBuffer()

    CHAT_SYSTEM:AddMessage(message)
	return true
end

local function TableToString(table, recurse)
	if (type(table.Observe) == "function") then
		-- if table looks like an observable, treat it as a value-source, instead
		local v = table()
		if (type(v) == "table") then
			return TableToString(v)
		elseif (type(v) == "string") then
			return "'" .. v .. "'"
		else
			return tostring(v)
		end
	else
		if (recurse == nil) then
			recurse = { 
				[table] = true,
			}
		else
			if (recurse[table]) then
				return tostring(table)
			end
		end
		local str = ""
		for k,v in pairs(table) do
			if (str:len() > 0) then
				str = str .. ", "
			end
			if (type(k) == "table") then
				k = TableToString(k, recurse)
			elseif (type(k) == "string") then
				k = "'" .. k .. "'"
			else
				k = tostring(k or "nil")
			end
			if (type(v) == "table") then
				v = TableToString(v, recurse)
			elseif (type(v) == "string") then
				v = "'" .. v .. "'"
			else
				v = tostring(v or "nil")
			end
			str = str .. "[" .. k .. "]" .. "=" .. v
		end
		return "{ " .. str .. " }"
	end
end

function X4D_Log:LogTable(source, level, table)
	local message = TableToString(table)
	return LogInternal(source, level, message)
end

function X4D_Log:LogString(source, level, message)
	return LogInternal(source, level, message)
end

function X4D_Log:Log(source, level, ...)
	if (level < _minTraceLevel) then
		return
	end
    for i = 1, select('#', ...) do
        local message = select(i, ...)
        if (message ~= nil) then
	        if(type(message) == "table") then
	            self:LogTable(source, level, message)
	        else
				if (type(message) ~= "string") then
					pcall(function() message = tostring(message or "") end)
				end
	            self:LogString(source, level, message)
	        end
	    end
    end
end

function X4D_Log:Debug(message, source)
	X4D_Log:Log(source, X4D_Log.TRACE_LEVELS.DEBUG, message)
end

function X4D_Log:Verbose(message, source)
	X4D_Log:Log(source, X4D_Log.TRACE_LEVELS.VERBOSE, message)
end

function X4D_Log:Information(message, source)
	X4D_Log:Log(source, X4D_Log.TRACE_LEVELS.INFORMATION, message)
end

function X4D_Log:Warning(message, source)
	X4D_Log:Log(source, X4D_Log.TRACE_LEVELS.WARNING, message)
end

function X4D_Log:Error(message, source)
    if (_minTraceLevel <= X4D_Log.TRACE_LEVELS.DEBUG) then
        d(type(message))
        d(message)
        d(type(source))
    end
	X4D_Log:Log(source, X4D_Log.TRACE_LEVELS.ERROR, message)
end

function X4D_Log:Critical(message, source)
	X4D_Log:Log(source, X4D_Log.TRACE_LEVELS.CRITICAL, message)
end

function X4D_Log:System(message, source)
	X4D_Log:Log(source, X4D_Log.TRACE_LEVELS.SYSTEM, message)
end

function X4D_Log:Raw(message, source)
	X4D_Log:Log(source, X4D_Log.TRACE_LEVELS.RAW, message)
end

--[[

Example Usage:

X4D.Log:SetTraceLevel(X4D_Log.TRACE_LEVELS.DEBUG)

X4D.Log:Log("MyAddon", X4D_Log.TRACE_LEVELS.INFO, "This is a test.")

X4D.Log:Debug("This is a test.", "MyAddon")
X4D.Log:Debug("This is a test.")
X4D.Log:Verbose("This is a test.", "MyAddon")
X4D.Log:Verbose("This is a test.")
X4D.Log:Info("This is a test.", "MyAddon")
X4D.Log:Info("This is a test.")
X4D.Log:Warn("This is a test.", "MyAddon")
X4D.Log:Warn("This is a test.")
X4D.Log:Error("This is a test.", "MyAddon")
X4D.Log:Error("This is a test.")
X4D.Log:Critical("This is a test.", "MyAddon")
X4D.Log:Critical("This is a test.")

]]

-- add global hook for 'd()' so we can wrap d() calls with a timestamp, and also queue it during init (when CHAT_SYSTEM is not yet ready)
function d(...)    
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if (type(value) == "table") then
            X4D.Log:System(value)
        else
            X4D.Log:System(tostring (value))
        end
    end
end

EVENT_MANAGER:RegisterForEvent("X4D_Log_Activated", EVENT_PLAYER_ACTIVATED, function()
    _initialized = true
    TryFlushMessageBuffer()
end)
