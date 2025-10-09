package reflaxe.elixir.ir;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.EPattern as EPat;

/**
 * IRBuilder: builds a minimal symbol overlay from ElixirAST.
 * Flag-gated with -D enable_symbol_ir. No behavior changes without integration.
 */
class Builder {
    static var symId:Int = 0;
    static var scopeId:Int = 0;

    public static function buildSymbols(ast:ElixirAST):{symbols:Array<Symbol>, scopes:Array<Scope>} {
        #if enable_symbol_ir
        var symbols:Array<Symbol> = [];
        var scopes:Array<Scope> = [];
        function newScope(kind:ScopeKind, parent:Null<Int>):Int {
            var id = ++scopeId;
            scopes.push(new Scope(id, kind, parent));
            return id;
        }
        function newSymbol(name:String, scope:Int, origin:Origin):Symbol {
            var s = new Symbol(++symId, name, scope, origin);
            symbols.push(s);
            return s;
        }
        function collectPattern(p:EPat, scope:Int):Void {
            switch (p) {
                case PVar(n): newSymbol(n, scope, Origin.PatternBinder);
                case PAlias(v, inner): newSymbol(v, scope, Origin.PatternBinder); collectPattern(inner, scope);
                case PTuple(el): for (e in el) collectPattern(e, scope);
                case PList(el): for (e in el) collectPattern(e, scope);
                case PCons(h,t): collectPattern(h, scope); collectPattern(t, scope);
                case PMap(pairs): for (kv in pairs) collectPattern(kv.value, scope);
                case PStruct(_, fields): for (f in fields) collectPattern(f.value, scope);
                case PPin(inner): collectPattern(inner, scope);
                default:
            }
        }
        function walk(node:ElixirAST, currentScope:Int):Void {
            if (node == null || node.def == null) return;
            switch (node.def) {
                case EModule(_, _, body):
                    var modScope = newScope(ScopeKind.Module, currentScope);
                    for (b in body) walk(b, modScope);
                case EDef(_, args, _, body) | EDefp(_, args, _, body):
                    var fnScope = newScope(ScopeKind.Function, currentScope);
                    for (a in args) collectPattern(a, fnScope);
                    walk(body, fnScope);
                case ECase(expr, clauses):
                    walk(expr, currentScope);
                    for (c in clauses) {
                        var clScope = newScope(ScopeKind.Case, currentScope);
                        collectPattern(c.pattern, clScope);
                        if (c.guard != null) walk(c.guard, clScope);
                        walk(c.body, clScope);
                    }
                case EIf(cond, thenB, elseB):
                    walk(cond, currentScope); walk(thenB, currentScope); if (elseB != null) walk(elseB, currentScope);
                case EBlock(sts):
                    var blk = newScope(ScopeKind.Block, currentScope);
                    for (s in sts) walk(s, blk);
                default:
                    // Generic descent
                    reflaxe.elixir.ast.ElixirASTTransformer.iterChildren(node, n -> walk(n, currentScope));
            }
        }
        var root = newScope(ScopeKind.Block, null);
        walk(ast, root);
        return { symbols: symbols, scopes: scopes };
        #else
        return { symbols: [], scopes: [] };
        #end
    }
}

#end

