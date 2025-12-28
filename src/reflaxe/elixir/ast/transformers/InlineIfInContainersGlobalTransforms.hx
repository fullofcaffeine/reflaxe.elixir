package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * InlineIfInContainersGlobalTransforms
 *
 * WHAT
 * - Wrap inline `if ...` expressions in parentheses when they appear as
 *   children of tuples, lists, or maps to avoid parser ambiguity.
 *
 * WHY
 * - Outside LiveView code (e.g., PubSub helpers), inline if inside tuples
 *   produces invalid `{:tag, if ..., do: ..., else: ...}` without parens.
 *   Adding parentheses fixes the ambiguity.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class InlineIfInContainersGlobalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
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

