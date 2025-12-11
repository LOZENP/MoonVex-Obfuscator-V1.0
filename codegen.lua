-- MoonVex Code Generator
-- codegen.lua
-- Converts AST back to Lua code

local Ast = require("ast")
local AstKind = Ast.AstKind

local CodeGenerator = {}

local function escapeString(str)
    return str:gsub("\\", "\\\\")
              :gsub('"', '\\"')
              :gsub("\n", "\\n")
              :gsub("\r", "\\r")
              :gsub("\t", "\\t")
end

local function generateExpression(node)
    if not node then return "" end
    
    if node.kind == AstKind.NilExpression then
        return "nil"
        
    elseif node.kind == AstKind.BooleanExpression then
        return tostring(node.value)
        
    elseif node.kind == AstKind.NumberExpression then
        return tostring(node.value)
        
    elseif node.kind == AstKind.StringExpression then
        return '"' .. escapeString(node.value) .. '"'
        
    elseif node.kind == AstKind.VarargExpression then
        return "..."
        
    elseif node.kind == AstKind.VariableExpression then
        local name = node.scope:getVariableName(node.id)
        return name or ("_VAR" .. node.id)
        
    elseif node.kind == AstKind.IndexExpression then
        local base = generateExpression(node.base)
        local index = generateExpression(node.index)
        if node.index.kind == AstKind.StringExpression then
            return base .. "." .. node.index.value
        else
            return base .. "[" .. index .. "]"
        end
        
    elseif node.kind == AstKind.FunctionCallExpression then
        local base = generateExpression(node.base)
        local args = {}
        for i, arg in ipairs(node.args) do
            table.insert(args, generateExpression(arg))
        end
        return base .. "(" .. table.concat(args, ",") .. ")"
        
    elseif node.kind == AstKind.TableConstructorExpression then
        local entries = {}
        for i, entry in ipairs(node.entries) do
            if entry.kind == AstKind.TableEntry then
                table.insert(entries, generateExpression(entry.value))
            elseif entry.kind == AstKind.KeyedTableEntry then
                local key = generateExpression(entry.key)
                local value = generateExpression(entry.value)
                if entry.key.kind == AstKind.StringExpression then
                    table.insert(entries, "[" .. key .. "]=" .. value)
                else
                    table.insert(entries, "[" .. key .. "]=" .. value)
                end
            end
        end
        return "{" .. table.concat(entries, ",") .. "}"
        
    elseif node.kind == AstKind.FunctionLiteralExpression then
        local args = {}
        for i, arg in ipairs(node.args) do
            table.insert(args, generateExpression(arg))
        end
        local body = generateBlock(node.body)
        return "function(" .. table.concat(args, ",") .. ")" .. body .. "end"
        
    -- Binary operations
    elseif node.kind == AstKind.AddExpression then
        return "(" .. generateExpression(node.lhs) .. "+" .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.SubExpression then
        return "(" .. generateExpression(node.lhs) .. "-" .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.MulExpression then
        return "(" .. generateExpression(node.lhs) .. "*" .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.DivExpression then
        return "(" .. generateExpression(node.lhs) .. "/" .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.ModExpression then
        return "(" .. generateExpression(node.lhs) .. "%" .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.PowExpression then
        return "(" .. generateExpression(node.lhs) .. "^" .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.StrCatExpression then
        return "(" .. generateExpression(node.lhs) .. ".." .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.EqExpression then
        return "(" .. generateExpression(node.lhs) .. "==" .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.NeExpression then
        return "(" .. generateExpression(node.lhs) .. "~=" .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.LtExpression then
        return "(" .. generateExpression(node.lhs) .. "<" .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.GtExpression then
        return "(" .. generateExpression(node.lhs) .. ">" .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.LeExpression then
        return "(" .. generateExpression(node.lhs) .. "<=" .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.GeExpression then
        return "(" .. generateExpression(node.lhs) .. ">=" .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.AndExpression then
        return "(" .. generateExpression(node.lhs) .. " and " .. generateExpression(node.rhs) .. ")"
    elseif node.kind == AstKind.OrExpression then
        return "(" .. generateExpression(node.lhs) .. " or " .. generateExpression(node.rhs) .. ")"
        
    -- Unary operations
    elseif node.kind == AstKind.NotExpression then
        return "(not " .. generateExpression(node.operand) .. ")"
    elseif node.kind == AstKind.NegateExpression then
        return "(-" .. generateExpression(node.operand) .. ")"
    elseif node.kind == AstKind.LenExpression then
        return "(#" .. generateExpression(node.operand) .. ")"
    end
    
    return ""
end

