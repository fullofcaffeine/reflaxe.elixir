package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * RedundantAssignmentCleanup
 *
 * WHAT
 * - Eliminates redundant placeholder binds that trigger unused-variable warnings
 *   and collapses trivial chained assignments into a single assignment.
 *
 * WHY
 * - Builder/transforms can emit `thisN` temporaries (e.g., `changeset = this1 = change(...)`).
 *   Elixir warns that `this1` is unused. Such chains are semantically equivalent to a
 *   single assignment and should be collapsed for idiomatic output.
 *
 * HOW
 * - Remove pure copies: `EMatch(PVar(thisN), EVar(x))` → drop.
 * - Remove known throwaway binds like `new_query = ...`.
 * - Collapse nested chain: `EMatch(PVar(dst), EMatch(PVar(thisN), expr))` → `dst = expr`.
 * - Collapse sequential chain inside blocks: `thisN = expr; dst = thisN` → `dst = expr`.
 *   Only applies when `thisN` matches `^this\d*$` to avoid touching user vars.
 *
 * EXAMPLES
 *   changeset = this1 = Ecto.Changeset.change(..)  ->  changeset = Ecto.Changeset.change(..)
 *   this2 = query; changeset = this2               ->  changeset = query
 */
class RedundantAssignmentCleanup {
    public static function cleanupPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EMatch(pattern, expr):
                    switch (pattern) {
                        case PVar(name) if (isRedundantName(name) && isSafeCopy(expr)):
                            // Remove by replacing with an empty block
                            makeASTWithMeta(EBlock([]), n.metadata, n.pos);
                        case PVar(name) if (name == "new_query"):
                            makeASTWithMeta(EBlock([]), n.metadata, n.pos);
                        default:
                            // Collapse nested chained match: dst = (thisN = expr) -> dst = expr
                            switch (expr.def) {
                                case EMatch(innerPat, innerExpr):
                                    switch (innerPat) {
                                        case PVar(innerName) if (isRedundantName(innerName)):
                                            makeASTWithMeta(EMatch(pattern, innerExpr), n.metadata, n.pos);
                                        default:
                                            n;
                                    }
                                default:
                                    n;
                            }
                    }
                case EBlock(stmts):
                    // Collapse sequential pattern: thisN = expr; dst = thisN
                    var out = [];
                    var i = 0;
                    while (i < stmts.length) {
                        var s = stmts[i];
                        var collapsed = false;
                        switch (s.def) {
                            case EMatch(PVar(tmp), rhs) if (isRedundantName(tmp)):
                                if (i + 1 < stmts.length) {
                                    var s2 = stmts[i + 1];
                                    switch (s2.def) {
                                        case EMatch(PVar(dst), {def: EVar(v)}) if (v == tmp):
                                            out.push(makeASTWithMeta(EMatch(PVar(dst), rhs), s2.metadata, s2.pos));
                                            i += 2;
                                            collapsed = true;
                                        default:
                                    }
                                }
                            default:
                        }
                        if (!collapsed) { out.push(s); i++; }
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function isRedundantName(name: String): Bool {
        if (name == null) return false;
        if (name == "this1" || name == "this2" || name == "this3") return true;
        if (StringTools.startsWith(name, "this")) {
            // Allow any numeric suffixes
            var rest = name.substr(4);
            var numeric = true;
            for (i in 0...rest.length) {
                var c = rest.charCodeAt(i);
                if (c < '0'.code || c > '9'.code) { numeric = false; break; }
            }
            return numeric || rest == "";
        }
        return false;
    }

    static inline function isSafeCopy(expr: ElixirAST): Bool {
        // Only consider pure variable copies safe to remove
        return expr != null && expr.def != null && switch (expr.def) {
            case EVar(_): true;
            default: false;
        }
    }
}

#end
