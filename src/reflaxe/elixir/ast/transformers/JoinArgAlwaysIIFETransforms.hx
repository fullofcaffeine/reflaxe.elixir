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
                    var firstArg = args[0];
                    // Wrap only when the first argument is not a single safe Elixir expression
                    // (e.g., an EBlock builder window). Avoid wrapping simple vars/lists/for-comprehensions.
                    var needsWrap = switch (firstArg.def) {
                        case ECall({def: EFn(_)}, _, _): false; // already IIFE
                        default: !isSafe(firstArg);
                    };
	                    if (!needsWrap) n else {
	                        var wrappedFirstArg = makeAST(ECall(makeAST(EFn([{ args: [], guard: null, body: firstArg }])), "", []));
	                        var newArgs:Array<ElixirAST> = [wrappedFirstArg];
	                        for (i in 1...args.length) newArgs.push(args[i]);
	                        makeASTWithMeta(ERemoteCall(modExpr, "join", newArgs), n.metadata, n.pos);
	                    }
                case ECall(target, "join", args) if (args != null && args.length >= 1 && target != null):
                    // Handle instance-style Enum.join call form
                    var firstArg = args[0];
                    var needsWrap = switch (firstArg.def) {
                        case ECall({def: EFn(_)}, _, _): false; // already IIFE
                        default: !isSafe(firstArg);
                    };
                    if (!needsWrap) n else {
                        var wrappedFirstArg = makeAST(ECall(makeAST(EFn([{ args: [], guard: null, body: firstArg }])), "", []));
                        var newArgs:Array<ElixirAST> = [wrappedFirstArg];
                        for (i in 1...args.length) newArgs.push(args[i]);
                        makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "join", newArgs), n.metadata, n.pos);
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
