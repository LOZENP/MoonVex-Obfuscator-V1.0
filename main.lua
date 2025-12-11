-- MoonVex Obfuscator V2.0
-- Main Entry Point
-- main.lua

local Parser = require("parser")
local Scope = require("scope")
local config = require("config")

-- Transformation modules
local NumbersToExpressions = require("transformations.NumbersToExpressions")
local SplitStrings = require("transformations.SplitStrings")
local ProxifyLocals = require("transformations.ProxifyLocals")

-- Code generator (simplified)
local CodeGenerator = require("codegen")

local MoonVex = {}

function MoonVex.obfuscate(code, options)
    options = options or {}
    
    -- Merge with defaults
    for k, v in pairs(config.default) do
        if options[k] == nil then
            options[k] = v
        end
    end
    
    math.randomseed(os.time())
    
    print("[MoonVex V2] Starting obfuscation...")
    
    -- Step 1: Parse code into AST
    print("[1/5] Parsing code...")
    local parser = Parser:new()
    local ast = parser:parse(code)
    print("  ✓ Parsed successfully")
    
    -- Step 2: Numbers to Expressions
    if options.NumbersToExpressions and options.NumbersToExpressions.enabled ~= false then
        print("[2/5] Transforming numbers to expressions...")
        local step = NumbersToExpressions:new(options.NumbersToExpressions)
        step:apply(ast)
        print("  ✓ Numbers transformed")
    else
        print("[2/5] Skipping Numbers to Expressions")
    end
    
    -- Step 3: Split Strings
    if options.SplitStrings and options.SplitStrings.enabled ~= false then
        print("[3/5] Splitting strings...")
        local step = SplitStrings:new(options.SplitStrings)
        step:apply(ast)
        print("  ✓ Strings split")
    else
        print("[3/5] Skipping Split Strings")
    end
    
    -- Step 4: Proxify Locals
    if options.ProxifyLocals and options.ProxifyLocals.enabled ~= false then
        print("[4/5] Proxifying local variables...")
        local step = ProxifyLocals:new(options.ProxifyLocals)
        step:apply(ast)
        print("  ✓ Locals proxified")
    else
        print("[4/5] Skipping Proxify Locals")
    end
    
    -- Step 5: Generate code
    print("[5/5] Generating obfuscated code...")
    local obfuscated = CodeGenerator.generate(ast)
    print("  ✓ Code generated")
    
    -- Add watermark if enabled
    if options.watermark then
        obfuscated = config.watermark .. "\n" .. obfuscated
    end
    
    print("[MoonVex V2] Obfuscation complete!\n")
    
    return obfuscated
end

function MoonVex.obfuscateFile(inputPath, outputPath, options)
    print("Input: " .. inputPath)
    print("Output: " .. outputPath)
    print()
    
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
    
    print("✓ Successfully obfuscated to: " .. outputPath)
    
    return true
end

return MoonVex
