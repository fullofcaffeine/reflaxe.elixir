package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalUnderscoreBinderPromoteTransforms
 *
 * WHAT
 * - Promote local binders from _name to name when subsequent code references
 *   the non-underscored variant and does not reference the underscored one.
 *
 * WHY
 * - Some hygiene passes underscore local assignments to silence warnings, but
 *   later code may correctly reference the base name (e.g., query). Promote
 *   the binder to match usage and avoid undefined variable errors.
 *
 * HOW
 * - Walk EBlock statements; for each EMatch(PVar("_name"), rhs) at index i,
 *   scan statements (i+1..end) for references to "name" and "_name". If name
 *   is referenced and _name is not, rewrite binder to PVar("name").
 *
 * EXAMPLES
 * Before:
 *   _query = String.downcase(search_query)
 *   Enum.filter(todos, fn t -> match?(... query ...) end)
 * After:
 *   query = String.downcase(search_query)
 *   Enum.filter(todos, fn t -> match?(... query ...) end)
 */
class LocalUnderscoreBinderPromoteTransforms {
    public static function promotePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        switch (s.def) {
                            case EMatch(PVar(name), rhs) if (name != null && name.length > 1 && name.charAt(0) == '_'):
                                var base = name.substr(1);
                                var usedBase = false;
                                var usedUnderscore = false;
                                for (j in i+1...stmts.length) {
                                    if (!usedBase && statementUsesName(stmts[j], base)) usedBase = true;
                                    if (!usedUnderscore && statementUsesName(stmts[j], name)) usedUnderscore = true;
                                    if (usedBase && usedUnderscore) break;
                                }
                                if (usedBase && !usedUnderscore) {
                                    out.push(makeASTWithMeta(EMatch(PVar(base), rhs), s.metadata, s.pos));
                                } else {
                                    out.push(s);
                                }
                            case EBinary(Match, left, rhs):
                                // Handle plain assignment: _name = rhs
                                switch (left.def) {
                                    case EVar(v) if (v != null && v.length > 1 && v.charAt(0) == '_'):
                                        var base2 = v.substr(1);
                                        var usedBase2 = false;
                                        var usedUnderscore2 = false;
                                        for (j in i+1...stmts.length) {
                                            if (!usedBase2 && statementUsesName(stmts[j], base2)) usedBase2 = true;
                                            if (!usedUnderscore2 && statementUsesName(stmts[j], v)) usedUnderscore2 = true;
                                            if (usedBase2 && usedUnderscore2) break;
                                        }
                                        if (usedBase2 && !usedUnderscore2) {
                                            out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(base2), left.metadata, left.pos), rhs), s.metadata, s.pos));
                                        } else {
                                            out.push(s);
                                        }
                                    default:
                                        out.push(s);
                                }
                            default:
                                out.push(s);
                        }
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                case EDo(bodyStmts):
                    // Treat do/end blocks similarly to EBlock
                    var block = makeAST(EBlock(bodyStmts));
                    var transformed = promotePass(block);
                    // Extract back inner statements if still a block
                    switch (transformed.def) {
                        case EBlock(xs): makeASTWithMeta(EDo(xs), n.metadata, n.pos);
                        default: n;
                    }
                default:
                    n;
            }
        });
    }

    static function statementUsesName(s: ElixirAST, name: String): Bool {
        var found = false;
        function visit(e: ElixirAST): Void {
            if (found || e == null || e.def == null) return;
            switch (e.def) {
                case EVar(n) if (n == name): found = true;
                case ERaw(code):
                    if (code != null && containsIdent(code, name)) found = true;
                case EBlock(ss): for (x in ss) visit(x);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case ECase(expr, cs): visit(expr); for (c in cs) { if (c.guard != null) visit(c.guard); visit(c.body);} 
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(tgt2, _, args2): visit(tgt2); for (a2 in args2) visit(a2);
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
