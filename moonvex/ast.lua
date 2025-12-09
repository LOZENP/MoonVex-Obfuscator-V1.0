-- MoonVex AST Module
-- ast.lua
-- Abstract Syntax Tree implementation for Lua

local Ast = {}
Ast.__index = Ast

-- AST Node Kinds
Ast.AstKind = {
    -- Statements
    Block = "Block",
    LocalVariableDeclaration = "LocalVariableDeclaration",
    AssignmentStatement = "AssignmentStatement",
    FunctionDeclaration = "FunctionDeclaration",
    LocalFunctionDeclaration = "LocalFunctionDeclaration",
    ReturnStatement = "ReturnStatement",
    BreakStatement = "BreakStatement",
    ContinueStatement = "ContinueStatement",
    IfStatement = "IfStatement",
    WhileStatement = "WhileStatement",
    RepeatStatement = "RepeatStatement",
    ForStatement = "ForStatement",
    ForInStatement = "ForInStatement",
    DoStatement = "DoStatement",
    FunctionCallStatement = "FunctionCallStatement",
    
    -- Expressions
    NilExpression = "NilExpression",
    BooleanExpression = "BooleanExpression",
    NumberExpression = "NumberExpression",
    StringExpression = "StringExpression",
    VarargExpression = "VarargExpression",
    FunctionLiteralExpression = "FunctionLiteralExpression",
    TableConstructorExpression = "TableConstructorExpression",
    VariableExpression = "VariableExpression",
    IndexExpression = "IndexExpression",
    FunctionCallExpression = "FunctionCallExpression",
    
    -- Binary Operations
    AddExpression = "AddExpression",
    SubExpression = "SubExpression",
    MulExpression = "MulExpression",
    DivExpression = "DivExpression",
    ModExpression = "ModExpression",
    PowExpression = "PowExpression",
    StrCatExpression = "StrCatExpression",
    EqExpression = "EqExpression",
    NeExpression = "NeExpression",
    LtExpression = "LtExpression",
    GtExpression = "GtExpression",
    LeExpression = "LeExpression",
    GeExpression = "GeExpression",
    AndExpression = "AndExpression",
    OrExpression = "OrExpression",
    
    -- Unary Operations
    NotExpression = "NotExpression",
    NegateExpression = "NegateExpression",
    LenExpression = "LenExpression",
    
    -- Assignment Targets
    AssignmentVariable = "AssignmentVariable",
    AssignmentIndexing = "AssignmentIndexing",
    
    -- Table Entries
    TableEntry = "TableEntry",
    KeyedTableEntry = "KeyedTableEntry",
}

-- Base Node Constructor
local function createNode(kind)
    return {
        kind = kind,
        __index = function(t, k)
            error("Attempted to access undefined field '" .. k .. "' in " .. kind)
        end
    }
end

-- Block (List of statements)
function Ast.Block(statements, scope)
    local node = createNode(Ast.AstKind.Block)
    node.statements = statements or {}
    node.scope = scope
    node.isFunctionBlock = false
    return node
end

-- Local Variable Declaration
function Ast.LocalVariableDeclaration(scope, ids, expressions)
    local node = createNode(Ast.AstKind.LocalVariableDeclaration)
    node.scope = scope
    node.ids = ids or {}
    node.expressions = expressions or {}
    return node
end

-- Assignment Statement
function Ast.AssignmentStatement(lhs, rhs)
    local node = createNode(Ast.AstKind.AssignmentStatement)
    node.lhs = lhs or {}
    node.rhs = rhs or {}
    return node
end

-- Assignment Variable
function Ast.AssignmentVariable(scope, id)
    local node = createNode(Ast.AstKind.AssignmentVariable)
    node.scope = scope
    node.id = id
    return node
end

-- Assignment Indexing
function Ast.AssignmentIndexing(base, index)
    local node = createNode(Ast.AstKind.AssignmentIndexing)
    node.base = base
    node.index = index
    return node
end

