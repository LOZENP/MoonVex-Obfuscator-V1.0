-- MoonVex Parser Module
-- parser.lua
-- Parses Lua code into AST

local Ast = require("ast")
local Scope = require("scope")

local Parser = {}
Parser.__index = Parser

function Parser:new()
    local parser = setmetatable({}, Parser)
    parser.tokens = {}
    parser.pos = 1
    return parser
end

-- Tokenizer
local function tokenize(code)
    local tokens = {}
    local i = 1
    local len = #code
    
    while i <= len do
        local char = code:sub(i, i)
        
        -- Skip whitespace
        if char:match("%s") then
            i = i + 1
            
        -- Comments
        elseif char == "-" and code:sub(i+1, i+1) == "-" then
            if code:sub(i+2, i+3) == "[[" then
                -- Multi-line comment
                local endPos = code:find("]]", i+4, true)
                if endPos then
                    i = endPos + 2
                else
                    break
                end
            else
                -- Single line comment
                local endPos = code:find("\n", i) or len + 1
                i = endPos
            end
            
        -- Strings
        elseif char == '"' or char == "'" then
            local quote = char
            local str = ""
            i = i + 1
            while i <= len do
                char = code:sub(i, i)
                if char == "\\" then
                    i = i + 1
                    char = code:sub(i, i)
                    if char == "n" then str = str .. "\n"
                    elseif char == "t" then str = str .. "\t"
                    elseif char == "r" then str = str .. "\r"
                    else str = str .. char end
                    i = i + 1
                elseif char == quote then
                    i = i + 1
                    break
                else
                    str = str .. char
                    i = i + 1
                end
            end
            table.insert(tokens, {type = "string", value = str})
            
        -- Numbers
        elseif char:match("%d") then
            local num = ""
            while i <= len and code:sub(i, i):match("[%d%.]") do
                num = num .. code:sub(i, i)
                i = i + 1
            end
            table.insert(tokens, {type = "number", value = tonumber(num)})
            
        -- Identifiers and keywords
        elseif char:match("[%a_]") then
            local ident = ""
            while i <= len and code:sub(i, i):match("[%w_]") do
                ident = ident .. code:sub(i, i)
                i = i + 1
            end
            
            -- Check if keyword
            local keywords = {
                "and", "break", "do", "else", "elseif", "end", "false",
                "for", "function", "if", "in", "local", "nil", "not",
                "or", "repeat", "return", "then", "true", "until", "while"
            }
            local isKeyword = false
            for _, kw in ipairs(keywords) do
                if ident == kw then
                    isKeyword = true
                    break
                end
            end
            
            if isKeyword then
                table.insert(tokens, {type = "keyword", value = ident})
            else
                table.insert(tokens, {type = "identifier", value = ident})
            end
            
        -- Operators and symbols
        else
            local ops = {
                ["=="] = true, ["~="] = true, ["<="] = true, [">="] = true,
                [".."] = true,
            }
            local twoChar = code:sub(i, i+1)
            if ops[twoChar] then
                table.insert(tokens, {type = "operator", value = twoChar})
                i = i + 2
            else
                table.insert(tokens, {type = "symbol", value = char})
                i = i + 1
            end
        end
    end
    
    return tokens
end

function Parser:parse(code)
    self.tokens = tokenize(code)
    self.pos = 1
    
    local globalScope = Scope:newGlobal()
    local block = self:parseBlock(globalScope, false)
    
    return {
        body = block,
        scope = globalScope
    }
end

function Parser:current()
    return self.tokens[self.pos]
end

function Parser:peek()
    return self.tokens[self.pos + 1]
end

function Parser:consume()
    local token = self.tokens[self.pos]
    self.pos = self.pos + 1
    return token
end

function Parser:expect(tokenType, value)
    local token = self:current()
    if not token or token.type ~= tokenType or (value and token.value ~= value) then
        error("Expected " .. tokenType .. " " .. (value or "") .. " but got " .. tostring(token and token.value))
    end
    return self:consume()
end

function Parser:parseBlock(scope, isFunctionBlock)
    local statements = {}
    
    while self:current() do
        local token = self:current()
        
        -- Stop at block-ending keywords
        if token.type == "keyword" and (token.value == "end" or token.value == "else" or 
           token.value == "elseif" or token.value == "until") then
            break
        end
        
        local stmt = self:parseStatement(scope)
        if stmt then
            table.insert(statements, stmt)
        end
    end
    
    local block = Ast.Block(statements, scope)
    block.isFunctionBlock = isFunctionBlock or false
    return block
