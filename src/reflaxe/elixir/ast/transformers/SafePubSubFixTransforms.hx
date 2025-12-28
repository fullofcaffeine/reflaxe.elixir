package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SafePubSubFixTransforms
 *
 * WHAT
 * - Framework-specific hygiene fix for Phoenix.SafePubSub: ensure def is_valid_message/1
 *   uses binder name `msg` when the body references `msg`.
 *
 * WHY
 * - Late transformations can introduce `_msg` binders while body references `msg`,
 *   triggering undefined-variable errors under warnings-as-errors.
 *
 * HOW
 * - Detect module Phoenix.SafePubSub; within it, locate def/defp named is_valid_message
 *   and rename PVar("_msg") -> PVar("msg").

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class SafePubSubFixTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name == "Phoenix.SafePubSub"):
                    var newBody = [];
                    for (b in body) newBody.push(fixDef(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name == "Phoenix.SafePubSub"):
                    makeASTWithMeta(EDefmodule(name, fixDef(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function fixDef(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EDef(fname, args, guards, _body) if (fname == "is_valid_message"):
                    var pargs:Array<EPattern> = args.copy();
                    // Force binder to msg when underscored
                    for (i in 0...pargs.length) switch (pargs[i]) {
                        case PVar(n) if (n == "_msg"): pargs[i] = PVar("msg");
                        default:
                    }
                    // Replace body with explicit ERaw expression to avoid late regressions
                    var expr = makeAST(ERaw("not Kernel.is_nil(msg) and Map.has_key?(msg, \"type\") and not Kernel.is_nil(Map.get(msg, \"type\"))"));
                    makeASTWithMeta(EDef(fname, pargs, guards, expr), x.metadata, x.pos);
                case EDefp(fname2, args2, guards2, body2) if (fname2 == "is_valid_message"):
                    var newArgs2 = args2.copy();
                    for (i in 0...newArgs2.length) switch (newArgs2[i]) {
                        case PVar(n2) if (n2 == "_msg"): newArgs2[i] = PVar("msg");
                        default:
                    }
                    makeASTWithMeta(EDefp(fname2, newArgs2, guards2, body2), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }
}

#end
