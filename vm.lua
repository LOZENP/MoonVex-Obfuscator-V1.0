-- MoonVex VM Module
-- vm.lua
-- This will modify soon

local util = require("util")
local namegen = require("namegen")
local encoder = require("encoder")
local config = require("config")

local vm = {}

function vm.parseCode(code, options)
    local instructions = {}
    local constPool = {}
    local constantArray = {}
    local constantLookup = {}
    local constantIndex = 1
    
    local function addToConstantArray(value)
        if not constantLookup[value] then
            constantArray[constantIndex] = value
            constantLookup[value] = constantIndex
            constantIndex = constantIndex + 1
        end
        return constantLookup[value]
    end
    
    local function addConst(val)
        addToConstantArray(val)
        table.insert(constPool, val)
        return #constPool - 1
    end
    
    local function emitInstr(op, a, b, c)
        table.insert(instructions, {op, a or 0, b or 0, c or 0})
    end
    
    local lines = {}
    for line in code:gmatch("[^\r\n]+") do
        if line:match("%S") then
            table.insert(lines, line)
        end
    end
    
    local complexityMultiplier = options.complexityMultiplier or 3
    
    -- Parse each line
    for _, line in ipairs(lines) do
        if line:match("print") then
            local str = line:match('["\']([^"\']+)["\']')
            if str then
                emitInstr(math.random(500, 600), 0, addConst(str), 0)
                for j = 1, complexityMultiplier do
                    emitInstr(math.random(100, 1004), math.random(0, 50), math.random(0, 50), math.random(0, 50))
                end
            end
        elseif line:match("warn") then
            local str = line:match('["\']([^"\']+)["\']')
            if str then
                emitInstr(math.random(600, 700), 0, addConst(str), 0)
                for j = 1, complexityMultiplier do
                    emitInstr(math.random(100, 1004), math.random(0, 50), math.random(0, 50), math.random(0, 50))
                end
            end
        elseif line:match("wait") or line:match("task%.wait") then
            local num = line:match("%(([%d%.]+)%)")
            if num then
                emitInstr(math.random(800, 900), 0, tonumber(num), 0)
                for j = 1, complexityMultiplier do
                    emitInstr(math.random(100, 1004), math.random(0, 50), math.random(0, 50), math.random(0, 50))
                end
            end
        else
            for j = 1, complexityMultiplier * 2 do
                emitInstr(math.random(100, 1004), math.random(0, 50), math.random(0, 50), math.random(0, 50))
            end
        end
    end
    
    -- Add dummy constants
    for i = 1, util.randomRange(options.dummyConstantsMin, options.dummyConstantsMax) do
        local dummyType = math.random(1, 4)
        if dummyType == 1 then
            addToConstantArray(math.random(1, 999999))
        elseif dummyType == 2 then
            addToConstantArray(math.random() * 1000)
        elseif dummyType == 3 then
            addToConstantArray(tostring(math.random(100000, 999999)))
        else
            addToConstantArray(math.random() > 0.5)
        end
    end
    
    -- Shuffle constant array
    local indices = {}
    for i = 1, #constantArray do
        table.insert(indices, i)
    end
    util.shuffle(indices)
    
    local shuffledConstants = {}
    local shuffleMap = {}
    for newIdx, oldIdx in ipairs(indices) do
        shuffledConstants[newIdx] = constantArray[oldIdx]
        shuffleMap[oldIdx] = newIdx
    end
    
    return {
        instructions = instructions,
        constPool = constPool,
        constantArray = shuffledConstants
    }
end

