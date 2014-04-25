local X4D_Debug = LibStub:NewLibrary('X4D_Debug', 1.0);
if (not X4D_Debug) then
	return;
end

local X4D_Colors = LibStub('X4D_Colors');

X4D_Debug.TRACE_LEVELS = {
	VERBOSE = 0,
	INFORMATION = 1,
	WARNING = 2,
	ERROR = 3,
	CRITICAL = 4,
};

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
};

local TRACE_FORMATS = {
	[X4D_Debug.TRACE_LEVELS.VERBOSE] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.VERBOSE] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.VERBOSE+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.VERBOSE] .. '] (%s) %s',	
	[X4D_Debug.TRACE_LEVELS.INFORMATION] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.INFORMATION] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.INFORMATION+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.INFORMATION] .. '] (%s) %s',	
	[X4D_Debug.TRACE_LEVELS.WARNING] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.WARNING] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.WARNING+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.WARNING] .. '] (%s) %s',	
	[X4D_Debug.TRACE_LEVELS.ERROR] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.ERROR] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.ERROR+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.ERROR] .. '] (%s) %s',	
	[X4D_Debug.TRACE_LEVELS.CRITICAL] = TRACE_COLORS[X4D_Debug.TRACE_LEVELS.CRITICAL] .. '[' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.CRITICAL+100] .. '%s' .. TRACE_COLORS[X4D_Debug.TRACE_LEVELS.CRITICAL] .. '] (%s) %s',	
};

local _minTraceLevel = X4D_Debug.TRACE_LEVELS.WARNING;

function X4D_Debug.SetTraceLevel(self, level)
	_minTraceLevel = level;
end

local _systemHighlightColor = X4D_Colors.DeriveHighlight(X4D_Colors.SYSTEM);

function X4D_Debug.Log(self, source, level, message)
	if (type(message) ~= 'string') then
		pcall(function() message = tostring(message or '') end);
	end
	if (level >= _minTraceLevel) then
		local L_source = source or "DBG";
		local L_level = level or 0;
		local format = TRACE_FORMATS[L_level];
		d(string.format(format, GetTimeString(), L_source, message));
		return true;
	else
		return false;
	end
end

function X4D_Debug.Verbose(self, message, source)
	self:Log(source, X4D_Debug.TRACE_LEVELS.VERBOSE, message);
end

function X4D_Debug.Information(self, message, source)
	self:Log(source, X4D_Debug.TRACE_LEVELS.INFORMATION, message);
end

function X4D_Debug.Warning(self, message, source)
	self:Log(source, X4D_Debug.TRACE_LEVELS.WARNING, message);
end

function X4D_Debug.Error(self, message, source)
	self:Log(source, X4D_Debug.TRACE_LEVELS.ERROR, message);
end

function X4D_Debug.Critical(self, message, source)
	self:Log(source, X4D_Debug.TRACE_LEVELS.CRITICAL, message);
end

--[[

Example Usage:

X4D.Debug:SetTraceLevel(X4D_DEBUG.TRACE_LEVELS.VERBOSE);

X4D.Debug:Log('MyAddon', X4D_DEBUG.TRACE_LEVELS.INFO, 'This is a test.');

X4D.Debug:Verbose('This is a test.', 'MyAddon');
X4D.Debug:Info('This is a test.', 'MyAddon');
X4D.Debug:Warn('This is a test.', 'MyAddon');
X4D.Debug:Error('This is a test.', 'MyAddon');
X4D.Debug:Critical('This is a test.', 'MyAddon');

]]