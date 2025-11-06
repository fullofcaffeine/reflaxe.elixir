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
                    for (a in args) if (shouldWrap(a)) {
                        #if debug_iife
                        trace('[FunctionArgBlockToIIFE] wrapping arg for ' + (name == null ? '<anon>' : name));
                        #end
                        newArgs.push(makeIIFE(unwrapParens(a)));
                    } else newArgs.push(a);
                    if (newArgs != args) makeAST(ECall(target, name, newArgs)) else n;
                case ERemoteCall(mod, name2, args2):
                    var newArgs2 = [];
                    for (a2 in args2) if (shouldWrap(a2)) {
                        #if debug_iife
                        trace('[FunctionArgBlockToIIFE] wrapping arg for remote ' + name2);
                        #end
                        newArgs2.push(makeIIFE(unwrapParens(a2)));
                    } else newArgs2.push(a2);
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

    static inline function isNumericSentinel(e: ElixirAST): Bool {
        return switch (e.def) {
            case EInteger(v) if (v == 0 || v == 1): true;
            case EFloat(f) if (f == 0.0): true;
            default: false;
        }
    }

    static inline function shouldWrap(a: ElixirAST): Bool {
        function needsWrapFor(sts:Array<ElixirAST>):Bool {
            if (sts == null) return false;
            // Ignore bare numeric sentinels often emitted by earlier passes
            var filtered = [];
            for (s in sts) if (!isNumericSentinel(s)) filtered.push(s);
            // If any top-level element is already an anonymous function, don't wrap
            for (s in filtered) switch (s.def) { case EFn(_): return false; default: }
            // Otherwise, wrap only if there are multiple meaningful statements
            return filtered.length > 1;
        }

        return switch (a.def) {
            case EBlock(sts): needsWrapFor(sts);
            case EDo(sts2): needsWrapFor(sts2);
            case EParen(inner):
                switch (inner.def) {
                    case EBlock(es): needsWrapFor(es);
                    case EDo(es2): needsWrapFor(es2);
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
