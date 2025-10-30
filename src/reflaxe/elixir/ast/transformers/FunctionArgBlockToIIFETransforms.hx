package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FunctionArgBlockToIIFETransforms
 *
 * WHAT
 * - Ensures any multi-statement block used as a function argument is converted
 *   to an immediately-invoked anonymous function (IIFE), yielding a single
 *   valid expression in argument position.
 *
 * WHY
 * - Raw multi-statement blocks are invalid in argument position and lead to
 *   syntax errors (e.g., in Enum.join(<block>, ",")). Wrapping as an IIFE is
 *   idiomatic and preserves semantics.
 *
 * HOW
 * - Walk ECall/ERemoteCall nodes and wrap any argument whose def is EBlock
 *   with two or more statements: (fn -> <block> end).()
 */
class FunctionArgBlockToIIFETransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECall(target, name, args):
                    var newArgs = [];
                    for (a in args) if (shouldWrap(a)) newArgs.push(makeIIFE(unwrapParens(a))) else newArgs.push(a);
                    if (newArgs != args) makeAST(ECall(target, name, newArgs)) else n;
                case ERemoteCall(mod, name2, args2):
                    var newArgs2 = [];
                    for (a2 in args2) if (shouldWrap(a2)) newArgs2.push(makeIIFE(unwrapParens(a2))) else newArgs2.push(a2);
                    if (newArgs2 != args2) makeAST(ERemoteCall(mod, name2, newArgs2)) else n;
                default:
                    n;
            }
        });
    }

    static inline function unwrapParens(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case EParen(inner): inner;
            default: e;
        }
    }

    static inline function shouldWrap(a: ElixirAST): Bool {
        return switch (a.def) {
            case EBlock(sts) if (sts != null && sts.length > 1): true;
            case EDo(sts2) if (sts2 != null && sts2.length > 1): true;
            case EParen(inner):
                switch (inner.def) {
                    case EBlock(es) if (es != null && es.length > 1): true;
                    case EDo(es2) if (es2 != null && es2.length > 1): true;
                    default: false;
                }
            default: false;
        }
    }

    static inline function makeIIFE(block: ElixirAST): ElixirAST {
        return makeAST(ECall(makeAST(EFn([{ args: [], guard: null, body: block }])), "", []));
    }
}

#end