end

function Parser:parseStatement(scope)
    local token = self:current()
    
    if not token then return nil end
    
    if token.type == "keyword" then
        if token.value == "local" then
            self:consume()
            if self:current() and self:current().type == "keyword" and self:current().value == "function" then
                return self:parseLocalFunctionDeclaration(scope)
            else
                return self:parseLocalVariableDeclaration(scope)
            end
        elseif token.value == "function" then
            return self:parseFunctionDeclaration(scope)
        elseif token.value == "return" then
            return self:parseReturnStatement(scope)
        elseif token.value == "if" then
            return self:parseIfStatement(scope)
        elseif token.value == "while" then
            return self:parseWhileStatement(scope)
        elseif token.value == "repeat" then
            return self:parseRepeatStatement(scope)
        elseif token.value == "for" then
            return self:parseForStatement(scope)
        elseif token.value == "do" then
            return self:parseDoStatement(scope)
        elseif token.value == "break" then
            self:consume()
            return Ast.BreakStatement()
        end
    end
    
    -- Try assignment or function call
    return self:parseAssignmentOrCall(scope)
end

function Parser:parseLocalVariableDeclaration(scope)
    local ids = {}
    local names = {}
    
    -- Parse variable names
    repeat
        local name = self:expect("identifier").value
        table.insert(names, name)
        local id = scope:addVariable(name)
        table.insert(ids, id)
        
        if self:current() and self:current().value == "," then
            self:consume()
        else
            break
        end
    until false
    
    -- Parse initializers
    local expressions = {}
    if self:current() and self:current().value == "=" then
        self:consume()
        repeat
            table.insert(expressions, self:parseExpression(scope))
            if self:current() and self:current().value == "," then
                self:consume()
            else
                break
            end
        until false
    end
    
    return Ast.LocalVariableDeclaration(scope, ids, expressions)
end

function Parser:parseExpression(scope, minPrec)
    minPrec = minPrec or 0
    local expr = self:parsePrimaryExpression(scope)
    
    while true do
        local token = self:current()
        if not token then break end
        
        local op = token.value
        local prec = self:getOperatorPrecedence(op)
        
        if prec < minPrec then break end
        
        self:consume()
        local rhs = self:parseExpression(scope, prec + 1)
        
        -- Create binary expression
        if op == "+" then expr = Ast.AddExpression(expr, rhs)
        elseif op == "-" then expr = Ast.SubExpression(expr, rhs)
        elseif op == "*" then expr = Ast.MulExpression(expr, rhs)
        elseif op == "/" then expr = Ast.DivExpression(expr, rhs)
        elseif op == "%" then expr = Ast.ModExpression(expr, rhs)
        elseif op == "^" then expr = Ast.PowExpression(expr, rhs)
        elseif op == ".." then expr = Ast.StrCatExpression(expr, rhs)
        elseif op == "==" then expr = Ast.EqExpression(expr, rhs)
        elseif op == "~=" then expr = Ast.NeExpression(expr, rhs)
        elseif op == "<" then expr = Ast.LtExpression(expr, rhs)
        elseif op == ">" then expr = Ast.GtExpression(expr, rhs)
        elseif op == "<=" then expr = Ast.LeExpression(expr, rhs)
        elseif op == ">=" then expr = Ast.GeExpression(expr, rhs)
        elseif op == "and" then expr = Ast.AndExpression(expr, rhs)
        elseif op == "or" then expr = Ast.OrExpression(expr, rhs)
        end
    end
    
    return expr
end

