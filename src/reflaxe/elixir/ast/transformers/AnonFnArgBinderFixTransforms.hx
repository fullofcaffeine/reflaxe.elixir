package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * AnonFnArgBinderFixTransforms
 *
 * WHAT
 * - Fix anonymous functions that bind underscore-prefixed args (e.g., _t) but
 *   body references the non-underscored variant (t). Renames binder to the
 *   referenced name to avoid undefined variable and underscore-usage warnings.
 *
 * WHY
 * - Some LiveView helpers and Enum.reduce/concat callbacks end up with `_x`
 *   binders while the body refers to `x`, causing mismatches and warnings.
 *
 * HOW
 * - For each EFn clause, collect body var names. For any PVar name starting
 *   with '_' where the body references its non-underscore variant and not the
 *   underscored one, rename binder to non-underscore name.
 *
 * EXAMPLES
 * Before:
 *   Enum.map(items, fn _t -> do_something(t) end)
 * After:
 *   Enum.map(items, fn t -> do_something(t) end)
 */
class AnonFnArgBinderFixTransforms {
    /**
     * WHAT
     * - Normalize anonymous function argument binders to avoid underscore-usage warnings.
     * - If an underscore-prefixed binder (e.g. `_t`) is actually referenced in the body,
     *   rename the binder to its trimmed variant (e.g. `t`) and rewrite body references
     *   accordingly. If the body already refers to the trimmed variant, just rename the
     *   binder. If the binder is unused, leave it underscored.
     *
     * WHY
     * - Elixir warns when variables starting with an underscore are used after being set.
     *   Generated callbacks like `Enum.map/2`, `Enum.count/2` often use `_elem` while
     *   referencing it in the body, producing warnings. This pass removes such warnings
     *   without changing semantics.
     *
     * HOW
     * - For each EFn clause, collect used variable names in the body.
     * - For each argument pattern:
     *   - If it is `_name` and body uses `_name`: rename binder to `name` and rewrite
     *     body occurrences from `_name` to `name`.
     *   - Else if body uses `name`: rename binder to `name`.
     *   - Else: keep as-is (intentionally unused).
     */
    public static function fixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        // NOTE: Intentionally ignores ERaw/HEEx bodies because we cannot safely
                        // rename variables inside raw strings.
                        var used = VariableUsageCollector.referencedInFunctionScope(cl.body);
                        var renamePairs:Array<{from:String, to:String}> = [];

                        // First pass: decide arg renames
                        var newArgs:Array<EPattern> = [];
                        for (a in cl.args) {
                            switch (a) {
                                case PVar(name) if (name != null && name.length > 1 && name.charAt(0) == '_'):
                                    var trimmed = name.substr(1);
                                    if (used.exists(name)) {
                                        // Body refers to underscored name; schedule rewrite to trimmed
                                        renamePairs.push({from: name, to: trimmed});
                                        newArgs.push(PVar(trimmed));
                                    } else if (used.exists(trimmed)) {
                                        newArgs.push(PVar(trimmed));
                                    } else {
                                        newArgs.push(a);
                                    }
                                case PAlias(name, pat) if (name != null && name.length > 1 && name.charAt(0) == '_'):
                                    var trimmed2 = name.substr(1);
                                    if (used.exists(name)) {
                                        renamePairs.push({from: name, to: trimmed2});
                                        newArgs.push(PAlias(trimmed2, pat));
                                    } else if (used.exists(trimmed2)) {
                                        newArgs.push(PAlias(trimmed2, pat));
                                    } else {
                                        newArgs.push(a);
                                    }
                                default:
                                    newArgs.push(a);
                            }
                        }

                        // Second pass: apply body var renames when necessary
                        var newBody = cl.body;
                        for (rp in renamePairs) {
                            newBody = renameVarInNode(newBody, rp.from, rp.to);
                        }

                        newClauses.push({args: newArgs, guard: cl.guard, body: newBody});
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    // Apply a local variable rename inside an AST node (ERaw left untouched intentionally)
    static function renameVarInNode(node: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(name) if (name == from): makeASTWithMeta(EVar(to), n.metadata, n.pos);
                case ERaw(_): n; // avoid touching raw HEEx/code strings
                default: n;
            }
        });
    }
}

#end
