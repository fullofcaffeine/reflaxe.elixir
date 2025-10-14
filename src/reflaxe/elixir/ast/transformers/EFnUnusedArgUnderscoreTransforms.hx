package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * EFnUnusedArgUnderscoreTransforms
 *
 * WHAT
 * - Underscore anonymous function argument binders that are not referenced in
 *   the function body. Applies to single-arg and two-arg (reduce) functions.
 *
 * WHY
 * - Prevents Elixir warnings about unused variables in anonymous functions
 *   emitted for Enum.each/map/reduce patterns. Keeps output idiomatic.
 *
 * HOW
 * - For each EFn clause, detect simple PVar/PAlias arg binders; if a binder is
 *   not used per VariableUsageCollector.usedInFunctionScope(body, name), rename
 *   it to `_name` (if not already underscored). Body rewrite is not needed as
 *   unused binders have no references.
 *
 * EXAMPLES
 * Before:
 *   Enum.each(xs, fn elem -> IO.puts("done") end)
 * After:
 *   Enum.each(xs, fn _elem -> IO.puts("done") end)
 */
class EFnUnusedArgUnderscoreTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var newArgs:Array<EPattern> = [];
                        var i = 0;
                        for (a in cl.args) {
                            switch (a) {
                                case PVar(name):
                                    var used = VariableUsageCollector.usedInFunctionScope(cl.body, name);
                                    var newName = (!used && name != null && (name.length == 0 || name.charAt(0) != '_')) ? ('_' + name) : name;
                                    newArgs.push(PVar(newName));
                                case PAlias(name, pat):
                                    var used2 = VariableUsageCollector.usedInFunctionScope(cl.body, name);
                                    var newName2 = (!used2 && name != null && (name.length == 0 || name.charAt(0) != '_')) ? ('_' + name) : name;
                                    newArgs.push(PAlias(newName2, pat));
                                default:
                                    newArgs.push(a);
                            }
                            i++;
                        }
                        newClauses.push({args: newArgs, guard: cl.guard, body: cl.body});
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end

