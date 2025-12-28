package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnForbiddenBinderRenameTransforms
 *
 * WHAT
 * - Renames anonymous function binders that collide with frequently used
 *   Kernel/function names (e.g., "elem") to neutral names and updates all
 *   body references accordingly.
 *
 * WHY
 * - Binders like `elem` can trigger confusing warnings and readability issues
 *   (shadowing Kernel.elem/2). Renaming them avoids warnings like
 *   "variable \"elem\" is unused (there is a variable with the same name in the context)".
 *
 * HOW
 * - For every EFn clause, if an argument is PVar("elem"), rename it to
 *   "entry" and replace all EVar("elem") references in the clause body with
 *   EVar("entry"). Additional names can be added to the mapping as needed.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class EFnForbiddenBinderRenameTransforms {
    static inline function replacementFor(name:String):Null<String> {
        return switch (name) {
            case "elem": "entry";
            default: null;
        }
    }

    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var renamedArgs:Array<EPattern> = [];
                        var renameMap = new Map<String,String>();
                        if (cl.args != null) {
                            for (a in cl.args) switch (a) {
                                case PVar(nm):
                                    var repl = replacementFor(nm);
                                    if (repl != null) {
                                        renameMap.set(nm, repl);
                                        renamedArgs.push(PVar(repl));
                                    } else {
                                        renamedArgs.push(a);
                                    }
                                default:
                                    renamedArgs.push(a);
                            }
                        }
                        var newBody = if (Lambda.count(renameMap) == 0) cl.body else renameVars(cl.body, renameMap);
                        newClauses.push({ args: renamedArgs, guard: cl.guard, body: newBody });
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function renameVars(body: ElixirAST, rename: Map<String,String>): ElixirAST {
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

