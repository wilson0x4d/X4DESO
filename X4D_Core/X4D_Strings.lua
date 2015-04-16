function string:Split(delimiter)
    local input = '' .. self;
    local result = {}
    for match in (input..delimiter):gmatch("(.-)"..delimiter) do
		local s = tostring(match)
		if (s:len() > 0) then
			table.insert(result, match)
		end
    end
    return result
end

function string:StartsWith(v)
    return string.sub(self, 1, string.len(v)) == v
end

function string:EndsWith(v)
    local input = '' .. self;
    return v=='' or string.sub(input,-string.len(v))==v
end
