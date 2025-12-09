-- MoonVex Split Strings Module
-- SplitStrings.lua
-- Splits string literals into concatenated chunks

local Ast = require("ast")
local Scope = require("scope")
local visitast = require("visitast")
local util = require("util")
local AstKind = Ast.AstKind

local SplitStrings = {}

function SplitStrings:new(settings)
    local obj = {
        Threshold = settings.Threshold or 1,
        MinLength = settings.MinLength or 3,
        MaxLength = settings.MaxLength or 7,
        ConcatenationType = settings.ConcatenationType or "custom",
        CustomFunctionType = settings.CustomFunctionType or "global",
        CustomLocalFunctionsCount = settings.CustomLocalFunctionsCount or 2
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function SplitStrings:variant()
    return math.random(1, 2)
end

function SplitStrings:generateTableConcatNode(chunks, data)
    local chunkNodes = {}
    for i, chunk in ipairs(chunks) do
        table.insert(chunkNodes, Ast.TableEntry(Ast.StringExpression(chunk)))
    end
    local tb = Ast.TableConstructorExpression(chunkNodes)
    data.scope:addReferenceToHigherScope(data.tableConcatScope, data.tableConcatId)
    return Ast.FunctionCallExpression(
        Ast.VariableExpression(data.tableConcatScope, data.tableConcatId),
        {tb}
    )
end

function SplitStrings:generateStrCatNode(chunks)
    local generatedNode = nil
    for i, chunk in ipairs(chunks) do
        if generatedNode then
            generatedNode = Ast.StrCatExpression(generatedNode, Ast.StringExpression(chunk))
        else
            generatedNode = Ast.StringExpression(chunk)
        end
    end
    return generatedNode
end

function SplitStrings:generateCustomNodeArgs(chunks, variant)
    local shuffled = {}
    local shuffledIndices = {}
    
    for i = 1, #chunks do
        shuffledIndices[i] = i
    end
    util.shuffle(shuffledIndices)
    
    for i, v in ipairs(shuffledIndices) do
        shuffled[v] = chunks[i]
    end
    
    if variant == 1 then
        -- Custom variant 1: {indices..., {strings...}}
        local args = {}
        local tbNodes = {}
        
        for i, v in ipairs(shuffledIndices) do
            table.insert(args, Ast.TableEntry(Ast.NumberExpression(v)))
        end
        
        for i, chunk in ipairs(shuffled) do
            table.insert(tbNodes, Ast.TableEntry(Ast.StringExpression(chunk)))
        end
        
        local tb = Ast.TableConstructorExpression(tbNodes)
        table.insert(args, Ast.TableEntry(tb))
        
        return {Ast.TableConstructorExpression(args)}
    else
        -- Custom variant 2: {indices..., strings...}
        local args = {}
        
        for i, v in ipairs(shuffledIndices) do
            table.insert(args, Ast.TableEntry(Ast.NumberExpression(v)))
        end
        
        for i, chunk in ipairs(shuffled) do
            table.insert(args, Ast.TableEntry(Ast.StringExpression(chunk)))
        end
        
        return {Ast.TableConstructorExpression(args)}
    end
end

function SplitStrings:generateCustomFunctionLiteral(parentScope, variant)
    local funcScope = Scope:new(parentScope)
    local tableArg = funcScope:addVariable()
    
    if variant == 1 then
        -- function(table) local stringTable, str = table[#table], ""; for i=1,#stringTable do str = str .. stringTable[table[i]] end return str end
        local stringTableId = funcScope:addVariable()
        local strId = funcScope:addVariable()
        local iId = funcScope:addVariable()
        
        local loopScope = Scope:new(funcScope)
        loopScope:addVariable() -- loop variable reuses iId
        
        local body = Ast.Block({
            -- local stringTable, str = table[#table], ""
            Ast.LocalVariableDeclaration(
                funcScope,
                {stringTableId, strId},
                {
                    Ast.IndexExpression(
                        Ast.VariableExpression(funcScope, tableArg),
                        Ast.LenExpression(Ast.VariableExpression(funcScope, tableArg))
                    ),
                    Ast.StringExpression("")
                }
            ),
            -- for i=1,#stringTable do
            Ast.ForStatement(
                loopScope,
                iId,
                Ast.NumberExpression(1),
                Ast.LenExpression(Ast.VariableExpression(funcScope, stringTableId)),
                nil,
                Ast.Block({
                    -- str = str .. stringTable[table[i]]
                    Ast.AssignmentStatement(
                        {Ast.AssignmentVariable(funcScope, strId)},
                        {
                            Ast.StrCatExpression(
                                Ast.VariableExpression(funcScope, strId),
                                Ast.IndexExpression(
                                    Ast.VariableExpression(funcScope, stringTableId),
                                    Ast.IndexExpression(
                                        Ast.VariableExpression(funcScope, tableArg),
                                        Ast.VariableExpression(loopScope, iId)
                                    )
                                )
                            )
                        }
                    )
                }, loopScope)
            ),
            -- return str
            Ast.ReturnStatement({Ast.VariableExpression(funcScope, strId)})
        }, funcScope)
        body.isFunctionBlock = true
        
        return Ast.FunctionLiteralExpression(
            {Ast.VariableExpression(funcScope, tableArg)},
            body
        )
    else
        -- function(tb) local str = ""; for i=1, #tb/2 do str = str .. tb[#tb/2 + tb[i]] end return str end
        local strId = funcScope:addVariable()
        local iId = funcScope:addVariable()
        
        local loopScope = Scope:new(funcScope)
        loopScope:addVariable() -- loop variable
        
        local body = Ast.Block({
            -- local str = ""
            Ast.LocalVariableDeclaration(funcScope, {strId}, {Ast.StringExpression("")}),
            -- for i=1, #tb/2 do
            Ast.ForStatement(
                loopScope,
                iId,
                Ast.NumberExpression(1),
                Ast.DivExpression(
                    Ast.LenExpression(Ast.VariableExpression(funcScope, tableArg)),
                    Ast.NumberExpression(2)
                ),
                nil,
                Ast.Block({
                    -- str = str .. tb[#tb/2 + tb[i]]
                    Ast.AssignmentStatement(
                        {Ast.AssignmentVariable(funcScope, strId)},
                        {
                            Ast.StrCatExpression(
                                Ast.VariableExpression(funcScope, strId),
                                Ast.IndexExpression(
                                    Ast.VariableExpression(funcScope, tableArg),
                                    Ast.AddExpression(
                                        Ast.DivExpression(
                                            Ast.LenExpression(Ast.VariableExpression(funcScope, tableArg)),
                                            Ast.NumberExpression(2)
                                        ),
                                        Ast.IndexExpression(
                                            Ast.VariableExpression(funcScope, tableArg),
                                            Ast.VariableExpression(loopScope, iId)
                                        )
                                    )
                                )
                            )
                        }
                    )
                }, loopScope)
            ),
            -- return str
            Ast.ReturnStatement({Ast.VariableExpression(funcScope, strId)})
        }, funcScope)
        body.isFunctionBlock = true
        
        return Ast.FunctionLiteralExpression(
            {Ast.VariableExpression(funcScope, tableArg)},
            body
        )
    end
end

function SplitStrings:apply(ast)
    local data = {}
    local self2 = self
    
    -- Setup based on concatenation type
    if self.ConcatenationType == "table" then
        local scope = ast.body.scope
        local id = scope:addVariable()
        data.tableConcatScope = scope
        data.tableConcatId = id
    elseif self.ConcatenationType == "custom" then
        data.customFunctionType = self.CustomFunctionType
        if data.customFunctionType == "global" then
            local scope = ast.body.scope
            local id = scope:addVariable()
            data.customFuncScope = scope
            data.customFuncId = id
            data.customFunctionVariant = self:variant()
        end
    end
    
    -- Visit AST
    visitast(ast, function(node, data)
        -- Create local custom functions for each function block
        if self2.ConcatenationType == "custom" and data.customFunctionType == "local" and 
           node.kind == AstKind.Block and node.isFunctionBlock then
            data.functionData.localFunctions = {}
            for i = 1, self2.CustomLocalFunctionsCount do
                local scope = data.scope
                local id = scope:addVariable()
                local variant = self2:variant()
                table.insert(data.functionData.localFunctions, {
                    scope = scope,
                    id = id,
                    variant = variant,
                    used = false
                })
            end
        end
    end, function(node, data)
        -- Add local function declarations
        if self2.ConcatenationType == "custom" and data.customFunctionType == "local" and 
           node.kind == AstKind.Block and node.isFunctionBlock then
            for i, func in ipairs(data.functionData.localFunctions) do
                if func.used then
                    local literal = self2:generateCustomFunctionLiteral(func.scope, func.variant)
                    table.insert(node.statements, 1, 
                        Ast.LocalVariableDeclaration(func.scope, {func.id}, {literal})
                    )
                end
            end
        end
        
        -- Process string expressions
        if node.kind == AstKind.StringExpression then
            local str = node.value
            local chunks = {}
            local i = 1
            
            -- Split string
            while i <= #str do
                local len = math.random(self2.MinLength, self2.MaxLength)
                table.insert(chunks, str:sub(i, i + len - 1))
                i = i + len
            end
            
            if #chunks > 1 and math.random() < self2.Threshold then
                if self2.ConcatenationType == "strcat" then
                    return self2:generateStrCatNode(chunks), true
                elseif self2.ConcatenationType == "table" then
                    return self2:generateTableConcatNode(chunks, data), true
                elseif self2.ConcatenationType == "custom" then
                    if self2.CustomFunctionType == "global" then
                        local args = self2:generateCustomNodeArgs(chunks, data.customFunctionVariant)
                        data.scope:addReferenceToHigherScope(data.customFuncScope, data.customFuncId)
                        return Ast.FunctionCallExpression(
                            Ast.VariableExpression(data.customFuncScope, data.customFuncId),
                            args
                        ), true
                    elseif self2.CustomFunctionType == "local" then
                        local lfuncs = data.functionData.localFunctions
                        local idx = math.random(1, #lfuncs)
                        local func = lfuncs[idx]
                        local args = self2:generateCustomNodeArgs(chunks, func.variant)
                        func.used = true
                        data.scope:addReferenceToHigherScope(func.scope, func.id)
                        return Ast.FunctionCallExpression(
                            Ast.VariableExpression(func.scope, func.id),
                            args
                        ), true
                    elseif self2.CustomFunctionType == "inline" then
                        local variant = self2:variant()
                        local args = self2:generateCustomNodeArgs(chunks, variant)
                        local literal = self2:generateCustomFunctionLiteral(data.scope, variant)
                        return Ast.FunctionCallExpression(literal, args), true
                    end
                end
            end
        end
    end, data)
    
    -- Add global declarations
    if self.ConcatenationType == "table" then
        local globalScope = ast.body.scope:getGlobalScope()
        local tableScope, tableId = globalScope:resolve("table")
        ast.body.scope:addReferenceToHigherScope(globalScope, tableId)
        table.insert(ast.body.statements, 1, 
            Ast.LocalVariableDeclaration(
                data.tableConcatScope,
                {data.tableConcatId},
                {
                    Ast.IndexExpression(
                        Ast.VariableExpression(tableScope, tableId),
                        Ast.StringExpression("concat")
                    )
                }
            )
        )
    elseif self.ConcatenationType == "custom" and self.CustomFunctionType == "global" then
        local literal = self:generateCustomFunctionLiteral(ast.body.scope, data.customFunctionVariant)
        table.insert(ast.body.statements, 1,
            Ast.LocalVariableDeclaration(data.customFuncScope, {data.customFuncId}, {literal})
        )
    end
    
    return ast
end

return SplitStrings
