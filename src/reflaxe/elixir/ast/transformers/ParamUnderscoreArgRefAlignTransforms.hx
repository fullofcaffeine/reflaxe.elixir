package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ParamUnderscoreArgRefAlignTransforms
 *
 * WHAT
 * - Inside a function that declares a parameter named `params`, rewrite
 *   occurrences of `_params` in the body to `params`.
 *
 * WHY
 * - Prevents "underscored variable _params is used" warnings without changing
 *   semantics. Shape-based and generic for LiveView wrappers.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ParamUnderscoreArgRefAlignTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var hasParams = false;
                    for (a in args) switch (a) { case PVar(v) if (v == "params"): hasParams = true; default: }
                    if (!hasParams) n else {
                        var nb = rewrite(body, "_params", "params");
                        makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                    }
                default:
                    n;
            }
        });
    }

    static function rewrite(body: ElixirAST, from:String, to:String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
                default: x;
            }
        });
    }
}

#end

