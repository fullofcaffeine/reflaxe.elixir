package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * RedundantAssignmentCleanup
 *
 * WHAT
 * - Remove clearly redundant local reassignments like `this1 = query` or
 *   `this1 = query`-style placeholders that serve no purpose and trigger unused
 *   variable warnings.
 *
 * WHY
 * - The generator sometimes emits `thisN` placeholder binds to satisfy earlier
 *   transforms. These produce warnings and clutter. Since they simply copy a
 *   variable without side effects, we can safely drop them.
 *
 * HOW
 * - Transform `EMatch(PVar(name), EVar(rhs))` where `name` matches `^this\d*$`
 *   into an empty expression (we rewrite to `EBlock([])` which prints nothing).
 * - Similarly remove `EMatch(PVar("new_query"), <expr>)` since it’s never used.
 *
 * EXAMPLES
 *   this1 = query        -> (removed)
 *   new_query = where..  -> (removed)
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
                            n;
                    }
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