function vm.generateBytecode(data, keys, options)
    local vn = namegen.generateMultiple(35)
    
    -- Generate vararg parameters
    local varargCount = util.randomRange(options.varargMin, options.varargMax)
    local varargParams = namegen.generateMultiple(varargCount)
    local varargStr = table.concat(varargParams, ",")
    
    -- Encrypt instructions
    local instrStr = {}
    for i, instr in ipairs(data.instructions) do
        table.insert(instrStr, encoder.encryptInstruction(instr, i, keys))
    end
    
    -- Encrypt strings in const pool
    local encryptedConstPool = {}
    for _, const in ipairs(data.constPool) do
        if type(const) == "string" then
            table.insert(encryptedConstPool, encoder.encryptString(const, keys))
        else
            table.insert(encryptedConstPool, tostring(const))
        end
    end
    
    -- Build constant array string
    local constArrayParts = {}
    for _, v in ipairs(data.constantArray) do
        if type(v) == "string" then
            table.insert(constArrayParts, '"' .. util.escapeString(v) .. '"')
        elseif type(v) == "number" then
            table.insert(constArrayParts, tostring(v))
        elseif type(v) == "boolean" then
            table.insert(constArrayParts, tostring(v))
        else
            table.insert(constArrayParts, "nil")
        end
    end
    
    -- Build VM parts
    local parts = {}
    
    table.insert(parts, "return(function(" .. varargStr .. ",...) ")
    table.insert(parts, "local " .. vn[1] .. "={" .. table.concat(keys.key1, ",") .. "} ")
    table.insert(parts, "local " .. vn[2] .. "={" .. table.concat(keys.key2, ",") .. "} ")
    table.insert(parts, "local " .. vn[3] .. "={" .. table.concat(keys.key3, ",") .. "} ")
    table.insert(parts, "local " .. vn[4] .. "={" .. table.concat(keys.strKey1, ",") .. "} ")
    table.insert(parts, "local " .. vn[5] .. "={" .. table.concat(keys.strKey2, ",") .. "} ")
    table.insert(parts, "local " .. vn[6] .. "={" .. table.concat(encryptedConstPool, ",") .. "} ")
    table.insert(parts, "local " .. vn[7] .. "={" .. table.concat(constArrayParts, ",") .. "} ")
    
    -- XOR function
    table.insert(parts, "local function " .. vn[8] .. "(a,b) local r=0 local v=1 while a>0 or b>0 do if a%2~=b%2 then r=r+v end v=v*2 a=math.floor(a/2) b=math.floor(b/2) end return r end ")
    
    -- String decrypt function
    table.insert(parts, "local function " .. vn[9] .. "(t) local s='' for i=1,#t do local c=" .. vn[8] .. "(t[i]," .. vn[5] .. "[((i-1)%64)+1]) c=" .. vn[8] .. "(c," .. vn[4] .. "[((i-1)%64)+1]) s=s..string.char(c) end return s end ")
    
    -- VM execute function
    table.insert(parts, "local function " .. vn[10] .. "(ins) local dec={} for i=1,#ins do local x=ins[i] local e1,e2,e3,e4=x[1],x[2],x[3],x[4] ")
    table.insert(parts, "e1=" .. vn[8] .. "(e1," .. vn[3] .. "[((i-1)%128)+1]) e2=" .. vn[8] .. "(e2," .. vn[3] .. "[((i-1)%128)+1]) e3=" .. vn[8] .. "(e3," .. vn[3] .. "[((i-1)%128)+1]) e4=" .. vn[8] .. "(e4," .. vn[3] .. "[((i-1)%128)+1]) ")
    table.insert(parts, "e1=" .. vn[8] .. "(e1," .. vn[2] .. "[((i-1)%128)+1]) e2=" .. vn[8] .. "(e2," .. vn[2] .. "[((i-1)%128)+1]) e3=" .. vn[8] .. "(e3," .. vn[2] .. "[((i-1)%128)+1]) e4=" .. vn[8] .. "(e4," .. vn[2] .. "[((i-1)%128)+1]) ")
    table.insert(parts, "e1=" .. vn[8] .. "(e1," .. vn[1] .. "[((i-1)%128)+1]) e2=" .. vn[8] .. "(e2," .. vn[1] .. "[((i-1)%128)+1]) e3=" .. vn[8] .. "(e3," .. vn[1] .. "[((i-1)%128)+1]) e4=" .. vn[8] .. "(e4," .. vn[1] .. "[((i-1)%128)+1]) ")
    table.insert(parts, "dec[i]={e1,e2,e3,e4} end ")
    
    -- Execute loop
    table.insert(parts, "local pc=1 while pc<=#dec do local op,a,b,c=dec[pc][1],dec[pc][2],dec[pc][3],dec[pc][4] ")
    table.insert(parts, "if op>=500 and op<=600 then print(" .. vn[9] .. "(" .. vn[6] .. "[b+1])) ")
    table.insert(parts, "elseif op>=600 and op<=700 then warn(" .. vn[9] .. "(" .. vn[6] .. "[b+1])) ")
    table.insert(parts, "elseif op>=800 and op<=900 then wait(b) end ")
    table.insert(parts, "pc=pc+1 end end ")
    
    -- Instructions and execute
    table.insert(parts, "local " .. vn[11] .. "={" .. table.concat(instrStr, ",") .. "} ")
    table.insert(parts, "return " .. vn[10] .. "(" .. vn[11] .. ") end)(...)")
    
    return table.concat(parts, "")
end

return vm
