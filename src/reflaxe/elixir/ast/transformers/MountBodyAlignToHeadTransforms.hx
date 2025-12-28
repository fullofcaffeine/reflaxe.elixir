package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * MountBodyAlignToHeadTransforms
 *
 * WHAT
 * - Aligns body references to the declared first parameter name of `mount/3`,
 *   replacing both `params` and `_params` occurrences with the actual binder
 *   used in the head.

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class MountBodyAlignToHeadTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "mount" && args != null && args.length == 3):
                    var binder = switch (args[0]) { case PVar(p): p; default: null; };
                    if (binder == null) n else makeASTWithMeta(EDef(name, args, guards, align(body, binder)), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2) if (name2 == "mount" && args2 != null && args2.length == 3):
                    var binder2 = switch (args2[0]) { case PVar(p2): p2; default: null; };
                    if (binder2 == null) n else makeASTWithMeta(EDefp(name2, args2, guards2, align(body2, binder2)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function align(body: ElixirAST, binder:String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (v == "params" || v == "_params"): makeASTWithMeta(EVar(binder), x.metadata, x.pos);
                default: x;
            }
        });
    }
}

#end