function Parser:parsePrimaryExpression(scope)
    local token = self:current()
    
    if not token then
        error("Unexpected end of input")
    end
    
    -- Literals
    if token.type == "number" then
        self:consume()
        return Ast.NumberExpression(token.value)
    elseif token.type == "string" then
        self:consume()
        return Ast.StringExpression(token.value)
    elseif token.type == "keyword" then
        if token.value == "nil" then
            self:consume()
            return Ast.NilExpression()
        elseif token.value == "true" then
            self:consume()
            return Ast.BooleanExpression(true)
        elseif token.value == "false" then
            self:consume()
            return Ast.BooleanExpression(false)
        elseif token.value == "function" then
            return self:parseFunctionLiteral(scope)
        end
    elseif token.type == "identifier" then
        local name = token.value
        self:consume()
        local varScope, varId = scope:resolve(name)
        if not varScope then
            -- Assume global
            varScope = scope:getGlobalScope()
            varId = varScope:addVariable(name)
        end
        local expr = Ast.VariableExpression(varScope, varId)
        
        -- Handle indexing and function calls
        while self:current() do
            if self:current().value == "." then
                self:consume()
                local index = self:expect("identifier").value
                expr = Ast.IndexExpression(expr, Ast.StringExpression(index))
            elseif self:current().value == "[" then
                self:consume()
                local index = self:parseExpression(scope)
                self:expect("symbol", "]")
                expr = Ast.IndexExpression(expr, index)
            elseif self:current().value == "(" then
                self:consume()
                local args = {}
                if self:current().value ~= ")" then
                    repeat
                        table.insert(args, self:parseExpression(scope))
                        if self:current().value == "," then
                            self:consume()
                        else
                            break
                        end
                    until false
                end
                self:expect("symbol", ")")
                expr = Ast.FunctionCallExpression(expr, args)
            else
                break
            end
        end
        
        return expr
    end
    
    error("Unexpected token: " .. tostring(token.value))
end

function Parser:parseFunctionLiteral(scope)
    self:expect("keyword", "function")
    self:expect("symbol", "(")
    
    local funcScope = Scope:new(scope)
    local args = {}
    
    if self:current().value ~= ")" then
        repeat
            local argName = self:expect("identifier").value
            local argId = funcScope:addVariable(argName)
            table.insert(args, Ast.VariableExpression(funcScope, argId))
            
            if self:current().value == "," then
                self:consume()
            else
                break
            end
        until false
    end
    
    self:expect("symbol", ")")
    local body = self:parseBlock(funcScope, true)
    self:expect("keyword", "end")
    
    return Ast.FunctionLiteralExpression(args, body)
end

function Parser:parseReturnStatement(scope)
    self:expect("keyword", "return")
    local expressions = {}
    
    if self:current() and self:current().type ~= "keyword" then
        repeat
            table.insert(expressions, self:parseExpression(scope))
            if self:current() and self:current().value == "," then
                self:consume()
            else
                break
            end
        until false
    end
    
    return Ast.ReturnStatement(expressions)
end

function Parser:parseIfStatement(scope)
    self:expect("keyword", "if")
    local condition = self:parseExpression(scope)
    self:expect("keyword", "then")
    local ifScope = Scope:new(scope)
    local body = self:parseBlock(ifScope, false)
    
    local elseIfs = {}
    local elseBlock = nil
    
    while self:current() and self:current().value == "elseif" do
        self:consume()
        local elseIfCondition = self:parseExpression(scope)
        self:expect("keyword", "then")
        local elseIfScope = Scope:new(scope)
        local elseIfBody = self:parseBlock(elseIfScope, false)
        table.insert(elseIfs, {condition = elseIfCondition, body = elseIfBody})
    end
    
    if self:current() and self:current().value == "else" then
        self:consume()
        local elseScope = Scope:new(scope)
        elseBlock = self:parseBlock(elseScope, false)
    end
    
    self:expect("keyword", "end")
    
    return Ast.IfStatement(condition, body, elseIfs, elseBlock)
end

function Parser:parseWhileStatement(scope)
    self:expect("keyword", "while")
    local condition = self:parseExpression(scope)
    self:expect("keyword", "do")
    local whileScope = Scope:new(scope)
    local body = self:parseBlock(whileScope, false)
    self:expect("keyword", "end")
    
    return Ast.WhileStatement(condition, body)
end

function Parser:parseRepeatStatement(scope)
    self:expect("keyword", "repeat")
    local repeatScope = Scope:new(scope)
    local body = self:parseBlock(repeatScope, false)
    self:expect("keyword", "until")
    local condition = self:parseExpression(scope)
    
    return Ast.RepeatStatement(body, condition)
end

