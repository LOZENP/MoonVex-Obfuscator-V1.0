-- MoonVex Name Compiler Module
-- namecompiler.lua
-- Compiles multiple base names together to make them longer

local namegen = require("namegen")

local compiler = {}

-- Configuration
compiler.config = {
    partsPerName = 3,        -- How many base names to combine
    useDelimiter = false,    -- Use _ between parts or not
    forceLength = 150         -- Minimum total length
}

-- Simply call namegen multiple times and concat them
function compiler.compileLong()
    local parts = {}
    local totalLength = 0
    
    -- Keep generating until we reach desired length
    while totalLength < compiler.config.forceLength do
        local part = namegen.generate()
        table.insert(parts, part)
        totalLength = totalLength + #part
    end
    
    if compiler.config.useDelimiter then
        return table.concat(parts, "_")
    else
        return table.concat(parts, "")  -- Just smash them together
    end
end

-- Generate multiple compiled names
function compiler.generateMultiple(count)
    local names = {}
    for i = 1, count do
        table.insert(names, compiler.compileLong())
    end
    return names
end

-- Configure settings
function compiler.configure(options)
    if options.partsPerName then compiler.config.partsPerName = options.partsPerName end
    if options.useDelimiter ~= nil then compiler.config.useDelimiter = options.useDelimiter end
    if options.forceLength then compiler.config.forceLength = options.forceLength end
end

-- Prepare namegen
function compiler.prepare()
    namegen.prepare()
end

-- Reset
function compiler.reset()
    namegen.reset()
end

return compiler
