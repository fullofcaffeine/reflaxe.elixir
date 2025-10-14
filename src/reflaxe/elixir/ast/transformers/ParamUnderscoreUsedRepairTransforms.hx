package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * ParamUnderscoreUsedRepairTransforms
 *
 * WHAT
 * - If a function parameter is underscored (e.g., `_name`) but the body uses
 *   `name`, rename the parameter back to `name`.
 *
 * WHY
 * - Some safe underscore passes may incorrectly underscore parameters later used
 *   in the body (e.g., generated helper modules). This repair ensures correctness
 *   and aligns snapshots that expect non-underscored names when used.
 */
class ParamUnderscoreUsedRepairTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, repair(args, body), guards, body), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2):
                    makeASTWithMeta(EDefp(name2, repair(args2, body2), guards2, body2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function repair(args:Array<EPattern>, body:ElixirAST):Array<EPattern> {
        if (args == null) return args;
        return [for (a in args) switch (a) {
            case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_' && VariableUsageCollector.usedInFunctionScope(body, nm.substr(1))):
                PVar(nm.substr(1));
            default: a;
        }];
    }
}

#end