function Parser:parseForStatement(scope)
    self:expect("keyword", "for")
    local varName = self:expect("identifier").value
    
    if self:current().value == "=" then
        -- Numeric for
        self:consume()
        local forScope = Scope:new(scope)
        local varId = forScope:addVariable(varName)
        local start = self:parseExpression(scope)
        self:expect("symbol", ",")
        local stop = self:parseExpression(scope)
        local step = nil
        if self:current().value == "," then
            self:consume()
            step = self:parseExpression(scope)
        end
        self:expect("keyword", "do")
        local body = self:parseBlock(forScope, false)
        self:expect("keyword", "end")
        return Ast.ForStatement(forScope, varId, start, stop, step, body)
    else
        -- Generic for
        local forScope = Scope:new(scope)
        local ids = {forScope:addVariable(varName)}
        
        while self:current().value == "," do
            self:consume()
            local name = self:expect("identifier").value
            table.insert(ids, forScope:addVariable(name))
        end
        
        self:expect("keyword", "in")
        local expressions = {}
        repeat
            table.insert(expressions, self:parseExpression(scope))
            if self:current().value == "," then
                self:consume()
            else
                break
            end
        until false
        
        self:expect("keyword", "do")
        local body = self:parseBlock(forScope, false)
        self:expect("keyword", "end")
        return Ast.ForInStatement(forScope, ids, expressions, body)
    end
end

function Parser:parseDoStatement(scope)
    self:expect("keyword", "do")
    local doScope = Scope:new(scope)
    local body = self:parseBlock(doScope, false)
    self:expect("keyword", "end")
    return Ast.DoStatement(body)
end

function Parser:parseAssignmentOrCall(scope)
    local expr = self:parseExpression(scope)
    
    -- Check if it's an assignment
    if self:current() and self:current().value == "=" then
        self:consume()
        local lhs = {expr}
        
        -- TODO: Convert expression to assignment target
        
        local rhs = {}
        repeat
            table.insert(rhs, self:parseExpression(scope))
            if self:current() and self:current().value == "," then
                self:consume()
            else
                break
            end
        until false
        
        return Ast.AssignmentStatement(lhs, rhs)
    end
    
    -- Otherwise it's a function call statement
    if expr.kind == Ast.AstKind.FunctionCallExpression then
        return Ast.FunctionCallStatement(expr.base, expr.args)
    end
    
    return nil
end

function Parser:parseLocalFunctionDeclaration(scope)
    self:expect("keyword", "function")
    local name = self:expect("identifier").value
    local id = scope:addVariable(name)
    
    self:expect("symbol", "(")
    local funcScope = Scope:new(scope)
    local args = {}
    
    if self:current().value ~= ")" then
        repeat
            local argName = self:expect("identifier").value
            local argId = funcScope:addVariable(argName)
            table.insert(args, Ast.VariableExpression(funcScope, argId))
            
            if self:current().value == "," then
                self:consume()
            else
                break
            end
        until false
    end
    
    self:expect("symbol", ")")
    local body = self:parseBlock(funcScope, true)
    self:expect("keyword", "end")
    
    return Ast.LocalFunctionDeclaration(scope, id, args, body)
end

function Parser:parseFunctionDeclaration(scope)
    self:expect("keyword", "function")
    local name = self:expect("identifier").value
    local varScope, varId = scope:resolve(name)
    
    if not varScope then
        varScope = scope:getGlobalScope()
        varId = varScope:addVariable(name)
    end
    
    self:expect("symbol", "(")
    local funcScope = Scope:new(scope)
    local args = {}
    
    if self:current().value ~= ")" then
        repeat
            local argName = self:expect("identifier").value
            local argId = funcScope:addVariable(argName)
            table.insert(args, Ast.VariableExpression(funcScope, argId))
            
            if self:current().value == "," then
                self:consume()
            else
                break
            end
        until false
    end
    
    self:expect("symbol", ")")
    local body = self:parseBlock(funcScope, true)
    self:expect("keyword", "end")
    
    return Ast.FunctionDeclaration(varScope, varId, args, body, {})
end

function Parser:getOperatorPrecedence(op)
    local precedence = {
        ["or"] = 1,
        ["and"] = 2,
        ["<"] = 3, [">"] = 3, ["<="] = 3, [">="] = 3, ["~="] = 3, ["=="] = 3,
        [".."] = 4,
        ["+"] = 5, ["-"] = 5,
        ["*"] = 6, ["/"] = 6, ["%"] = 6,
        ["^"] = 7,
    }
    return precedence[op] or 0
end

return Parser
