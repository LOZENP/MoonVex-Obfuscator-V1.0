-- MoonVex Name Generator Module
-- namegen.lua

local util = require("util")

local namegen = {}

local VarDigits = util.chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
local VarStartDigits = util.chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
local nameId = 0

function namegen.prepare()
    util.shuffle(VarDigits)
    util.shuffle(VarStartDigits)
    nameId = 0
end

function namegen.generate()
    local name = ''
    local id = nameId
    nameId = nameId + 1
    
    local d = id % #VarStartDigits
    id = (id - d) / #VarStartDigits
    name = name .. VarStartDigits[d + 1]
    
    while id > 0 do
        d = id % #VarDigits
        id = (id - d) / #VarDigits
        name = name .. VarDigits[d + 1]
    end
    
    return name
end

function namegen.generateMultiple(count)
    local names = {}
    for i = 1, count do
        table.insert(names, namegen.generate())
    end
    return names
end

function namegen.reset()
    nameId = 0
end

return namegen
