-- MoonVex Numbers To Expressions Module
-- NumbersToExpressions.lua
-- Converts number literals to complex mathematical expressions

local Ast = require("ast")
local visitast = require("visitast")
local util = require("util")
local AstKind = Ast.AstKind

local NumbersToExpressions = {}

function NumbersToExpressions:new(settings)
    local obj = {
        Threshold = settings.Threshold or 1,
        InternalThreshold = settings.InternalThreshold or 0.2,
        ExpressionGenerators = {}
    }
    setmetatable(obj, self)
    self.__index = self
    
    -- Initialize expression generators
    obj:initGenerators()
    
    return obj
end

function NumbersToExpressions:initGenerators()
    self.ExpressionGenerators = {
        -- Addition
        function(val, depth)
            local val2 = math.random(-2^20, 2^20)
            local diff = val - val2
            if tonumber(tostring(diff)) + tonumber(tostring(val2)) ~= val then
                return false
            end
            return Ast.AddExpression(
                self:CreateNumberExpression(val2, depth),
                self:CreateNumberExpression(diff, depth),
                false
            )
        end,
        
        -- Subtraction
        function(val, depth)
            local val2 = math.random(-2^20, 2^20)
            local diff = val + val2
            if tonumber(tostring(diff)) - tonumber(tostring(val2)) ~= val then
                return false
            end
            return Ast.SubExpression(
                self:CreateNumberExpression(diff, depth),
                self:CreateNumberExpression(val2, depth),
                false
            )
        end,
        
        -- Multiplication
        function(val, depth)
            if val == 0 then return false end
            local divisors = {}
            for i = 2, math.min(100, math.abs(val)) do
                if val % i == 0 then
                    table.insert(divisors, i)
                end
            end
            if #divisors == 0 then return false end
            local divisor = divisors[math.random(#divisors)]
            local quotient = val / divisor
            return Ast.MulExpression(
                self:CreateNumberExpression(quotient, depth),
                self:CreateNumberExpression(divisor, depth),
                false
            )
        end,
        
        -- Division
        function(val, depth)
            if val == 0 then return false end
            local multiplier = math.random(2, 20)
            local product = val * multiplier
            if product / multiplier ~= val then return false end
            return Ast.DivExpression(
                self:CreateNumberExpression(product, depth),
                self:CreateNumberExpression(multiplier, depth),
                false
            )
        end,
        
        -- Modulo (for small numbers)
        function(val, depth)
            if val < 0 or val > 100 then return false end
            local mod = math.random(val + 10, val + 100)
            return Ast.ModExpression(
                self:CreateNumberExpression(val + mod, depth),
                self:CreateNumberExpression(mod, depth),
                false
            )
        end,
        
        -- Power (for specific cases)
        function(val, depth)
            if val <= 0 or val > 1000 then return false end
            -- Try to find if val is a perfect square
            local sqrt = math.sqrt(val)
            if sqrt == math.floor(sqrt) and sqrt <= 100 then
                return Ast.PowExpression(
                    self:CreateNumberExpression(sqrt, depth),
                    Ast.NumberExpression(2),
                    false
                )
            end
            return false
        end,
    }
end

function NumbersToExpressions:CreateNumberExpression(val, depth)
    depth = depth or 0
    
    -- Stop recursion at depth limit or based on threshold
    if depth > 15 or (depth > 0 and math.random() >= self.InternalThreshold) then
        return Ast.NumberExpression(val)
    end
    
    -- Shuffle generators and try each one
    local generators = util.shuffle(util.shallowCopy(self.ExpressionGenerators))
    for i, generator in ipairs(generators) do
        local node = generator(val, depth + 1)
        if node then
            return node
        end
    end
    
    -- Fallback to literal
    return Ast.NumberExpression(val)
end

function NumbersToExpressions:apply(ast)
    local self2 = self
    
    visitast(ast, nil, function(node, data)
        if node.kind == AstKind.NumberExpression then
            if math.random() <= self2.Threshold then
                return self2:CreateNumberExpression(node.value, 0), true
            end
        end
    end)
    
    return ast
end

return NumbersToExpressions
