-- MoonVex Obfuscator V1.0
-- Main Entry Point
-- By Shizo

local config = require("config")
local util = require("util")
local namegen = require("namegen")
local encoder = require("encoder")
local vm = require("vm")

local MoonVex = {}

function MoonVex.obfuscate(code, options)
    options = options or {}
    
    -- Merge with default config
    for k, v in pairs(config.default) do
        if options[k] == nil then
            options[k] = v
        end
    end
    
    math.randomseed(os.time())
    
    -- Prepare name generator
    namegen.prepare()
    
    -- Generate XOR keys
    local keys = encoder.generateKeys()
    
    -- Parse and process code
    local instructions = vm.parseCode(code, options)
    
    -- Generate VM bytecode
    local bytecode = vm.generateBytecode(instructions, keys, options)
    
    -- Add watermark if enabled
    if options.watermark then
        bytecode = config.watermark .. " " .. bytecode
    end
    
    return bytecode
end

function MoonVex.obfuscateFile(inputPath, outputPath, options)
    local file = io.open(inputPath, "r")
    if not file then
        error("Cannot open input file: " .. inputPath)
    end
    
    local code = file:read("*all")
    file:close()
    
    local obfuscated = MoonVex.obfuscate(code, options)
    
    local outFile = io.open(outputPath, "w")
    if not outFile then
        error("Cannot open output file: " .. outputPath)
    end
    
    outFile:write(obfuscated)
    outFile:close()
    
    return true
end

return MoonVex
