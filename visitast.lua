-- MoonVex AST Visitor Module
-- visitast.lua
-- Traverses and transforms AST nodes

local Ast = require("ast")
local AstKind = Ast.AstKind

local function visitast(node, preVisit, postVisit, data)
    data = data or {}
    
    if not node then return node end
    
    -- Track scope changes
    local oldScope = data.scope
    if node.scope then
        data.scope = node.scope
    end
    
    -- Track function data
    local oldFunctionData = data.functionData
    if node.kind == AstKind.Block and node.isFunctionBlock then
        data.functionData = {}
    end
    
    -- Pre-visit callback
    if preVisit then
        local result = preVisit(node, data)
        if result then
            node = result
        end
    end
    
    -- Visit children based on node kind
    if node.kind == AstKind.Block then
        for i, stmt in ipairs(node.statements) do
            node.statements[i] = visitast(stmt, preVisit, postVisit, data)
        end
        
    elseif node.kind == AstKind.LocalVariableDeclaration then
        for i, expr in ipairs(node.expressions) do
            node.expressions[i] = visitast(expr, preVisit, postVisit, data)
        end
        
    elseif node.kind == AstKind.AssignmentStatement then
        for i, target in ipairs(node.lhs) do
            node.lhs[i] = visitast(target, preVisit, postVisit, data)
        end
        for i, expr in ipairs(node.rhs) do
            node.rhs[i] = visitast(expr, preVisit, postVisit, data)
        end
        
    elseif node.kind == AstKind.FunctionDeclaration or node.kind == AstKind.LocalFunctionDeclaration then
        for i, arg in ipairs(node.args) do
            node.args[i] = visitast(arg, preVisit, postVisit, data)
        end
        node.body = visitast(node.body, preVisit, postVisit, data)
        
    elseif node.kind == AstKind.ReturnStatement then
        for i, expr in ipairs(node.expressions) do
            node.expressions[i] = visitast(expr, preVisit, postVisit, data)
        end
        
    elseif node.kind == AstKind.IfStatement then
        node.condition = visitast(node.condition, preVisit, postVisit, data)
        node.body = visitast(node.body, preVisit, postVisit, data)
        for i, elseIf in ipairs(node.elseIfs) do
            elseIf.condition = visitast(elseIf.condition, preVisit, postVisit, data)
            elseIf.body = visitast(elseIf.body, preVisit, postVisit, data)
        end
        if node.elseBlock then
            node.elseBlock = visitast(node.elseBlock, preVisit, postVisit, data)
        end
        
    elseif node.kind == AstKind.WhileStatement then
        node.condition = visitast(node.condition, preVisit, postVisit, data)
        node.body = visitast(node.body, preVisit, postVisit, data)
        
    elseif node.kind == AstKind.RepeatStatement then
        node.body = visitast(node.body, preVisit, postVisit, data)
        node.condition = visitast(node.condition, preVisit, postVisit, data)
        
    elseif node.kind == AstKind.ForStatement then
        node.start = visitast(node.start, preVisit, postVisit, data)
        node.stop = visitast(node.stop, preVisit, postVisit, data)
        if node.step then
            node.step = visitast(node.step, preVisit, postVisit, data)
        end
        node.body = visitast(node.body, preVisit, postVisit, data)
        
    elseif node.kind == AstKind.ForInStatement then
        for i, expr in ipairs(node.expressions) do
            node.expressions[i] = visitast(expr, preVisit, postVisit, data)
        end
        node.body = visitast(node.body, preVisit, postVisit, data)
        
    elseif node.kind == AstKind.DoStatement then
        node.body = visitast(node.body, preVisit, postVisit, data)
        
    elseif node.kind == AstKind.FunctionCallStatement then
        node.base = visitast(node.base, preVisit, postVisit, data)
        for i, arg in ipairs(node.args) do
            node.args[i] = visitast(arg, preVisit, postVisit, data)
        end
        
    elseif node.kind == AstKind.FunctionLiteralExpression then
        for i, arg in ipairs(node.args) do
            node.args[i] = visitast(arg, preVisit, postVisit, data)
        end
        node.body = visitast(node.body, preVisit, postVisit, data)
        
    elseif node.kind == AstKind.TableConstructorExpression then
        for i, entry in ipairs(node.entries) do
            node.entries[i] = visitast(entry, preVisit, postVisit, data)
        end
        
    elseif node.kind == AstKind.TableEntry then
        node.value = visitast(node.value, preVisit, postVisit, data)
        
    elseif node.kind == AstKind.KeyedTableEntry then
        node.key = visitast(node.key, preVisit, postVisit, data)
        node.value = visitast(node.value, preVisit, postVisit, data)
        
    elseif node.kind == AstKind.IndexExpression then
        node.base = visitast(node.base, preVisit, postVisit, data)
        node.index = visitast(node.index, preVisit, postVisit, data)
        
    elseif node.kind == AstKind.FunctionCallExpression then
        node.base = visitast(node.base, preVisit, postVisit, data)
        for i, arg in ipairs(node.args) do
            node.args[i] = visitast(arg, preVisit, postVisit, data)
        end
        
    elseif node.kind == AstKind.AssignmentIndexing then
        node.base = visitast(node.base, preVisit, postVisit, data)
        node.index = visitast(node.index, preVisit, postVisit, data)
        
    -- Binary operations
    elseif node.kind == AstKind.AddExpression or node.kind == AstKind.SubExpression or
           node.kind == AstKind.MulExpression or node.kind == AstKind.DivExpression or
           node.kind == AstKind.ModExpression or node.kind == AstKind.PowExpression or
           node.kind == AstKind.StrCatExpression or node.kind == AstKind.EqExpression or
           node.kind == AstKind.NeExpression or node.kind == AstKind.LtExpression or
           node.kind == AstKind.GtExpression or node.kind == AstKind.LeExpression or
           node.kind == AstKind.GeExpression or node.kind == AstKind.AndExpression or
           node.kind == AstKind.OrExpression then
        node.lhs = visitast(node.lhs, preVisit, postVisit, data)
        node.rhs = visitast(node.rhs, preVisit, postVisit, data)
        
    -- Unary operations
    elseif node.kind == AstKind.NotExpression or node.kind == AstKind.NegateExpression or
           node.kind == AstKind.LenExpression then
        node.operand = visitast(node.operand, preVisit, postVisit, data)
    end
    
    -- Post-visit callback
    if postVisit then
        local result, replace = postVisit(node, data)
        if replace then
            node = result
        end
    end
    
    -- Restore scope and function data
    data.scope = oldScope
    data.functionData = oldFunctionData
    
    return node
end

return visitast
