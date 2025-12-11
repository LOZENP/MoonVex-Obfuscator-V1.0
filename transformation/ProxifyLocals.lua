-- MoonVex ProxifyLocals Module
-- ProxifyLocals.lua
-- Wraps local variables in proxy objects using metatables

local Ast = require("ast")
local Scope = require("scope")
local visitast = require("visitast")
local util = require("util")
local AstKind = Ast.AstKind

local ProxifyLocals = {}

function ProxifyLocals:new(settings)
    local obj = {
        Threshold = settings.Threshold or 1.0,
        LiteralType = settings.LiteralType or "number"
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- Available metatable operations
local MetatableExpressions = {
    {constructor = Ast.AddExpression, key = "__add"},
    {constructor = Ast.SubExpression, key = "__sub"},
    {constructor = Ast.MulExpression, key = "__mul"},
    {constructor = Ast.DivExpression, key = "__div"},
    {constructor = Ast.PowExpression, key = "__pow"},
    {constructor = Ast.StrCatExpression, key = "__concat"},
}

-- Generate random literal based on type
local function generateRandomLiteral(literalType)
    if literalType == "number" then
        return Ast.NumberExpression(math.random(1, 100))
    elseif literalType == "string" then
        local chars = "abcdefghijklmnopqrstuvwxyz"
        local len = math.random(3, 8)
        local str = ""
        for i = 1, len do
            local idx = math.random(1, #chars)
            str = str .. chars:sub(idx, idx)
        end
        return Ast.StringExpression(str)
    elseif literalType == "boolean" then
        return Ast.BooleanExpression(math.random() > 0.5)
    else
        -- Any type
        local types = {"number", "string", "boolean"}
        return generateRandomLiteral(types[math.random(#types)])
    end
end

-- Generate metatable info for a local variable
local function generateLocalMetatableInfo(namegen)
    local usedOps = {}
    local info = {}
    
    -- Pick 3 random unique operations
    for i, purpose in ipairs({"setValue", "getValue", "index"}) do
        local rop
        repeat
            rop = MetatableExpressions[math.random(#MetatableExpressions)]
        until not usedOps[rop]
        usedOps[rop] = true
        info[purpose] = rop
    end
    
    -- Generate random value name
    info.valueName = namegen()
    
    return info
end

-- Create proxy assignment expression
function ProxifyLocals:CreateAssignmentExpression(info, expr, parentScope)
    local metatableVals = {}
    
    -- __setValue function
    local setValueScope = Scope:new(parentScope)
    local selfId = setValueScope:addVariable()
    local argId = setValueScope:addVariable()
    
    local setValueBody = Ast.Block({
        Ast.AssignmentStatement(
            {Ast.AssignmentIndexing(
                Ast.VariableExpression(setValueScope, selfId),
                Ast.StringExpression(info.valueName)
            )},
            {Ast.VariableExpression(setValueScope, argId)}
        )
    }, setValueScope)
    setValueBody.isFunctionBlock = true
    
    local setValueFunc = Ast.FunctionLiteralExpression(
        {
            Ast.VariableExpression(setValueScope, selfId),
            Ast.VariableExpression(setValueScope, argId)
        },
        setValueBody
    )
    
    table.insert(metatableVals, Ast.KeyedTableEntry(
        Ast.StringExpression(info.setValue.key),
        setValueFunc
    ))
    
    -- __getValue function
    local getValueScope = Scope:new(parentScope)
    local getSelfId = getValueScope:addVariable()
    local getArgId = getValueScope:addVariable()
    
    -- Use rawget if __index is used
    local getValueIdxExpr
    if info.getValue.key == "__index" or info.setValue.key == "__index" then
        local rawgetScope, rawgetId = getValueScope:resolveGlobal("rawget")
        getValueScope:addReferenceToHigherScope(rawgetScope, rawgetId)
        getValueIdxExpr = Ast.FunctionCallExpression(
            Ast.VariableExpression(rawgetScope, rawgetId),
            {
                Ast.VariableExpression(getValueScope, getSelfId),
                Ast.StringExpression(info.valueName)
            }
        )
    else
        getValueIdxExpr = Ast.IndexExpression(
            Ast.VariableExpression(getValueScope, getSelfId),
            Ast.StringExpression(info.valueName)
        )
    end
    
    local getValueBody = Ast.Block({
        Ast.ReturnStatement({getValueIdxExpr})
    }, getValueScope)
    getValueBody.isFunctionBlock = true
    
    local getValueFunc = Ast.FunctionLiteralExpression(
        {
            Ast.VariableExpression(getValueScope, getSelfId),
            Ast.VariableExpression(getValueScope, getArgId)
        },
        getValueBody
    )
    
    table.insert(metatableVals, Ast.KeyedTableEntry(
        Ast.StringExpression(info.getValue.key),
        getValueFunc
    ))
    
    -- Return setmetatable call
    parentScope:addReferenceToHigherScope(self.setMetatableScope, self.setMetatableId)
    
    return Ast.FunctionCallExpression(
        Ast.VariableExpression(self.setMetatableScope, self.setMetatableId),
        {
            Ast.TableConstructorExpression({
                Ast.KeyedTableEntry(Ast.StringExpression(info.valueName), expr)
            }),
            Ast.TableConstructorExpression(metatableVals)
        }
    )
end

function ProxifyLocals:apply(ast, namegen)
    local localMetatableInfos = {}
    local self2 = self
    
    -- Name generator function
    if not namegen then
        local counter = 0
        namegen = function()
            counter = counter + 1
            return "_P" .. counter .. "_"
        end
    end
    
    -- Get or create metatable info for a variable
    local function getLocalMetatableInfo(scope, id)
        if scope.isGlobal then return nil end
        
        localMetatableInfos[scope] = localMetatableInfos[scope] or {}
        
        if localMetatableInfos[scope][id] then
            if localMetatableInfos[scope][id].locked then
                return nil
            end
            return localMetatableInfos[scope][id]
        end
        
        local info = generateLocalMetatableInfo(namegen)
        localMetatableInfos[scope][id] = info
        return info
    end
    
    -- Disable proxying for a variable
    local function disableMetatableInfo(scope, id)
        if scope.isGlobal then return end
        localMetatableInfos[scope] = localMetatableInfos[scope] or {}
        localMetatableInfos[scope][id] = {locked = true}
    end
    
    -- Create setmetatable variable
    self.setMetatableScope = ast.body.scope
    self.setMetatableId = ast.body.scope:addVariable()
    
    -- Create empty function for assignment statements
    self.emptyFunctionScope = ast.body.scope
    self.emptyFunctionId = ast.body.scope:addVariable()
    self.emptyFunctionUsed = false
    
    -- Add empty function declaration
    local emptyFuncScope = Scope:new(ast.body.scope)
    local emptyFuncBody = Ast.Block({}, emptyFuncScope)
    emptyFuncBody.isFunctionBlock = true
    
    table.insert(ast.body.statements, 1, Ast.LocalVariableDeclaration(
        self.emptyFunctionScope,
        {self.emptyFunctionId},
        {Ast.FunctionLiteralExpression({}, emptyFuncBody)}
    ))
    
    -- Visit AST
    visitast(ast, function(node, data)
        -- Lock for loop variables
        if node.kind == AstKind.ForStatement then
            disableMetatableInfo(node.scope, node.id)
        end
        
        if node.kind == AstKind.ForInStatement then
            for i, id in ipairs(node.ids) do
                disableMetatableInfo(node.scope, id)
            end
        end
        
        -- Lock function arguments
        if node.kind == AstKind.FunctionDeclaration or 
           node.kind == AstKind.LocalFunctionDeclaration or 
           node.kind == AstKind.FunctionLiteralExpression then
            for i, expr in ipairs(node.args) do
                if expr.kind == AstKind.VariableExpression then
                    disableMetatableInfo(expr.scope, expr.id)
                end
            end
        end
        
        -- Transform assignment statements
        if node.kind == AstKind.AssignmentStatement then
            if #node.lhs == 1 and node.lhs[1].kind == AstKind.AssignmentVariable then
                local variable = node.lhs[1]
                local info = getLocalMetatableInfo(variable.scope, variable.id)
                
                if info and math.random() <= self2.Threshold then
                    local args = util.shallowCopy(node.rhs)
                    local vexp = Ast.VariableExpression(variable.scope, variable.id)
                    vexp.__ignoreProxifyLocals = true
                    args[1] = info.setValue.constructor(vexp, args[1])
                    
                    self2.emptyFunctionUsed = true
                    data.scope:addReferenceToHigherScope(self2.emptyFunctionScope, self2.emptyFunctionId)
                    
                    return Ast.FunctionCallStatement(
                        Ast.VariableExpression(self2.emptyFunctionScope, self2.emptyFunctionId),
                        args
                    )
                end
            end
        end
    end, function(node, data)
        -- Local variable declaration
        if node.kind == AstKind.LocalVariableDeclaration then
            for i, id in ipairs(node.ids) do
                local expr = node.expressions[i] or Ast.NilExpression()
                local info = getLocalMetatableInfo(node.scope, id)
                
                if info and math.random() <= self2.Threshold then
                    local newExpr = self2:CreateAssignmentExpression(info, expr, node.scope)
                    node.expressions[i] = newExpr
                end
            end
        end
        
        -- Variable expression
        if node.kind == AstKind.VariableExpression and not node.__ignoreProxifyLocals then
            local info = getLocalMetatableInfo(node.scope, node.id)
            
            if info and math.random() <= self2.Threshold then
                local literal = generateRandomLiteral(self2.LiteralType)
                return info.getValue.constructor(node, literal), true
            end
        end
        
        -- Assignment variable
        if node.kind == AstKind.AssignmentVariable then
            local info = getLocalMetatableInfo(node.scope, node.id)
            
            if info and math.random() <= self2.Threshold then
                return Ast.AssignmentIndexing(
                    node,
                    Ast.StringExpression(info.valueName)
                ), true
            end
        end
        
        -- Local function declaration
        if node.kind == AstKind.LocalFunctionDeclaration then
            local info = getLocalMetatableInfo(node.scope, node.id)
            
            if info and math.random() <= self2.Threshold then
                local funcLiteral = Ast.FunctionLiteralExpression(node.args, node.body)
                local newExpr = self2:CreateAssignmentExpression(info, funcLiteral, node.scope)
                return Ast.LocalVariableDeclaration(node.scope, {node.id}, {newExpr}), true
            end
        end
        
        -- Function declaration
        if node.kind == AstKind.FunctionDeclaration then
            local info = getLocalMetatableInfo(node.scope, node.id)
            
            if info then
                table.insert(node.indices, 1, info.valueName)
            end
        end
    end)
    
    -- Add setmetatable variable declaration
    local setmetatableScope, setmetatableId = ast.body.scope:resolveGlobal("setmetatable")
    ast.body.scope:addReferenceToHigherScope(setmetatableScope, setmetatableId)
    
    table.insert(ast.body.statements, 1, Ast.LocalVariableDeclaration(
        self.setMetatableScope,
        {self.setMetatableId},
        {Ast.VariableExpression(setmetatableScope, setmetatableId)}
    ))
    
    return ast
end

return ProxifyLocals
