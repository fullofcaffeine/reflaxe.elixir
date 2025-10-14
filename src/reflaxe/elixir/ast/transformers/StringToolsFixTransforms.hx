package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StringToolsFixTransforms
 *
 * WHAT
 * - Late binder fix for StringTools.is_space/2 to ensure parameters are `s, pos`.
 *
 * WHY
 * - Earlier hygiene passes may have underscored binders via shared context mapping
 *   before native rewrite runs; enforce canonical names at the end.
 *
 * HOW
 * - For module StringTools, rename EDef is_space params to PVar("s"), PVar("pos").
 *
 * EXAMPLES
 * Elixir (before):
 *   def is_space(_s, _pos), do: ...
 * Elixir (after):
 *   def is_space(s, pos), do: ...
 */
class StringToolsFixTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name == "StringTools"):
                    var newBody = [];
                    for (b in body) newBody.push(fixIsSpace(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name == "StringTools"):
                    makeASTWithMeta(EDefmodule(name, fixIsSpace(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function fixIsSpace(n: ElixirAST): ElixirAST {
        return switch (n.def) {
            case EDef(fnName, params, guards, body) if (fnName == "is_space" && params.length == 2):
                makeASTWithMeta(EDef(fnName, [PVar("s"), PVar("pos")], guards, body), n.metadata, n.pos);
            default:
                n;
        }
    }
}

#end
