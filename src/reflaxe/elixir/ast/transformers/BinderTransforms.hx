package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * BinderTransforms
 *
 * WHY: Case arms that bind a single payload variable (e.g., {:some, x}) sometimes reference
 *      a different variable name in the body (e.g., `level`). This occurs when upstream
 *      transformations preserve idiomatic body names while payload binders are generic.
 * WHAT: For case clauses with exactly one variable binder in the pattern, inject a clause-local
 *       alias at the start of the body for each used lowercased variable that is not already bound:
 *       var = binder.
 * HOW: Analyze each ECase clause: collect pattern binders and used EVar names; if exactly one
 *      binder exists, prepend alias assignments for missing variables.
 */
class BinderTransforms {
    public static function caseClauseBinderAliasInjectionPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            if (node == null || node.def == null) return node;
            return switch(node.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (clause in clauses) {
                        var binders = collectPatternBinders(clause.pattern);
                        if (binders.length == 1) {
                            var used = collectUsedLowerVars(clause.body);
                            var binder = binders[0];
                            var toAlias = used.filter(v -> v != binder);
                            if (toAlias.length > 0) {
                                var body = clause.body;
                                var assigns = [for (v in toAlias) makeAST(EMatch(PVar(v), makeAST(EVar(binder))))];
                                var newBody = switch(body.def) {
                                    case EBlock(exprs): makeAST(EBlock(assigns.concat(exprs)));
                                    default: makeAST(EBlock(assigns.concat([body])));
                                }
                                newClauses.push({ pattern: clause.pattern, guard: clause.guard, body: newBody });
                                continue;
                            }
                        }
                        newClauses.push(clause);
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function collectPatternBinders(pat: EPattern): Array<String> {
        var result: Array<String> = [];
        function walk(p: EPattern): Void {
            switch (p) {
                case PVar(name):
                    if (name != null && name.length > 0 && isLower(name)) result.push(name);
                case PTuple(items):
                    for (i in items) walk(i);
                case PList(items):
                    for (i in items) walk(i);
                case PCons(head, tail):
                    walk(head); walk(tail);
                case PMap(pairs):
                    for (kv in pairs) walk(kv.value);
                default:
            }
        }
        walk(pat);
        return result;
    }

    static function collectUsedLowerVars(ast: ElixirAST): Array<String> {
        var names = new Map<String, Bool>();
        function scan(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch(n.def) {
                case EVar(name):
                    if (name != null && name.length > 0 && isLower(name)) names.set(name, true);
                case EBlock(exprs):
                    for (e in exprs) scan(e);
                case EIf(c,t,e):
                    scan(c); scan(t); if (e != null) scan(e);
                case ECase(expr, clauses):
                    scan(expr); for (c in clauses) { if (c.guard != null) scan(c.guard); scan(c.body);} 
                case ECall(target, _, args):
                    if (target != null) scan(target); if (args != null) for (a in args) scan(a);
                case ERemoteCall(mod, _, args):
                    scan(mod); if (args != null) for (a in args) scan(a);
                case ETuple(items) | EList(items):
                    for (i in items) scan(i);
                case EMap(pairs):
                    for (p in pairs) { scan(p.key); scan(p.value); }
                default:
            }
        }
        scan(ast);
        return [for (k in names.keys()) k];
    }

    static inline function isLower(s: String): Bool {
        var c = s.charAt(0);
        return c.toLowerCase() == c; // crude but effective for variable vs module
    }
}

#end
