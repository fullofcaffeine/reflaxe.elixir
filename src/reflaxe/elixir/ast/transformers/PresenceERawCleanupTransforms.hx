package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
using StringTools;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceERawCleanupTransforms
 *
 * WHAT
 * - Clean up ERaw reduce bodies in Presence modules to remove constant-true
 *   sentinel conditionals and trailing acc returns.
 *
 * HOW
 * - Scope: modules whose names end with ".Presence" or include "Web.Presence".
 * - Replace occurrences of "if 1, do: acc ++ [entry.metas[0]], else: acc" with
 *   "acc ++ [entry.metas[0]]".
 * - Remove trailing "\n  acc\nend)" following an if-block in the reduce body by
 *   collapsing to just "end)".

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class PresenceERawCleanupTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var nb = [];
                    for (b in body) nb.push(cleanERaw(b));
                    makeASTWithMeta(EModule(name, attrs, nb), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    makeASTWithMeta(EDefmodule(name, cleanERaw(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function cleanERaw(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case ERaw(code):
                    var out = code;
                    if (out != null && out.indexOf("Phoenix.Presence.") != -1) {
                        // Collapse constant-true inner if in presence reduce
                        out = StringTools.replace(out, "if 1, do: acc ++ [entry.metas[0]], else: acc", "acc ++ [entry.metas[0]]");
                        // Drop trailing acc after reduce body if present
                        out = StringTools.replace(out, "\n  acc\nend)", "\nend)");
                    }
                    out != code ? makeASTWithMeta(ERaw(out), x.metadata, x.pos) : x;
                default:
                    x;
            }
        });
    }
}

#end
