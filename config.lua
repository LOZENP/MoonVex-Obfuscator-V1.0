-- MoonVex Configuration Module
-- config.lua

local config = {}

config.watermark = "([[MoonVex Obfuscator V1.0]]):gsub('.',function()end);" -- This is WaterMark This will be on top of the Obfuscted Code

config.default = {
    -- Watermark settings
    watermark = true,
    
    -- Encryption layers
    encryptionLayers = 5,
    
    -- Vararg settings
    varargMin = 50,
    varargMax = 130,
    
    -- Constant array
    dummyConstantsMin = 3000,
    dummyConstantsMax = 8000,
    
    -- Array shuffling
    shuffleMin = 30,
    shuffleMax = 50,
    
    -- Key modifications
    keyModsMin = 15,
    keyModsMax = 25,
    
    -- String splitting
    stringSplitMin = 2,
    stringSplitMax = 8,
    
    -- Complexity multiplier
    complexityMultiplier = 5,
    
    -- Output format
    removeNewlines = true,
    
    -- ProxifyLocals
    proxyCount = 10,
    
    -- Control flow obfuscation
    controlFlowObfuscation = true,
}

return config
