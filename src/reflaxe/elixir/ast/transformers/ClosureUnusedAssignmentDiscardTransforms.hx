package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ClosureUnusedAssignmentDiscardTransforms
 *
 * WHAT
 * - In anonymous function (EFn) clause bodies, replace assignments of the form
 *   `var = expr` with `_ = expr` when `var` is not referenced later in the same
 *   clause body. Prevents unused-variable warnings inside closures (reduce/concat).
 *
 * WHY
 * - Prevents unused-variable warnings in closure bodies after normalization
 *   while preserving side effects from the right-hand expression.
 *
 * HOW
 * - For each EFn/clauses, when body is an EBlock, scan statements; for a
 *   statement EBinary(Match, EVar(name), rhs), check future usage in the rest
 *   of the statements (EVar occurrences or ERaw identifier tokens). If none,
 *   rewrite to EMatch(PWildcard, rhs).
 *
 * EXAMPLES
 * Haxe:
 *   arr.map(function(x) {
 *     var tmp = compute(x); // not used later
 *     return x;
 *   });
 * Elixir (before):
 *   Enum.map(arr, fn x -> tmp = compute(x); x end)
 * Elixir (after):
 *   Enum.map(arr, fn x -> _ = compute(x); x end)
 */
class ClosureUnusedAssignmentDiscardTransforms {
    public static function discardPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var body = cl.body;
                        switch (body.def) {
                            case EBlock(stmts):
                                var out: Array<ElixirAST> = [];
                                for (i in 0...stmts.length) {
                                    var s = stmts[i];
                                    var replaced = false;
                                    switch (s.def) {
                                        case EBinary(Match, left, rhs):
                                            switch (left.def) {
                                                case EVar(name):
                                                    if (
                                                        (name != null && name.length > 0 && name.charAt(0) == '_')
                                                        && !futureUsesName(stmts, i + 1, name)
                                                        && !exprReferencesName(rhs, name)
                                                    ) {
                                                        out.push(makeASTWithMeta(EMatch(PWildcard, rhs), s.metadata, s.pos));
                                                        replaced = true;
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                    if (!replaced) out.push(s);
                                }
                                newClauses.push({ args: cl.args, guard: cl.guard, body: makeASTWithMeta(EBlock(out), body.metadata, body.pos) });
                            default:
                                newClauses.push(cl);
                        }
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function exprReferencesName(e: ElixirAST, name: String): Bool {
        var found = false;
        function visit(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EVar(n) if (n == name): found = true;
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(t, _, args): if (t != null) visit(t); if (args != null) for (a in args) visit(a);
                case ERemoteCall(moduleExpr, _, remoteArgs): visit(moduleExpr); if (remoteArgs != null) for (argument in remoteArgs) visit(argument);
                case EBlock(ss): for (s in ss) visit(s);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case ECase(cond, cs): visit(cond); for (c in cs) { if (c.guard != null) visit(c.guard); visit(c.body);} 
                default:
            }
        }
        visit(e);
        return found;
    }

    static function futureUsesName(stmts: Array<ElixirAST>, start: Int, name: String): Bool {
        for (i in start...stmts.length) if (statementUsesName(stmts[i], name)) return true;
        return false;
    }

    static function statementUsesName(s: ElixirAST, name: String): Bool {
        var found = false;
        function visit(e: ElixirAST): Void {
            if (found || e == null || e.def == null) return;
            switch (e.def) {
                case EVar(n) if (n == name): found = true;
                case ERaw(code): if (code != null && containsIdent(code, name)) found = true;
                case EBlock(ss): for (x in ss) visit(x);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case ECase(expr, cs): visit(expr); for (c in cs) { if (c.guard != null) visit(c.guard); visit(c.body);} 
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(target, _, arguments): if (target != null) visit(target); for (argument in arguments) visit(argument);
                case ERemoteCall(remoteTarget, _, remoteArgs): visit(remoteTarget); for (argument in remoteArgs) visit(argument);
                case EList(els): for (el in els) visit(el);
                case ETuple(els): for (el in els) visit(el);
                case EMap(pairs): for (p in pairs) { visit(p.key); visit(p.value); }
                case EKeywordList(pairs): for (p in pairs) visit(p.value);
                case EStructUpdate(base, fields): visit(base); for (f in fields) visit(f.value);
                case EFn(clauses): for (cl in clauses) visit(cl.body);
                default:
            }
        }
        visit(s);
        return found;
    }

    static function containsIdent(s:String, ident:String):Bool {
        if (s == null || ident == null || ident.length == 0) return false;
        var i = 0;
        while (i < s.length) {
            var idx = s.indexOf(ident, i);
            if (idx == -1) return false;
            var ok = true;
            if (idx > 0) {
                var p = s.charAt(idx - 1);
                if (isIdent(p)) ok = false;
            }
            var endIdx = idx + ident.length;
            if (endIdx < s.length) {
                var n = s.charAt(endIdx);
                if (isIdent(n)) ok = false;
            }
            if (ok) return true; else i = endIdx;
        }
        return false;
    }

    static inline function isIdent(ch: String): Bool {
        if (ch == null || ch.length == 0) return false;
        var c = ch.charCodeAt(0);
        return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code) || c == '_'.code;
    }
}

#end
