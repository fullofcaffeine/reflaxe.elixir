package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * JoinArgForceIIFETransforms
 *
 * WHAT
 * - As a last-resort safety, ensure the first argument to Enum.join/2 is a
 *   single valid expression by wrapping complex shapes in an IIFE.
 *
 * WHY
 * - Earlier rewrites may miss certain desugared list-builder forms outside of
 *   interpolation, leaving raw multi-statement sequences as the first arg.
 *   Elixir forbids statements in argument position.
 *
 * HOW
 * - Detect ERemoteCall(Enum, "join", [arg, sep]) where arg is a complex node
 *   (EBlock, EDo, EMatch, EBinary(Concat|StringConcat), or a Paren-wrapped
 *   complex). Replace arg with (fn -> <arg> end).().

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class JoinArgForceIIFETransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(_, "join", args) if (args != null && args.length >= 1):
                    var first = args[0];
                    if (needsIIFE(first)) {
                        var wrapped = makeIIFE(unwrapParens(first));
                        var newArgs = [wrapped];
                        for (i in 1...args.length) newArgs.push(args[i]);
                        makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "join", newArgs), n.metadata, n.pos);
                    } else {
                        n;
                    }
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

    static inline function makeIIFE(body: ElixirAST): ElixirAST {
        return makeAST(ECall(makeAST(EFn([{ args: [], guard: null, body: body }])), "", []));
    }

    static function needsIIFE(e: ElixirAST): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (found || n == null) return;
            switch (n.def) {
                case EBlock(_) | EDo(_) | EMatch(_, _) | EBinary(_, _, _):
                    found = true;
                case ERemoteCall(mod, name, args):
                    walk(mod); for (a in args) walk(a);
                case ECall(t, _, args2):
                    if (t != null) walk(t); for (a2 in args2) walk(a2);
                case EParen(inner):
                    walk(inner);
                case EIf(c,t,eopt): walk(c); walk(t); if (eopt != null) walk(eopt);
                default:
            }
        }
        walk(e);
        return found;
    }
}

#end