-- Function Declaration
function Ast.FunctionDeclaration(scope, id, args, body, indices)
    local node = createNode(Ast.AstKind.FunctionDeclaration)
    node.scope = scope
    node.id = id
    node.args = args or {}
    node.body = body
    node.indices = indices or {}
    return node
end

-- Local Function Declaration
function Ast.LocalFunctionDeclaration(scope, id, args, body)
    local node = createNode(Ast.AstKind.LocalFunctionDeclaration)
    node.scope = scope
    node.id = id
    node.args = args or {}
    node.body = body
    return node
end

-- Return Statement
function Ast.ReturnStatement(expressions)
    local node = createNode(Ast.AstKind.ReturnStatement)
    node.expressions = expressions or {}
    return node
end

-- Break Statement
function Ast.BreakStatement()
    return createNode(Ast.AstKind.BreakStatement)
end

-- If Statement
function Ast.IfStatement(condition, body, elseIfs, elseBlock)
    local node = createNode(Ast.AstKind.IfStatement)
    node.condition = condition
    node.body = body
    node.elseIfs = elseIfs or {}
    node.elseBlock = elseBlock
    return node
end

-- While Statement
function Ast.WhileStatement(condition, body)
    local node = createNode(Ast.AstKind.WhileStatement)
    node.condition = condition
    node.body = body
    return node
end

-- Repeat Statement
function Ast.RepeatStatement(body, condition)
    local node = createNode(Ast.AstKind.RepeatStatement)
    node.body = body
    node.condition = condition
    return node
end

-- For Statement (numeric)
function Ast.ForStatement(scope, id, start, stop, step, body)
    local node = createNode(Ast.AstKind.ForStatement)
    node.scope = scope
    node.id = id
    node.start = start
    node.stop = stop
    node.step = step
    node.body = body
    return node
end

-- For In Statement (generic)
function Ast.ForInStatement(scope, ids, expressions, body)
    local node = createNode(Ast.AstKind.ForInStatement)
    node.scope = scope
    node.ids = ids or {}
    node.expressions = expressions or {}
    node.body = body
    return node
end

-- Do Statement
function Ast.DoStatement(body)
    local node = createNode(Ast.AstKind.DoStatement)
    node.body = body
    return node
end

-- Function Call Statement
function Ast.FunctionCallStatement(base, args)
    local node = createNode(Ast.AstKind.FunctionCallStatement)
    node.base = base
    node.args = args or {}
    return node
end

-- Literal Expressions
function Ast.NilExpression()
    return createNode(Ast.AstKind.NilExpression)
end

function Ast.BooleanExpression(value)
    local node = createNode(Ast.AstKind.BooleanExpression)
    node.value = value
    return node
end

function Ast.NumberExpression(value)
    local node = createNode(Ast.AstKind.NumberExpression)
    node.value = value
    return node
end

function Ast.StringExpression(value)
    local node = createNode(Ast.AstKind.StringExpression)
    node.value = value
    return node
end

function Ast.VarargExpression()
    return createNode(Ast.AstKind.VarargExpression)
end

-- Function Literal Expression
function Ast.FunctionLiteralExpression(args, body)
    local node = createNode(Ast.AstKind.FunctionLiteralExpression)
    node.args = args or {}
    node.body = body
    node.body.isFunctionBlock = true
    return node
end

-- Table Constructor Expression
function Ast.TableConstructorExpression(entries)
    local node = createNode(Ast.AstKind.TableConstructorExpression)
    node.entries = entries or {}
    return node
end

-- Table Entry
function Ast.TableEntry(value)
    local node = createNode(Ast.AstKind.TableEntry)
    node.value = value
    return node
end

-- Keyed Table Entry
function Ast.KeyedTableEntry(key, value)
    local node = createNode(Ast.AstKind.KeyedTableEntry)
    node.key = key
    node.value = value
    return node
end

-- Variable Expression
function Ast.VariableExpression(scope, id)
    local node = createNode(Ast.AstKind.VariableExpression)
    node.scope = scope
    node.id = id
    return node
