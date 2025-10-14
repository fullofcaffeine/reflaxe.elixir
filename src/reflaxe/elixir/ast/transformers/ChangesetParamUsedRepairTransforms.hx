package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * ChangesetParamUsedRepairTransforms
 *
 * WHAT
 * - For functions named `changeset`, if a parameter is underscored (e.g., `_user`)
 *   but the body uses the base name (`user`), rename the parameter back to the
 *   base name to ensure binder/body alignment.
 *
 * WHY
 * - Safe underscore passes or stubs may underscore parameters that are actually
 *   referenced in the body (e.g., Ecto.Changeset.change(user, attrs)). This causes
 *   undefined-variable errors in Elixir. This pass repairs the parameter names in
 *   a shape-driven, target-agnostic way.
 *
 * HOW
 * - Match EDef/EDefp with name == "changeset". For each PVar arg that starts with
 *   an underscore, check if body references the base name via VariableUsageCollector.
 *   If yes, replace the PVar with the base name. No body rewrite is needed because
 *   references already use the base names.
 */
class ChangesetParamUsedRepairTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "changeset"):
                    makeASTWithMeta(EDef(name, repair(args, body), guards, body), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2) if (name2 == "changeset"):
                    makeASTWithMeta(EDefp(name2, repair(args2, body2), guards2, body2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function repair(args: Array<EPattern>, body: ElixirAST): Array<EPattern> {
        if (args == null) return args;
        return [for (a in args) switch (a) {
            case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
                var base = nm.substr(1);
                if (VariableUsageCollector.usedInFunctionScope(body, base)) PVar(base) else a;
            default:
                a;
        }];
    }
}

#end

