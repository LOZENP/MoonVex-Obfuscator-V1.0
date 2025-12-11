#!/usr/bin/env lua
-- MoonVex Obfuscator V2.0 CLI
-- cli.lua

local MoonVex = require("main")

local function printHelp()
    print([[
╔═══════════════════════════════════════════════════════╗
║       MoonVex Obfuscator V2.0 - By Rodgie           ║
╚═══════════════════════════════════════════════════════╝

Usage: lua cli.lua [options] <input> <output>

Options:
  -h, --help              Show this help message
  -w, --no-watermark      Disable watermark
  -v, --verbose           Verbose output
  
Transformation Options:
  --no-numbers            Disable Numbers to Expressions
  --no-strings            Disable String Splitting
  --no-proxify            Disable Proxify Locals
  
  --string-mode <mode>    String split mode: strcat, table, custom (default: custom)
  --string-min <n>        Min string chunk size (default: 3)
  --string-max <n>        Max string chunk size (default: 7)

Examples:
  lua cli.lua script.lua output.lua
  lua cli.lua -w script.lua output.lua
  lua cli.lua --no-proxify script.lua output.lua
  lua cli.lua --string-mode strcat script.lua output.lua

Termux Usage:
  # Install Lua if not installed
  pkg install lua
  
  # Run obfuscator
  lua cli.lua input.lua output.lua
  
  # Test output
  lua output.lua
]])
end

local function parseArgs(args)
    local options = {
        NumbersToExpressions = {
            enabled = true,
            Threshold = 0.8,
            InternalThreshold = 0.3
        },
        SplitStrings = {
            enabled = true,
            Threshold = 0.9,
            MinLength = 3,
            MaxLength = 7,
            ConcatenationType = "custom",
            CustomFunctionType = "global"
        },
        ProxifyLocals = {
            enabled = true,
            Threshold = 0.7,
            LiteralType = "number"
        },
        watermark = true,
        verbose = false
    }
    
    local files = {}
    local i = 1
    
    while i <= #args do
        local arg = args[i]
        
        if arg == "-h" or arg == "--help" then
            printHelp()
            os.exit(0)
            
        elseif arg == "-w" or arg == "--no-watermark" then
            options.watermark = false
            
        elseif arg == "-v" or arg == "--verbose" then
            options.verbose = true
            
        elseif arg == "--no-numbers" then
            options.NumbersToExpressions.enabled = false
            
        elseif arg == "--no-strings" then
            options.SplitStrings.enabled = false
            
        elseif arg == "--no-proxify" then
            options.ProxifyLocals.enabled = false
            
        elseif arg == "--string-mode" then
            i = i + 1
            options.SplitStrings.ConcatenationType = args[i]
            
        elseif arg == "--string-min" then
            i = i + 1
            options.SplitStrings.MinLength = tonumber(args[i])
            
        elseif arg == "--string-max" then
            i = i + 1
            options.SplitStrings.MaxLength = tonumber(args[i])
            
        else
            table.insert(files, arg)
        end
        
        i = i + 1
    end
    
    return options, files
end

local function main(args)
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
        print("╔═══════════════════════════════════════════════════════╗")
        print("║       MoonVex Obfuscator V2.0 - By Rodgie           ║")
        print("╚═══════════════════════════════════════════════════════╝")
        print()
        print("Configuration:")
        print("  Input:  " .. inputFile)
        print("  Output: " .. outputFile)
        print()
        print("Transformations:")
        print("  Numbers to Expressions: " .. (options.NumbersToExpressions.enabled and "ON" or "OFF"))
        print("  Split Strings:          " .. (options.SplitStrings.enabled and "ON" or "OFF"))
        print("  Proxify Locals:         " .. (options.ProxifyLocals.enabled and "ON" or "OFF"))
        print()
    end
    
    local success, err = pcall(function()
        MoonVex.obfuscateFile(inputFile, outputFile, options)
    end)
    
    if success then
        print("\n✓ Successfully obfuscated!")
        print("  Output saved to: " .. outputFile)
    else
        print("\n✗ Error during obfuscation:")
        print("  " .. tostring(err))
        os.exit(1)
    end
end

-- Get command line arguments
local args = {}
for i = 1, #arg do
    args[i] = arg[i]
end

main(args)
