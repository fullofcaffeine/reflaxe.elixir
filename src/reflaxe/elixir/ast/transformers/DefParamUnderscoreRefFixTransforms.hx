package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DefParamUnderscoreRefFixTransforms
 *
 * WHAT
 * - Within function bodies, rewrite references to underscored variants of
 *   function parameters (e.g., _tags) back to their defined names (tags)
 *   when there is no corresponding underscored parameter.
 *
 * WHY
 * - Hygiene passes may introduce underscore prefixing inconsistently in LiveView
 *   helpers, leading to undefined variables like _tags while the parameter is tags.
 *
 * HOW
 * - For each EDef/EDefp, collect parameter base names. Rewrite any EVar("_name")
 *   in the function body to EVar("name") when "name" is a parameter and there is
 *   no "_name" parameter.
 *
 * EXAMPLES
 * Before:
 *   defp render_tags(tags) do if Kernel.is_nil(tags) or length(_tags) == 0, do: "" end
 * After:
 *   defp render_tags(tags) do if Kernel.is_nil(tags) or length(tags) == 0, do: "" end
 */
class DefParamUnderscoreRefFixTransforms {
    public static function fixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, params, guards, body):
                    var map = buildParamMap(params);
                    var newBody = rewriteBody(body, map);
                    makeASTWithMeta(EDef(name, params, guards, newBody), node.metadata, node.pos);
                case EDefp(name, params, guards, body):
                    var map = buildParamMap(params);
                    var newBody = rewriteBody(body, map);
                    makeASTWithMeta(EDefp(name, params, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function buildParamMap(params: Array<EPattern>): Map<String, Bool> {
        var m = new Map<String, Bool>();
        for (p in params) collect(p, m);
        return m;
    }
    static function collect(p: EPattern, m: Map<String, Bool>): Void {
        switch (p) {
            case PVar(n) if (n != null && n.length > 0): m.set(n, true);
            case PTuple(es): for (e in es) collect(e, m);
            case PList(es): for (e in es) collect(e, m);
            case PCons(h, t): collect(h, m); collect(t, m);
            case PMap(kvs): for (kv in kvs) collect(kv.value, m);
            case PStruct(_, fs): for (f in fs) collect(f.value, m);
            case PPin(inner): collect(inner, m);
            default:
        }
    }

    static function rewriteBody(body: ElixirAST, params: Map<String, Bool>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (v != null && v.length > 1 && v.charAt(0) == '_'):
                    var base = v.substr(1);
                    if (params.exists(base) && !params.exists(v)) makeASTWithMeta(EVar(base), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }
}

#end

