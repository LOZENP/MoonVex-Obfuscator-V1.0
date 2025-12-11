-- MoonVex Scope Module
-- scope.lua
-- Manages variable scoping and references

local Scope = {}
Scope.__index = Scope

local globalScope = nil

-- Create a new scope
function Scope:new(parent)
    local scope = setmetatable({}, Scope)
    scope.parent = parent
    scope.variables = {}
    scope.variableCount = 0
    scope.isGlobal = false
    scope.references = {}
    scope.children = {}
    
    if parent then
        table.insert(parent.children, scope)
    end
    
    return scope
end

-- Create the global scope
function Scope:newGlobal()
    if globalScope then
        return globalScope
    end
    
    local scope = Scope:new(nil)
    scope.isGlobal = true
    globalScope = scope
    
    -- Add Lua globals
    local globals = {
        "print", "assert", "error", "warn", "type", "tostring", "tonumber",
        "pairs", "ipairs", "next", "select", "getmetatable", "setmetatable",
        "rawget", "rawset", "rawequal", "pcall", "xpcall",
        "table", "string", "math", "coroutine", "io", "os", "debug",
        "_G", "_VERSION", "require", "load", "loadstring", "dofile", "loadfile",
        "unpack", "collectgarbage", "newproxy",
        -- Roblox globals (if needed)
        "game", "workspace", "script", "wait", "spawn", "delay", "tick",
        "Instance", "Vector3", "CFrame", "Color3", "UDim2", "Enum",
        "task", "bit32"
    }
    
    for _, name in ipairs(globals) do
        scope:addVariable(name)
    end
    
    return scope
end

-- Get the global scope
function Scope:getGlobalScope()
    local current = self
    while current.parent do
        current = current.parent
    end
    return current
end

-- Add a variable to this scope
function Scope:addVariable(name)
    self.variableCount = self.variableCount + 1
    local id = self.variableCount
    self.variables[id] = {
        name = name,
        id = id,
        references = 0
    }
    return id
end

-- Rename a variable
function Scope:renameVariable(id, newName)
    if self.variables[id] then
        self.variables[id].name = newName
    end
end

-- Get variable name
function Scope:getVariableName(id)
    if self.variables[id] then
        return self.variables[id].name
    end
    return nil
end

-- Resolve a variable name to scope and id
function Scope:resolve(name)
    -- Check current scope
    for id, var in pairs(self.variables) do
        if var.name == name then
            return self, id
        end
    end
    
    -- Check parent scopes
    if self.parent then
        return self.parent:resolve(name)
    end
    
    -- Not found
    return nil, nil
end

-- Resolve a global variable
function Scope:resolveGlobal(name)
    local globalScope = self:getGlobalScope()
    local scope, id = globalScope:resolve(name)
    return scope, id
end

-- Add a reference to a higher scope variable
function Scope:addReferenceToHigherScope(targetScope, targetId)
    if targetScope.variables[targetId] then
        targetScope.variables[targetId].references = targetScope.variables[targetId].references + 1
        table.insert(self.references, {scope = targetScope, id = targetId})
    end
end

-- Set parent scope
function Scope:setParent(parent)
    self.parent = parent
    if parent then
        table.insert(parent.children, self)
    end
end

-- Check if variable exists in this scope
function Scope:hasVariable(id)
    return self.variables[id] ~= nil
end

-- Get all variables in scope
function Scope:getAllVariables()
    return self.variables
end

-- Get variable count
function Scope:getVariableCount()
    return self.variableCount
end

return Scope
