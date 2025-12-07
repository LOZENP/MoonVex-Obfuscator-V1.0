#!/usr/bin/env lua
-- MoonVex CLI
-- cli.lua

local MoonVex = require("main")

local function printHelp()
    print([[
MoonVex Obfuscator V1.0
Usage: lua cli.lua [options] <input> <output>

Options:
  -h, --help              Show this help message
  -w, --no-watermark      Disable watermark
  -l, --layers <n>        Encryption layers (default: 3)
  -c, --complexity <n>    Complexity multiplier (default: 3)
  -v, --verbose           Verbose output

Examples:
  lua cli.lua script.lua output.lua
  lua cli.lua -w script.lua output.lua
  lua cli.lua --layers 5 script.lua output.lua
]])
end

local function parseArgs(args)
    local options = {}
    local files = {}
    
    local i = 1
    while i <= #args do
        local arg = args[i]
        
        if arg == "-h" or arg == "--help" then
            printHelp()
            os.exit(0)
        elseif arg == "-w" or arg == "--no-watermark" then
            options.watermark = false
        elseif arg == "-l" or arg == "--layers" then
            i = i + 1
            options.encryptionLayers = tonumber(args[i])
        elseif arg == "-c" or arg == "--complexity" then
            i = i + 1
            options.complexityMultiplier = tonumber(args[i])
        elseif arg == "-v" or arg == "--verbose" then
            options.verbose = true
        else
            table.insert(files, arg)
        end
        
        i = i + 1
    end
    
    return options, files
end

local function main()
    local args = {...}
    
    if #args == 0 then
        printHelp()
        os.exit(1)
    end
    
    local options, files = parseArgs(args)
    
    if #files < 2 then
        print("Error: Input and output files required")
        printHelp()
        os.exit(1)
    end
    
    local inputFile = files[1]
    local outputFile = files[2]
    
    if options.verbose then
        print("MoonVex Obfuscator V1.0")
        print("Input: " .. inputFile)
        print("Output: " .. outputFile)
        print("Options:")
        for k, v in pairs(options) do
            print("  " .. k .. ": " .. tostring(v))
        end
        print("")
    end
    
    local success, err = pcall(function()
        MoonVex.obfuscateFile(inputFile, outputFile, options)
    end)
    
    if success then
        print("✓ Successfully obfuscated: " .. outputFile)
    else
        print("✗ Error: " .. tostring(err))
        os.exit(1)
    end
end

main()
