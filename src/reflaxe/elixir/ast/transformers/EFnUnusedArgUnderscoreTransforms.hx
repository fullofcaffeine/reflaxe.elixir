package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * EFnUnusedArgUnderscoreTransforms
 *
 * WHAT
 * - Underscore anonymous function argument binders that are not referenced in
 *   the function body. Applies to single-arg and two-arg (reduce) functions.
 *
 * WHY
 * - Prevents Elixir warnings about unused variables in anonymous functions
 *   emitted for Enum.each/map/reduce patterns. Keeps output idiomatic.
 *
 * HOW
 * - For each EFn clause, detect simple PVar/PAlias arg binders; if a binder is
 *   not used per VariableUsageCollector.usedInFunctionScope(body, name), rename
 *   it to `_name` (if not already underscored). Body rewrite is not needed as
 *   unused binders have no references.
 *
 * EXAMPLES
 * Before:
 *   Enum.each(xs, fn elem -> IO.puts("done") end)
 * After:
 *   Enum.each(xs, fn _elem -> IO.puts("done") end)
 */
class EFnUnusedArgUnderscoreTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var newArgs:Array<EPattern> = [];
                        var i = 0;
                        inline function isUsed(name:String):Bool {
                            if (name == null) return false;
                            var underscored = '_' + name;
                            return VariableUsageCollector.usedInFunctionScope(cl.body, name)
                                || VariableUsageCollector.usedInFunctionScope(cl.body, underscored)
                                || erawUsesName(cl.body, name)
                                || erawUsesName(cl.body, underscored)
                                || containsVarName(cl.body, name)
                                || containsVarName(cl.body, underscored);
                        }
                        inline function normalizedBinder(name:String):String {
                            if (name == null) return name;
                            var needsUnderscore = !isUsed(name) && (name.length == 0 || name.charAt(0) != '_');
                            return needsUnderscore ? ('_' + name) : name;
                        }
                        for (a in cl.args) {
                            switch (a) {
                                case PVar(name):
                                    var nn = normalizedBinder(name);
                                    newArgs.push(PVar(nn));
                                case PAlias(name, pat):
                                    var nn = normalizedBinder(name);
                                    newArgs.push(PAlias(nn, pat));
                                default:
                                    newArgs.push(a);
                            }
                            i++;
                        }
                        newClauses.push({args: newArgs, guard: cl.guard, body: cl.body});
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    // ERaw token-bound scan for name usage
    static function erawUsesName(body: ElixirAST, name: String): Bool {
        var found = false;
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= '0'.code && ch <= '9'.code) || (ch >= 'A'.code && ch <= 'Z'.code) || (ch >= 'a'.code && ch <= 'z'.code) || c == "_" || c == ".";
        }
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case ERaw(code):
                    if (code != null && name != null && name.length > 0 && name.charAt(0) != '_') {
                        var start = 0;
                        while (!found) {
                            var i = code.indexOf(name, start);
                            if (i == -1) break;
                            var before = i > 0 ? code.substr(i - 1, 1) : null;
                            var afterIdx = i + name.length;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            if (!isIdentChar(before) && !isIdentChar(after)) { found = true; break; }
                            start = i + name.length;
                        }
                    }
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(statements): for (s in statements) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses): walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); for (a in as) walk(a);
                case ERemoteCall(targetExpr,_,argsList): walk(targetExpr); for (argNode in argsList) walk(argNode);
                case EField(obj,_): walk(obj);
                case EAccess(objectExpr,key): walk(objectExpr); walk(key);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base,fs): walk(base); for (f in fs) walk(f.value);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(body);
        return found;
    }

    static function containsVarName(body: ElixirAST, name: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case EVar(v) if (v == name):
                    found = true;
                case EPin(inner):
                    walk(inner);
                case EParen(e):
                    walk(e);
                case EBinary(_, l, r):
                    walk(l); walk(r);
                case EMatch(_, rhs):
                    walk(rhs);
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(statements): for (s in statements) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses): walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); for (a in as) walk(a);
                case ERemoteCall(targetExpr,_,argsList): walk(targetExpr); for (argNode in argsList) walk(argNode);
                case EField(obj,_): walk(obj);
                case EAccess(obj2,key): walk(obj2); walk(key);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base,fs): walk(base); for (f in fs) walk(f.value);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(body);
        return found;
    }
}

#end
