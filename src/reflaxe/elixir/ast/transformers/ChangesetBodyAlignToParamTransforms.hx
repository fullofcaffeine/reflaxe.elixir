package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ChangesetBodyAlignToParamTransforms
 *
 * WHAT
 * - Aligns body variable references to the actual parameter names in functions
 *   named `changeset`. If parameters are underscored (e.g., `_user`, `_attrs`)
 *   but the body references `user`/`attrs`, rewrite the body references to the
 *   underscored variants to restore binder/body consistency.
 *
 * WHY
 * - Some code generation paths underscore params (stubs) while downstream code
 *   may still reference base names. This creates undefined-variable errors in
 *   Elixir. Aligning body references to the declared parameter names avoids
 *   compile failures without guessing names.
 *
 * HOW
 * - For EDef/EDefp with name == "changeset", collect param names. For each
 *   param of the shape `_name`, replace EVar("name") occurrences in the body
 *   with EVar("_name").
 */
class ChangesetBodyAlignToParamTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "changeset"):
                    var map = buildUnderscoreMap(args);
                    var newBody = rewriteBody(body, map);
                    makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2) if (name2 == "changeset"):
                    var map2 = buildUnderscoreMap(args2);
                    var newBody2 = rewriteBody(body2, map2);
                    makeASTWithMeta(EDefp(name2, args2, guards2, newBody2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function buildUnderscoreMap(args:Array<EPattern>):Map<String,String> {
        var m = new Map<String,String>();
        if (args == null) return m;
        for (a in args) switch (a) {
            case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
                m.set(nm.substr(1), nm);
            default:
        }
        return m;
    }

    static function rewriteBody(body: ElixirAST, rename: Map<String,String>): ElixirAST {
        if (!rename.keys().hasNext()) return body;
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (rename.exists(v)):
                    makeASTWithMeta(EVar(rename.get(v)), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }
}

#end

