function string:Split(delimiter)
    local input = "" .. self
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
    local input = "" .. self
    return v=="" or string.sub(input,-string.len(v))==v
end

local _base58Table = "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"

function base58(input)
    local bignum0 = bignum(0)
    local bignum1 = bignum(1)
    local bignum58 = bignum(58)
    if (input == nil) then
        return nil
    end
    if (type(input) == "number") then
        input = bignum(input)
    end
    if (input.isBigNum ~= nil) then
        local output = {}
        local power = 1
        local result = bignum(0)
        local linear = bignum(0)
        while (input > bignum0) do
            BigNum.div(input, bignum58, result, linear)
            local L_linear = tonumber(tostring(linear)) + power
	        table.insert(output, _base58Table:sub(L_linear, L_linear))
	        input = input / 58
        end
        return table.concat(output):reverse()
    else
        if (type(input) ~= "string") then
            input = tostring(input) -- attempt conversion to base58 string regardless of type
        end
        if (input == nil) then
            return bignum(0)
        end
        local output = bignum(0)
        local power = bignum(0)
        local checkdigit = bignum(1)
        for linear in input:reverse():gmatch(".") do
	        output = output + (bignum(_base58Table:find(linear) - bignum1) * (bignum58 ^ power))
	        power = power + bignum1
        end
        return output
    end
end

function bignum(input)
--    if (type(input) == "number") then
--        return BigNum.new(input)
--    end
    return BigNum.new(input)
end

function hash(input)
    return sha1(tostring(input))
end

-- NOTE: *sadface*
if (debug ~= nil and debug.setmetatable ~= nil) then
    local number = {}
    function number:ToBase58()
        return base58(self)
    end
    local _ = 1977
    debug.setmetatable(_, { __index = number })
end

function string:FromBase58()
    return base58(self)
end

function string:ToSHA1()
    return sha1.sha1(self)
end

---
--- if result cannot be converted to/from Lua number, it is returned as a 'BigNum' result instead - these behave like Lua numbers but are NOT Lua numbers
function string:FromHex()
    local output = bignum(0)
    self:gsub('..', function(hex)
        output = (output * 256) + tonumber(hex, 16)
    end)
    return output
end