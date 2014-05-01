local X4D_Debug = LibStub:NewLibrary('X4D_Debug', 1000)
if (not X4D_Debug) then
	return
end

local X4D_Colors = LibStub('X4D_Colors')

X4D_Debug.TRACE_LEVELS = {
	VERBOSE = 0,
	INFORMATION = 1,
	WARNING = 2,
	ERROR = 3,
	CRITICAL = 4,
}

local TRACE_COLORS = {
	[X4D_Debug.TRACE_LEVELS.VERBOSE] = X4D_Colors.TRACE_VERBOSE,	
	[X4D_Debug.TRACE_LEVELS.INFORMATION] = X4D_Colors.TRACE_INFORMATION,	
	[X4D_Debug.TRACE_LEVELS.WARNING] = X4D_Colors.TRACE_WARNING,	
	[X4D_Debug.TRACE_LEVELS.ERROR] = X4D_Colors.TRACE_ERROR,	
	[X4D_Debug.TRACE_LEVELS.CRITICAL] = X4D_Colors.TRACE_CRITICAL,	
	[X4D_Debug.TRACE_LEVELS.VERBOSE+100] = X4D_Colors.DeriveHighlight(X4D_Colors.TRACE_VERBOSE),	
	[X4D_Debug.TRACE_LEVELS.INFORMATION+100] = X4D_Colors.DeriveHighlight(X4D_Colors.TRACE_INFORMATION),	
	[X4D_Debug.TRACE_LEVELS.WARNING+100] = X4D_Colors.DeriveHighlight(X4D_Colors.TRACE_WARNING),	
	[X4D_Debug.TRACE_LEVELS.ERROR+100] = X4D_Colors.DeriveHighlight(X4D_Colors.TRACE_ERROR),	
	[X4D_Debug.TRACE_LEVELS.CRITICAL+100] = X4D_Colors.DeriveHighlight(X4D_Colors.TRACE_CRITICAL),	
}

local TRACE_FORMATS = {
	[X4D_Debug.TRACE_LEVELS.VERBOSE] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.VERBOSE] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.VERBOSE+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.VERBOSE] .. '] (%s) %s',	
	[X4D_Debug.TRACE_LEVELS.INFORMATION] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.INFORMATION] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.INFORMATION+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.INFORMATION] .. '] (%s) %s',	
	[X4D_Debug.TRACE_LEVELS.WARNING] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.WARNING] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.WARNING+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.WARNING] .. '] (%s) %s',	
	[X4D_Debug.TRACE_LEVELS.ERROR] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.ERROR] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.ERROR+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.ERROR] .. '] (%s) %s',	
	[X4D_Debug.TRACE_LEVELS.CRITICAL] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.CRITICAL] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.CRITICAL+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.CRITICAL] .. '] (%s) %s',	
}

local TRACE_FORMATS_NOSOURCE = {
	[X4D_Debug.TRACE_LEVELS.VERBOSE] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.VERBOSE] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.VERBOSE+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.VERBOSE] .. '] %s',	
	[X4D_Debug.TRACE_LEVELS.INFORMATION] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.INFORMATION] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.INFORMATION+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.INFORMATION] .. '] %s',	
	[X4D_Debug.TRACE_LEVELS.WARNING] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.WARNING] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.WARNING+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.WARNING] .. '] %s',	
	[X4D_Debug.TRACE_LEVELS.ERROR] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.ERROR] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.ERROR+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.ERROR] .. '] %s',	
	[X4D_Debug.TRACE_LEVELS.CRITICAL] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.CRITICAL] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.CRITICAL+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.CRITICAL] .. '] %s',	
}

local _minTraceLevel = X4D_Debug.TRACE_LEVELS.WARNING

function X4D_Debug:SetTraceLevel(level)
	_minTraceLevel = level
end

local _systemHighlightColor = X4D_Colors.DeriveHighlight(X4D_Colors.SYSTEM)

local function LogInternal(source, level, message)
    if (CHAT_SYSTEM == nil) then
    	return false
    end
	local L_level = level or 0
	if (L_level < _minTraceLevel) then
		return false
	end
	if (source == nil or source:len() == 0) then
        CHAT_SYSTEM:AddMessage(string.format(TRACE_FORMATS_NOSOURCE[L_level], GetTimeString(), message))
	else
        CHAT_SYSTEM:AddMessage(string.format(TRACE_FORMATS[L_level], GetTimeString(), source, message))			
	end
	return true
end

local function TableToString(table, recurse)
	if (recurse == nil) then
		recurse = { 
			[table] = true,
		}
	else
		if (recurse[table]) then
			return tostring(table)
		end
	end
	local str = ''
	for k,v in pairs(table) do
		if (str:len() > 0) then
			str = str .. ', '
		end
		if (type(k) == 'table') then
			k = TableToString(k, recurse)
		elseif (type(k) == 'string') then
			k = '"' .. k .. '"'
		else
			k = tostring(k or 'nil')
		end
		if (type(v) == 'table') then
			v = TableToString(v, recurse)
		elseif (type(v) == 'string') then
			v = '"' .. v .. '"'
		else
			v = tostring(v or 'nil')
		end
		str = str .. '[' .. k .. ']' .. '=' .. v
	end
	return '{ ' .. str .. ' }'
end

function X4D_Debug:LogTable(source, level, table)
	local message = TableToString(table)
	return LogInternal(source, level, message)
end

function X4D_Debug:LogString(source, level, message)
	return LogInternal(source, level, message)
end

function X4D_Debug:Log(source, level, ...)
	if (level < _minTraceLevel) then
		return
	end
    for i = 1, select("#", ...) do
        local message = select(i, ...)
        if (message ~= nil) then
	        if(type(message) == "table") then
	            self:LogTable(source, level, message)
	        else
				if (type(message) ~= 'string') then
					pcall(function() message = tostring(message or '') end)
				end
	            self:LogString(source, level, message)
	        end
	    end
    end
end

function X4D_Debug:Verbose(message, source)
	self:Log(source, X4D_Debug.TRACE_LEVELS.VERBOSE, message)
end

function X4D_Debug:Information(message, source)
	self:Log(source, X4D_Debug.TRACE_LEVELS.INFORMATION, message)
end

function X4D_Debug:Warning(message, source)
	self:Log(source, X4D_Debug.TRACE_LEVELS.WARNING, message)
end

function X4D_Debug:Error(message, source)
	self:Log(source, X4D_Debug.TRACE_LEVELS.ERROR, message)
end

function X4D_Debug:Critical(message, source)
	self:Log(source, X4D_Debug.TRACE_LEVELS.CRITICAL, message)
end

--[[

Example Usage:

X4D.Debug:SetTraceLevel(X4D_DEBUG.TRACE_LEVELS.VERBOSE)

X4D.Debug:Log('MyAddon', X4D_DEBUG.TRACE_LEVELS.INFO, 'This is a test.')

X4D.Debug:Verbose('This is a test.', 'MyAddon')
X4D.Debug:Info('This is a test.', 'MyAddon')
X4D.Debug:Warn('This is a test.', 'MyAddon')
X4D.Debug:Error('This is a test.', 'MyAddon')
X4D.Debug:Critical('This is a test.', 'MyAddon')

]]