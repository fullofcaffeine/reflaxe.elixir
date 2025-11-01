package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * DefParamUnusedUnderscoreGlobalSafeTransforms
 *
 * WHAT
 * - Globally underscore unused function parameters when it is provably safe:
 *   the parameter name is not referenced anywhere in the function body or its
 *   nested closures/ERaw strings.
 *
 * WHY
 * - Tests and idiomatic Elixir often prefer underscore-prefixed params when
 *   unused (e.g., _user, _attrs). This pass fixes minimal modules (like
 *   changeset helpers) without relying on Phoenix gating.
 */
class DefParamUnusedUnderscoreGlobalSafeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    // Do not underscore handle_event/3 second arg; reserved for Phoenix params
                    var newArgs = if (name == "handle_event" && args != null && args.length == 3) args else underscoreArgsIfUnused(args, body);
                    makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2):
                    var newArgs2 = if (name2 == "handle_event" && args2 != null && args2.length == 3) args2 else underscoreArgsIfUnused(args2, body2);
                    makeASTWithMeta(EDefp(name2, newArgs2, guards2, body2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function underscoreArgsIfUnused(args:Array<EPattern>, body:ElixirAST):Array<EPattern> {
        if (args == null) return args;
        return [for (a in args) underscoreIfUnused(a, body)];
    }

    static function underscoreIfUnused(p:EPattern, body:ElixirAST):EPattern {
        return switch (p) {
            case PVar(nm) if (nm != null && nm.length > 0 && nm.charAt(0) != '_' && !usedInBody(body, nm)):
                PVar('_' + nm);
            default:
                p;
        }
    }

    static function usedInBody(body:ElixirAST, name:String):Bool {
        if (name == null || name.length == 0) return false;
        if (VariableUsageCollector.usedInFunctionScope(body, name)) return true;
        // Basic ERaw scan as a conservative check
        var found = false;
        ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
            if (found || n == null || n.def == null) return n;
            switch (n.def) {
                case ERaw(code): if (code != null && code.indexOf(name) != -1) found = true;
                default:
            }
            return n;
        });
        return found;
    }
}

#end
