package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * BlockUnusedAssignmentDiscardTransforms
 *
 * WHAT
 * - In function bodies (EDef → EBlock), rewrite `var = expr` to `_ = expr` when `var` is not
 *   referenced later in the same block.
 */
/**
 * BlockUnusedAssignmentDiscardTransforms
 *
 * WHAT
 * - In block-like contexts (EDef/EFn/EBlock/EDo), rewrite `var = expr` to `_ = expr`
 *   when `var` is not referenced later in the same block. Also supports `EMatch(PVar, rhs)`.
 *
 * WHY
 * - Removes throwaway temps introduced by lowerings without changing semantics. This
 *   reduces warnings and enables WAE=0 for generated LiveView helpers.
 *
 * HOW
 * - For each block, forward-scan for later usage (including ERaw, map/keyword, struct
 *   update targets) before deciding to discard the assignment target.
 *
 * EXAMPLES
 * Before: this1 = Ecto.Changeset.change(cs); ... (no later use of this1)
 * After:  _ = Ecto.Changeset.change(cs)
 */
class BlockUnusedAssignmentDiscardTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var nb = rewriteBody(body);
                    makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                case EBlock(_):
                    rewriteBody(n);
                case EDo(_):
                    rewriteBody(n);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var b = cl.body;
                        newClauses.push({ args: cl.args, guard: cl.guard, body: rewriteBody(b) });
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * rewriteBody
     *
     * WHAT
     * - Performs the per-block transformation, handling both EBinary(Match, …) and
     *   EMatch(PVar, rhs) forms.
     */
    static function rewriteBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    switch (s.def) {
                        case EBinary(Match, left, rhs):
                            switch (left.def) {
                                case EVar(nm):
                                    // Safety: do not discard known supervisor children binding
                                    if (nm == "children") { out.push(s); break; }
                                    if (!usedLater(stmts, i + 1, nm)) {
                                        out.push(makeASTWithMeta(EMatch(PWildcard, rhs), s.metadata, s.pos));
                                    } else out.push(s);
                                default: out.push(s);
                            }
                        case EMatch(pat, rhs2):
                            switch (pat) {
                                case PVar(nm2):
                                    if (nm2 == "children") { out.push(s); break; }
                                    if (!usedLater(stmts, i + 1, nm2)) {
                                        out.push(makeASTWithMeta(EMatch(PWildcard, rhs2), s.metadata, s.pos));
                                    } else out.push(s);
                                default: out.push(s);
                            }
                        default:
                            out.push(s);
                    }
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            case EDo(stmts2):
                // Treat EDo like EBlock for hygiene
                var out2:Array<ElixirAST> = [];
                for (i in 0...stmts2.length) {
                    var s2 = stmts2[i];
                    switch (s2.def) {
                        case EBinary(Match, left2, rhs2):
                            switch (left2.def) {
                                case EVar(nm2):
                                    if (!usedLater(stmts2, i + 1, nm2)) {
                                        out2.push(makeASTWithMeta(EMatch(PWildcard, rhs2), s2.metadata, s2.pos));
                                    } else out2.push(s2);
                                default: out2.push(s2);
                            }
                        default:
                            out2.push(s2);
                    }
                }
                makeASTWithMeta(EDo(out2), body.metadata, body.pos);
            default:
                body;
        }
    }

    static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (j in start...stmts.length) if (stmtUsesVar(stmts[j], name)) return true; return false;
    }

    /**
     * stmtUsesVar
     *
     * WHAT
     * - Determines if `name` is referenced in `n` (including inside ERaw and string
     *   interpolation) to guide safe discards.
     *
     * WHY INLINE HELPERS
     * - Boundary checks for tokens and interpolation scanning are kept as small inline
     *   helpers to reduce overhead in hot traversal paths.
     */
    static function stmtUsesVar(n:ElixirAST, name:String):Bool {
        var found = false;
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
        }
        function walk(x:ElixirAST, inPattern:Bool):Void {
            if (x == null || found) return;
            switch (x.def) {
                case EVar(v) if (!inPattern && v == name): found = true;
                case ERaw(code):
                    if (name != null && name.length > 0 && name.charAt(0) != '_' && code != null) {
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
                case EBinary(Match, left, rhs): walk(rhs, false);
                case EMatch(pat, rhs2): walk(rhs2, false);
                case EBlock(ss): for (s in ss) walk(s, false);
                case EIf(c,t,e): walk(c, false); walk(t, false); if (e != null) walk(e, false);
                case EBinary(_, l, r): walk(l, false); walk(r, false);
                case ECall(tgt, _, args): if (tgt != null) walk(tgt, false); for (a in args) walk(a, false);
                case ERemoteCall(tgt2, _, args2): walk(tgt2, false); for (a2 in args2) walk(a2, false);
                case ECase(expr, cs): walk(expr, false); for (c in cs) walk(c.body, false);
                case EKeywordList(pairs): for (p in pairs) walk(p.value, false);
                case EMap(pairs):
                    // Ensure we detect usage inside literal maps like %{ key => var }
                    for (p in pairs) { walk(p.key, false); walk(p.value, false); }
                case EStructUpdate(base, fields): walk(base, false); for (f in fields) walk(f.value, false);
                case EField(obj, _): walk(obj, false);
                case EAccess(tgt3, key): walk(tgt3, false); walk(key, false);
                case EString(str):
                    // Detect string interpolation and search for name within it
                    var i2 = 0;
                    while (!found && str != null && i2 < str.length) {
                        var idx2 = str.indexOf("#{", i2);
                        if (idx2 == -1) break;
                        var j2 = str.indexOf("}", idx2 + 2);
                        if (j2 == -1) break;
                        var inner = str.substr(idx2 + 2, j2 - (idx2 + 2));
                        if (inner.indexOf(name) != -1) { found = true; break; }
                        i2 = j2 + 1;
                    }
                case ETuple(elems): for (e in elems) walk(e, false);
                default:
            }
        }
        walk(n, false);
        return found;
    }
}

#end
