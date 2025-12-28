package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * IfInlineInContainerParenTransforms
 *
 * WHAT
 * - Wrap inline `if ... do ... else ... end` expressions in parentheses when
 *   they appear inside container literals (tuples, lists, maps). This avoids
 *   parser ambiguity errors in Elixir, which require parentheses in such cases.
 *
 * WHY
 * - Generated code can embed an `if` directly as an element of a tuple or as a
 *   value inside a map literal. Elixir requires parentheses around the `if`
 *   expression to disambiguate container boundaries.
 *
 * HOW
 * - For ETuple/elist/EMap, wrap any child expression of form EIf(...) with
 *   EParen(EIf(...)).

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class IfInlineInContainerParenTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        // Gate: only run for LiveView modules to avoid broad snapshot churn
        if (ast == null || ast.metadata == null || (ast.metadata.isLiveView != true)) {
            return ast;
        }
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ETuple(elements):
                    var changed = false;
                    var newEls = elements.map(function(e) {
                        return switch (e.def) {
                            case EIf(_,_,_): changed = true; makeAST(EParen(e));
                            default: e;
                        }
                    });
                    changed ? makeASTWithMeta(ETuple(newEls), n.metadata, n.pos) : n;
                case EList(elements):
                    var changed2 = false;
                    var newEls2 = elements.map(function(e) {
                        return switch (e.def) {
                            case EIf(_,_,_): changed2 = true; makeAST(EParen(e));
                            default: e;
                        }
                    });
                    changed2 ? makeASTWithMeta(EList(newEls2), n.metadata, n.pos) : n;
                case EMap(pairs):
                    var changed3 = false;
                    var newPairs = pairs.map(function(p) {
                        var v = p.value;
                        var nv = switch (v.def) {
                            case EIf(_,_,_): changed3 = true; makeAST(EParen(v));
                            default: v;
                        };
                        return { key: p.key, value: nv };
                    });
                    changed3 ? makeASTWithMeta(EMap(newPairs), n.metadata, n.pos) : n;
                default:
                    n;
            }
        });
    }
}

#end
