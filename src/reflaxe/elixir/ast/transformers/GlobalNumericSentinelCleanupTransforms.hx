package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * GlobalNumericSentinelCleanupTransforms
 *
 * WHAT
 * - Remove standalone numeric sentinel literals (0, 1, 0.0) from any EBlock/EDo,
 *   regardless of nesting (EFn, def/defp, case, etc.).
 *
 * WHY
 * - Late passes can reintroduce numeric sentinels; this global sweep ensures
 *   warnings-as-errors do not trigger on bare 1/0/0.0 statements anywhere.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class GlobalNumericSentinelCleanupTransforms {
    public static function cleanupPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out = [];
                    for (s in stmts) switch (s.def) {
                        case EInteger(v) if (v == 0 || v == 1):
                        case EFloat(f) if (f == 0.0):
                        default: out.push(s);
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                case EDo(stmts2):
                    var out2 = [];
                    for (s2 in stmts2) switch (s2.def) {
                        case EInteger(v2) if (v2 == 0 || v2 == 1):
                        case EFloat(f2) if (f2 == 0.0):
                        default: out2.push(s2);
                    }
                    makeASTWithMeta(EDo(out2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end

