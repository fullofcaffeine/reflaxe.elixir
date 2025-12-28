package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnScopedUnderscoreRefCleanup (Final)
 *
 * WHAT
 * - For each anonymous function (EFn), rewrite body variable references of the form
 *   _name to name when a corresponding binder (name) exists in the clause args.
 *
 * WHY
 * - Late-stage rewrites may leave body references with underscored variants even when
 *   the declared binder is non-underscored. This produces undefined vars or hygiene warnings.
 *
 * HOW
 * - This is a shallow transform: it only handles EFn nodes. For each clause, collect binder
 *   names (PVar/PAlias), then run a body rename that replaces EVar("_" + binder) with EVar(binder).
 * - ERaw nodes are untouched.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class EFnScopedUnderscoreRefCleanup {
    public static function cleanupPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var binders = collectBinderNames(cl.args);
                        var newBody = renameUnderscoredRefs(cl.body, binders);
                        newClauses.push({args: cl.args, guard: cl.guard, body: newBody});
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function collectBinderNames(args:Array<EPattern>):Array<String> {
        var names:Array<String> = [];
        for (a in args) switch (a) {
            case PVar(name) if (name != null && name.length > 0): names.push(name);
            case PAlias(name, _): if (name != null && name.length > 0) names.push(name);
            case PTuple(targs): for (x in collectBinderNames(targs)) names.push(x);
            case PList(largs): for (x in collectBinderNames(largs)) names.push(x);
            case PCons(h, t):
                for (x in collectBinderNames([h])) names.push(x);
                for (x in collectBinderNames([t])) names.push(x);
            case PMap(pairs): for (p in pairs) for (x in collectBinderNames([p.value])) names.push(x);
            case PStruct(_, fields): for (f in fields) for (x in collectBinderNames([f.value])) names.push(x);
            default:
        }
        return names;
    }

    static function renameUnderscoredRefs(body: ElixirAST, binders:Array<String>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(name) if (name != null && name.length > 1 && name.charAt(0) == '_'):
                    var trimmed = name.substr(1);
                    if (contains(binders, trimmed)) makeASTWithMeta(EVar(trimmed), n.metadata, n.pos) else n;
                case ERaw(_): n;
                default: n;
            }
        });
    }

    static function contains(arr:Array<String>, s:String):Bool {
        for (x in arr) if (x == s) return true;
        return false;
    }
}

#end