local function generateAssignmentTarget(node)
    if node.kind == AstKind.AssignmentVariable then
        local name = node.scope:getVariableName(node.id)
        return name or ("_VAR" .. node.id)
    elseif node.kind == AstKind.AssignmentIndexing then
        local base = generateExpression(node.base)
        local index = generateExpression(node.index)
        if node.index.kind == AstKind.StringExpression then
            return base .. "." .. node.index.value
        else
            return base .. "[" .. index .. "]"
        end
    end
    return ""
end

local function generateStatement(node)
    if not node then return "" end
    
    if node.kind == AstKind.LocalVariableDeclaration then
        local names = {}
        for i, id in ipairs(node.ids) do
            local name = node.scope:getVariableName(id)
            table.insert(names, name or ("_VAR" .. id))
        end
        
        local values = {}
        for i, expr in ipairs(node.expressions) do
            table.insert(values, generateExpression(expr))
        end
        
        local result = "local " .. table.concat(names, ",")
        if #values > 0 then
            result = result .. "=" .. table.concat(values, ",")
        end
        return result
        
    elseif node.kind == AstKind.AssignmentStatement then
        local targets = {}
        for i, target in ipairs(node.lhs) do
            table.insert(targets, generateAssignmentTarget(target))
        end
        
        local values = {}
        for i, expr in ipairs(node.rhs) do
            table.insert(values, generateExpression(expr))
        end
        
        return table.concat(targets, ",") .. "=" .. table.concat(values, ",")
        
    elseif node.kind == AstKind.FunctionCallStatement then
        return generateExpression(Ast.FunctionCallExpression(node.base, node.args))
        
    elseif node.kind == AstKind.ReturnStatement then
        local values = {}
        for i, expr in ipairs(node.expressions) do
            table.insert(values, generateExpression(expr))
        end
        return "return " .. table.concat(values, ",")
        
    elseif node.kind == AstKind.BreakStatement then
        return "break"
        
    elseif node.kind == AstKind.IfStatement then
        local result = "if " .. generateExpression(node.condition) .. " then " .. generateBlock(node.body)
        
        for i, elseIf in ipairs(node.elseIfs) do
            result = result .. "elseif " .. generateExpression(elseIf.condition) .. " then " .. generateBlock(elseIf.body)
        end
        
        if node.elseBlock then
            result = result .. "else " .. generateBlock(node.elseBlock)
        end
        
        return result .. "end"
        
    elseif node.kind == AstKind.WhileStatement then
        return "while " .. generateExpression(node.condition) .. " do " .. generateBlock(node.body) .. "end"
        
    elseif node.kind == AstKind.RepeatStatement then
        return "repeat " .. generateBlock(node.body) .. "until " .. generateExpression(node.condition)
        
    elseif node.kind == AstKind.ForStatement then
        local varName = node.scope:getVariableName(node.id)
        local start = generateExpression(node.start)
        local stop = generateExpression(node.stop)
        local step = node.step and ("," .. generateExpression(node.step)) or ""
        return "for " .. varName .. "=" .. start .. "," .. stop .. step .. " do " .. generateBlock(node.body) .. "end"
        
    elseif node.kind == AstKind.ForInStatement then
        local names = {}
        for i, id in ipairs(node.ids) do
            table.insert(names, node.scope:getVariableName(id))
        end
        
        local exprs = {}
        for i, expr in ipairs(node.expressions) do
            table.insert(exprs, generateExpression(expr))
        end
        
        return "for " .. table.concat(names, ",") .. " in " .. table.concat(exprs, ",") .. " do " .. generateBlock(node.body) .. "end"
        
    elseif node.kind == AstKind.DoStatement then
        return "do " .. generateBlock(node.body) .. "end"
        
    elseif node.kind == AstKind.LocalFunctionDeclaration then
        local name = node.scope:getVariableName(node.id)
        local args = {}
        for i, arg in ipairs(node.args) do
            table.insert(args, generateExpression(arg))
        end
        return "local function " .. name .. "(" .. table.concat(args, ",") .. ")" .. generateBlock(node.body) .. "end"
        
    elseif node.kind == AstKind.FunctionDeclaration then
        local name = node.scope:getVariableName(node.id)
        local args = {}
        for i, arg in ipairs(node.args) do
            table.insert(args, generateExpression(arg))
        end
        return "function " .. name .. "(" .. table.concat(args, ",") .. ")" .. generateBlock(node.body) .. "end"
    end
    
    return ""
end

function generateBlock(block)
    local statements = {}
    for i, stmt in ipairs(block.statements) do
        local code = generateStatement(stmt)
        if code ~= "" then
            table.insert(statements, code)
        end
    end
    return table.concat(statements, " ")
end

function CodeGenerator.generate(ast)
    return generateBlock(ast.body)
end

return CodeGenerator
