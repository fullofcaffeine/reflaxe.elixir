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
                case ECall(target, "", []) if (target != null):
                    var targetCore = target;
                    while (true) switch (targetCore.def) {
                        case EParen(inner): targetCore = inner; continue;
                        default: break;
                    }
                    var clauses: Null<Array<{args:Array<EPattern>, guard:Null<ElixirAST>, body:ElixirAST}>> = switch (targetCore.def) {
                        case EFn(cs): cs;
                        default: null;
                    };

                    if (clauses == null || clauses.length != 1) return n;
                    var cl = clauses[0];
                    // Only unwrap IIFEs of 0-arg functions
                    if (cl.args != null && cl.args.length != 0) return n;

                    var innerFn = unwrapReturnedFn(cl.body);
                    if (innerFn != null) {
                        makeASTWithMeta(innerFn.def, n.metadata, n.pos);
                    } else {
                        n;
                    }
                default:
                    n;
            }
        });
    }

    static function unwrapReturnedFn(body: ElixirAST): Null<ElixirAST> {
        if (body == null || body.def == null) return null;
        return switch (body.def) {
            case EFn(_):
                body;
            case EParen(inner):
                unwrapReturnedFn(inner);
            case EBlock(stmts) | EDo(stmts):
                var meaningful = [];
                for (s in stmts) if (!isNumericSentinel(s)) meaningful.push(s);
                if (meaningful.length == 1) unwrapReturnedFn(meaningful[0]) else null;
            default:
                null;
        };
    }

    static function isNumericSentinel(n: ElixirAST): Bool {
        if (n == null || n.def == null) return false;
        return switch (n.def) {
            case EInteger(i): i == 0 || i == 1;
            case EFloat(f): f == 0.0;
            default: false;
        };
    }
}

#end
