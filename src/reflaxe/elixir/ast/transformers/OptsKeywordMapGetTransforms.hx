package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * OptsKeywordMapGetTransforms
 *
 * WHAT
 * - Rewrite any keyword list values of the form opts.<key> to Map.get(opts, :<key>),
 *   regardless of surrounding call site. This is a broad, safe normalization.
 *
 * WHY
 * - Avoid non-idiomatic and warning-prone dot/access usage on maps in option lists.
 *   Ensures uniform Map.get usage across late-emitted keyword lists.
 *
 * HOW
 * - Traverse EKeywordList and replace values that are either EField(opts, key)
 *   or EAccess(opts, :key) with Map.get(opts, :key). Leaves other values intact.
 *
 * EXAMPLES
 * Before:
 *   [min: opts.min, max: opts[:max], step: 1]
 * After:
 *   [min: Map.get(opts, :min), max: Map.get(opts, :max), step: 1]
 */
class OptsKeywordMapGetTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EKeywordList(pairs):
                    var out = [];
                    for (p in pairs) {
                        var v = switch (p.value.def) {
                            case EField({def: EVar(name)}, fld) if (name == "opts"):
                                makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(fld))]));
                            case EAccess({def: EVar(name2)}, key) if (name2 == "opts"):
                                var atomKey = switch (key.def) { case EAtom(a): a; default: null; };
                                if (atomKey != null) makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(atomKey))])) else p.value;
                            default:
                                p.value;
                        }
                        out.push({key: p.key, value: v});
                    }
                    makeAST(EKeywordList(out));
                default:
                    n;
            }
        });
    }
}

#end