end

-- Index Expression
function Ast.IndexExpression(base, index)
    local node = createNode(Ast.AstKind.IndexExpression)
    node.base = base
    node.index = index
    return node
end

-- Function Call Expression
function Ast.FunctionCallExpression(base, args)
    local node = createNode(Ast.AstKind.FunctionCallExpression)
    node.base = base
    node.args = args or {}
    return node
end

-- Binary Operations
function Ast.AddExpression(lhs, rhs, isConstant)
    local node = createNode(Ast.AstKind.AddExpression)
    node.lhs = lhs
    node.rhs = rhs
    node.isConstant = isConstant or false
    return node
end

function Ast.SubExpression(lhs, rhs, isConstant)
    local node = createNode(Ast.AstKind.SubExpression)
    node.lhs = lhs
    node.rhs = rhs
    node.isConstant = isConstant or false
    return node
end

function Ast.MulExpression(lhs, rhs, isConstant)
    local node = createNode(Ast.AstKind.MulExpression)
    node.lhs = lhs
    node.rhs = rhs
    node.isConstant = isConstant or false
    return node
end

function Ast.DivExpression(lhs, rhs, isConstant)
    local node = createNode(Ast.AstKind.DivExpression)
    node.lhs = lhs
    node.rhs = rhs
    node.isConstant = isConstant or false
    return node
end

function Ast.ModExpression(lhs, rhs, isConstant)
    local node = createNode(Ast.AstKind.ModExpression)
    node.lhs = lhs
    node.rhs = rhs
    node.isConstant = isConstant or false
    return node
end

function Ast.PowExpression(lhs, rhs, isConstant)
    local node = createNode(Ast.AstKind.PowExpression)
    node.lhs = lhs
    node.rhs = rhs
    node.isConstant = isConstant or false
    return node
end

function Ast.StrCatExpression(lhs, rhs)
    local node = createNode(Ast.AstKind.StrCatExpression)
    node.lhs = lhs
    node.rhs = rhs
    return node
end

-- Comparison Operations
function Ast.EqExpression(lhs, rhs)
    local node = createNode(Ast.AstKind.EqExpression)
    node.lhs = lhs
    node.rhs = rhs
    return node
end

function Ast.NeExpression(lhs, rhs)
    local node = createNode(Ast.AstKind.NeExpression)
    node.lhs = lhs
    node.rhs = rhs
    return node
end

function Ast.LtExpression(lhs, rhs)
    local node = createNode(Ast.AstKind.LtExpression)
    node.lhs = lhs
    node.rhs = rhs
    return node
end

function Ast.GtExpression(lhs, rhs)
    local node = createNode(Ast.AstKind.GtExpression)
    node.lhs = lhs
    node.rhs = rhs
    return node
end

function Ast.LeExpression(lhs, rhs)
    local node = createNode(Ast.AstKind.LeExpression)
    node.lhs = lhs
    node.rhs = rhs
    return node
end

function Ast.GeExpression(lhs, rhs)
    local node = createNode(Ast.AstKind.GeExpression)
    node.lhs = lhs
    node.rhs = rhs
    return node
end

-- Logical Operations
function Ast.AndExpression(lhs, rhs)
    local node = createNode(Ast.AstKind.AndExpression)
    node.lhs = lhs
    node.rhs = rhs
    return node
end

function Ast.OrExpression(lhs, rhs)
    local node = createNode(Ast.AstKind.OrExpression)
    node.lhs = lhs
    node.rhs = rhs
    return node
end

-- Unary Operations
function Ast.NotExpression(operand)
    local node = createNode(Ast.AstKind.NotExpression)
    node.operand = operand
    return node
end

function Ast.NegateExpression(operand)
    local node = createNode(Ast.AstKind.NegateExpression)
    node.operand = operand
    return node
end

function Ast.LenExpression(operand)
    local node = createNode(Ast.AstKind.LenExpression)
    node.operand = operand
    return node
end

return Ast
