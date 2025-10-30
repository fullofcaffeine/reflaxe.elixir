package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * JoinArgAlwaysIIFETransforms
 *
 * WHAT
 * - Ensures Enum.join first argument is a single valid expression by wrapping
 *   it in an IIFE unless it is already a simple, safe expression (list literal
 *   or comprehension or variable).
 *
 * WHY
 * - Some late-emitted shapes can still surface as raw statement sequences in
 *   argument position. This pass guarantees validity without relying on
 *   printed-string heuristics.
 */
class JoinArgAlwaysIIFETransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(modExpr, "join", args) if (args != null && args.length >= 1):
                    var arg0 = args[0];
                    // Unconditionally wrap first arg in an IIFE unless it is already an IIFE
                    var needsWrap = switch (arg0.def) {
                        case ECall({def: EFn(_)}, _, _): false;
                        default: true;
                    };
                    if (!needsWrap) n else {
                        var wrapped = makeAST(ECall(makeAST(EFn([{ args: [], guard: null, body: arg0 }])), "", []));
                        var newArgs:Array<ElixirAST> = [wrapped];
                        for (i in 1...args.length) newArgs.push(args[i]);
                        makeASTWithMeta(ERemoteCall(modExpr, "join", newArgs), n.metadata, n.pos);
                    }
                case ECall(target, "join", args) if (args != null && args.length >= 1 && target != null):
                    // Handle instance-style Enum.join call form
                    var needsWrap2 = switch (args[0].def) {
                        case ECall({def: EFn(_)}, _, _): false;
                        default: true;
                    };
                    if (!needsWrap2) n else {
                        var wrapped2 = makeAST(ECall(makeAST(EFn([{ args: [], guard: null, body: args[0] }])), "", []));
                        var newArgs2:Array<ElixirAST> = [wrapped2];
                        for (i in 1...args.length) newArgs2.push(args[i]);
                        makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "join", newArgs2), n.metadata, n.pos);
                    }
                default:
                    n;
            }
        });
    }

    static function isSafe(e: ElixirAST): Bool {
        return switch (e.def) {
            case EList(_) | EFor(_, _, _, _, _) | EVar(_): true;
            case EParen(inner): isSafe(inner);
            default: false;
        }
    }
}

#end
