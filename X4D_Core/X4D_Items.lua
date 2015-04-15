local X4D_Items = LibStub:NewLibrary('X4D_Items', 1001)
if (not X4D_Items) then
	return
end

local _itemQualities = {
    [0] = {
        Level = 0,
        Name = 'Junk',
        NormalizedName = 'JUNK',
    },
    [1] = {
        Level = 1,
        Name = 'Normal',
        NormalizedName = 'NORMAL',
    },
    [2] = {
        Level = 2,
        Name = 'Fine',
        NormalizedName = 'FINE',
    },
    [3] = {
        Level = 3,
        Name = 'Superior',
        NormalizedName = 'SUPERIOR',
    },
    [4] = {
        Level = 4,
        Name = 'Epic',
        NormalizedName = 'EPIC',
    },
    [5] = {
        Level = 5,
        Name = 'Legendary',
        NormalizedName = 'LEGENDARY',
    }
}

function X4D_Items.ToQualityString(v)    
    return _itemQualities[v].Name
end

function X4D_Items.FromQualityString(v)
    local normalized = tostring(v):upper()
	for level,quality in pairs(_itemQualities) do
        if (quality.NormalizedName == normalized) then
            return quality.Level
        end
    end
end
