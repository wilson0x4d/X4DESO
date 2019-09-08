local X4D_Icons = LibStub:NewLibrary("X4D_Icons", 1020)
if (not X4D_Icons) then
	return
end
local X4D = LibStub("X4D")
X4D.Icons = X4D_Icons

local _icons58

EVENT_MANAGER:RegisterForEvent("X4D_Icons", EVENT_ADD_ON_LOADED, function(event, name)
    if (name ~= "X4D_Core") then
        return
    end
    X4D_Icons.DB = X4D.DB:Open("X4D_Icons")
    _icons58 = X4D_Icons.DB:Find("I58")
    if (_icons58 == nil) then
        _icons58 = {}
        X4D_Icons.DB:Add("I58", _icons58)
    end
    -- try scraping from misc API
    for i = 1, 16 do
        local filename = GetGuildRankLargeIcon(i)
        if (filename ~= nil) then
            X4D_Icons:ToIcon58(filename)
        end
        filename = GetGuildRankSmallIcon(i)
        if (filename ~= nil) then
            X4D_Icons:ToIcon58(filename)
        end
    end
end)

function X4D_Icons:CreateString(filename, width, height)
    return string.format("|t%u:%u:%s|t", width or 16, height or 16, filename or "EsoUI/Art/Icons/icon_missing.dds")
end

function X4D_Icons:CreateString58(icon58, width, height)
    local filename = _icons58[icon58]
    return self:CreateString(filename, width, height)
end

function X4D_Icons:ToIcon58(filename)
    local icon58 = base58(sha1(filename):FromHex())
    _icons58[icon58] = filename
    return icon58
end

function X4D_Icons:FromIcon58(icon58)
    local filename = _icons58[icon58]
    return filename
end