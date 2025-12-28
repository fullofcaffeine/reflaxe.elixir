package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventBodyAlignToHeadTransforms
 *
 * WHAT
 * - Aligns body references to the declared second parameter name of
 *   `handle_event/3`, replacing both `params` and `_params` occurrences
 *   with the actual binder used in the head.
 *
 * WHY
 * - Late hygiene passes or generator choices can produce head/body
 *   mismatches (e.g., head uses `_params` while body uses `params`).
 *   This pass ensures consistency without renaming the head.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HandleEventBodyAlignToHeadTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "handle_event" && args != null && args.length == 3):
                    var argName = switch (args[1]) { case PVar(p): p; default: null; };
                    if (argName == null) n else {
                        var nb = align(body, argName);
                        makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                    }
                case EDefp(name2, args2, guards2, body2) if (name2 == "handle_event" && args2 != null && args2.length == 3):
                    var argName2 = switch (args2[1]) { case PVar(p2): p2; default: null; };
                    if (argName2 == null) n else {
                        var nb2 = align(body2, argName2);
                        makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
                    }
                default:
                    n;
            }
        });
    }

    static function align(body: ElixirAST, binder:String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (v == "params" || v == "_params"):
                    makeASTWithMeta(EVar(binder), x.metadata, x.pos);
                default: x;
            }
        });
    }
}

#end

