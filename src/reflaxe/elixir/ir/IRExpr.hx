package reflaxe.elixir.ir;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST; // reuse literal/value nodes when practical

enum IRPattern {
    PVar(symbol: Symbol);
    PLiteral(value: ElixirAST);
    PTuple(elements: Array<IRPattern>);
    PList(elements: Array<IRPattern>);
    PCons(head: IRPattern, tail: IRPattern);
    PMap(pairs: Array<{ key: ElixirAST, value: IRPattern }>);
    PStruct(module: String, fields: Array<{ key: String, value: IRPattern }>);
    PPin(inner: IRPattern);
    PWildcard;
    PAlias(symbol: Symbol, inner: IRPattern);
}

enum IRExpr {
    IRModule(name: String, defs: Array<IRExpr>);
    IRDef(name: String, params: Array<Symbol>, body: IRExpr);
    IRCase(expr: IRExpr, clauses: Array<{ pattern: IRPattern, guard: Null<IRExpr>, body: IRExpr }>);
    IRCond(clauses: Array<{ condition: IRExpr, body: IRExpr }>);
    IRMatch(pattern: IRPattern, expr: IRExpr);
    IRVar(symbol: Symbol);
    IRCall(target: Null<IRExpr>, name: String, args: Array<IRExpr>);
    IRRemoteCall(module: IRExpr, name: String, args: Array<IRExpr>);
    IRBinary(op: String, left: IRExpr, right: IRExpr);
    IRUnary(op: String, expr: IRExpr);
    IRBlock(exprs: Array<IRExpr>);
    IRLiteral(value: ElixirAST);
}

#end
