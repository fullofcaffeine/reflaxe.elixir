package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
using StringTools;

/**
 * ReduceWhileSentinelCleanupTransforms
 *
 * WHAT
 * - Removes bare numeric literal statements inside the anonymous function bodies
 *   passed to Enum.reduce_while/3 (common sentinel artifacts from loop lowering).
 *
 * WHY
 * - Prevents warnings like "code block contains unused literal 1" within
 *   reduce_while branches while keeping semantics.
 *
 * HOW
 * - For any ERemoteCall(..., "reduce_while", [_, _, fn]), recursively walk the
 *   fn body and remove EInteger(1|0) and EFloat(0.0) statements in EBlock/EDo.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ReduceWhileSentinelCleanupTransforms {
    static function cleanupNode(n: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EBlock(stmts):
                    var out = [];
                    for (s in stmts) switch (s.def) {
                        case EInteger(v) if (v == 0 || v == 1):
                            // drop
                        case EFloat(f) if (f == 0.0):
                            // drop
                        default: out.push(s);
                    }
                    makeASTWithMeta(EBlock(out), x.metadata, x.pos);
                case EDo(stmts):
                    var out2 = [];
                    for (s in stmts) switch (s.def) {
                        case EInteger(v2) if (v2 == 0 || v2 == 1):
                        case EFloat(f2) if (f2 == 0.0):
                        default: out2.push(s);
                    }
                    makeASTWithMeta(EDo(out2), x.metadata, x.pos);
                case ERaw(code):
                    // Remove lines that are only numeric sentinels (1/0) in raw code blocks
                    var lines = code.split("\n");
                    var outLines = [];
                    for (ln in lines) {
                        var t = ln.trim();
                        if (t == "1" || t == "0") {
                            // skip sentinel-only line
                        } else {
                            outLines.push(ln);
                        }
                    }
                    var newCode = outLines.join("\n");
                    if (newCode != code) makeASTWithMeta(ERaw(newCode), x.metadata, x.pos) else x;
                default:
                    x;
            }
        });
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, func, args) if (func == "reduce_while" && args != null && args.length >= 3):
                    var fnArg = args[2];
                    var cleaned = cleanupNode(fnArg);
                    if (cleaned != fnArg) {
                        var newArgs = args.copy();
                        newArgs[2] = cleaned;
                        makeASTWithMeta(ERemoteCall(mod, func, newArgs), n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }
}

#end
