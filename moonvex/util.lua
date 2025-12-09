-- MoonVex Utility Module
-- util.lua

local util = {}

-- TODO Character array utility
function util.chararray(str)
    local t = {}
    for i = 1, #str do
        t[i] = str:sub(i, i)
    end
    return t
end

-- TODO Shuffle table
function util.shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

-- TODO Split string into chunks
function util.splitString(str, chunkSize)
    local chunks = {}
    for i = 1, #str, chunkSize do
        table.insert(chunks, str:sub(i, i + chunkSize - 1))
    end
    return chunks
end

-- TODO Deep copy table
function util.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[util.deepcopy(orig_key)] = util.deepcopy(orig_value)
        end
        setmetatable(copy, util.deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- TODO XOR operation
function util.xor(a, b)
    local result = 0
    local bitval = 1
    while a > 0 or b > 0 do
        if a % 2 ~= b % 2 then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

-- TODO Escape string for Lua
function util.escapeString(str)
    return str:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
end

-- TODO Check if string is valid identifier
function util.isValidIdentifier(str)
    return str:match("^[%a_][%w_]*$") ~= nil
end

-- TODO Random number in range
function util.randomRange(min, max)
    return math.random(min, max)
end

return util
