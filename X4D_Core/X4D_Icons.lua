local X4D_Icons = LibStub:NewLibrary('X4D_Icons', 1001)
if (not X4D_Icons) then
	return
end
local X4D = LibStub('X4D')
X4D.Icons = X4D_Icons

function X4D_Icons.Create(filename, width, height)
    return string.format('|t%u:%u:%s|t', width or 16, height or 16, filename)
end
