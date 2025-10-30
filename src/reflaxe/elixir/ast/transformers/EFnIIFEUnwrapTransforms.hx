package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnIIFEUnwrapTransforms
 *
 * WHAT
 * - Unwraps immediately-invoked zero-arg anonymous functions whose body is an
 *   anonymous function, i.e., (fn -> (fn args -> ... end) end).() → (fn args -> ... end)
 *
 * WHY
 * - Some argument wrappers convert a block to an IIFE even when the block
 *   simply returns an anonymous function. This breaks places expecting a plain
 *   anonymous function (e.g., Enum.each/map second arg).
 */
class EFnIIFEUnwrapTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECall({def: EFn(clauses)}, "", []) if (clauses.length == 1):
                    var cl = clauses[0];
                    switch (cl.body.def) {
                        case EFn(_):
                            makeASTWithMeta(cl.body.def, n.metadata, n.pos);
                        case EParen(inner) if (switch (inner.def) { case EFn(_): true; default: false; }):
                            makeASTWithMeta(inner.def, n.metadata, n.pos);
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
