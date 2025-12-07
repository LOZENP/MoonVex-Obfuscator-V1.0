-- MoonVex Encoder Module
-- encoder.lua

local util = require("util")
local config = require("config")

local encoder = {}

function encoder.generateKeys()
    local keys = {
        key1 = {},
        key2 = {},
        key3 = {},
        strKey1 = {},
        strKey2 = {}
    }
    
    for i = 1, 128 do
        keys.key1[i] = math.random(1, 255)
        keys.key2[i] = math.random(1, 255)
        keys.key3[i] = math.random(1, 255)
    end
    
    for i = 1, 64 do
        keys.strKey1[i] = math.random(1, 255)
        keys.strKey2[i] = math.random(1, 255)
    end
    
    return keys
end

function encoder.encryptString(str, keys)
    local encrypted = {}
    for i = 1, #str do
        local byte = string.byte(str, i)
        local encByte = util.xor(byte, keys.strKey1[((i-1) % 64) + 1])
        encByte = util.xor(encByte, keys.strKey2[((i-1) % 64) + 1])
        table.insert(encrypted, encByte)
    end
    return "{" .. table.concat(encrypted, ",") .. "}"
end

function encoder.encryptInstruction(instr, index, keys)
    local e1 = util.xor(instr[1], keys.key1[((index-1) % 128) + 1])
    local e2 = util.xor(instr[2], keys.key1[((index-1) % 128) + 1])
    local e3 = util.xor(instr[3], keys.key1[((index-1) % 128) + 1])
    local e4 = util.xor(instr[4], keys.key1[((index-1) % 128) + 1])
    
    e1 = util.xor(e1, keys.key2[((index-1) % 128) + 1])
    e2 = util.xor(e2, keys.key2[((index-1) % 128) + 1])
    e3 = util.xor(e3, keys.key2[((index-1) % 128) + 1])
    e4 = util.xor(e4, keys.key2[((index-1) % 128) + 1])
    
    e1 = util.xor(e1, keys.key3[((index-1) % 128) + 1])
    e2 = util.xor(e2, keys.key3[((index-1) % 128) + 1])
    e3 = util.xor(e3, keys.key3[((index-1) % 128) + 1])
    e4 = util.xor(e4, keys.key3[((index-1) % 128) + 1])
    
    return "{" .. e1 .. "," .. e2 .. "," .. e3 .. "," .. e4 .. "}"
end

function encoder.numberToExpression(num)
    local expressions = {
        function() return "(" .. (num + math.random(100, 999)) .. "-" .. math.random(100, 999) .. ")" end,
        function() 
            local mult = math.random(2, 10)
            return "(" .. (num * mult) .. "/" .. mult .. ")" 
        end,
        function() return "(" .. (num + math.random(10, 99)) .. "-" .. math.random(10, 99) .. ")" end,
    }
    return expressions[math.random(1, #expressions)]()
end

function encoder.stringToExpression(str)
    if #str == 0 then return "''" end
    local parts = {}
    for i = 1, #str do
        local byte = string.byte(str, i)
        table.insert(parts, "string.char(" .. byte .. ")")
    end
    return "(" .. table.concat(parts, "..") .. ")"
end

return encoder
