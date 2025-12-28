package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * UnusedLocalAssignUnderscoreFinalTransforms
 *
 * WHAT
 * - In function bodies, find simple local assignments like `g = expr` where
 *   the binder name is not referenced later in the surrounding block and
 *   rename the binder to `_g` to silence compiler warnings.
 *
 * WHY
 * - The compiler intentionally materializes temporary binders (e.g., for
 *   side-effecting expressions) but Elixir warns when those binders are
 *   unused. Renaming to an underscored binder communicates intent without
 *   altering semantics.
 *
 * HOW
 * - Walk blocks; for any top-level `EMatch(PVar(name), rhs)` or
 *   `EBinary(Match, EVar(name), rhs)`, check if `name` is used in any
 *   subsequent sibling statement. If not, rename pattern to `_name`.
 * - Use a suffix usage index (O(n)) so `usedLater` checks are O(1), avoiding
 *   quadratic behavior on large generated functions.
 * - Conservative: does not attempt cross-block dataflow; only same-level
 *   block siblings are considered.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class UnusedLocalAssignUnderscoreFinalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    makeASTWithMeta(EBlock(processStatements(stmts)), n.metadata, n.pos);
                case EDo(stmts):
                    makeASTWithMeta(EDo(processStatements(stmts)), n.metadata, n.pos);
                case EFn(clauses):
                    // Explicitly process EFn clause bodies for dead store removal
                    var processedClauses = [for (clause in clauses) {
                        var processedBody = switch (clause.body.def) {
                            case EBlock(bodyStmts):
                                makeASTWithMeta(EBlock(processStatements(bodyStmts)), clause.body.metadata, clause.body.pos);
                            case EDo(bodyStmts2):
                                makeASTWithMeta(EDo(processStatements(bodyStmts2)), clause.body.metadata, clause.body.pos);
                            default:
                                clause.body;
                        };
                        {
                            args: clause.args,
                            guard: clause.guard,
                            body: processedBody
                        };
                    }];
                    makeASTWithMeta(EFn(processedClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function processStatements(stmts: Array<ElixirAST>): Array<ElixirAST> {
        if (stmts == null) return stmts;
        var usage = OptimizedVarUseAnalyzer.buildExact(stmts);
        var out:Array<ElixirAST> = [];

        for (i in 0...stmts.length) {
            var s = stmts[i];

            inline function canRename(name: String): Bool {
                if (name == null) return false;
                // Never rename core binders
                if (name == "socket" || name == "params" || name == "assigns") return false;
                // Rename only clearly unused compiler temps (g, this1, etc.)
                return name == "g" || StringTools.startsWith(name, "this");
            }

            var renamed = switch (s.def) {
                case EMatch(PVar(vn), rhs) if (canRename(vn) && !OptimizedVarUseAnalyzer.usedLater(usage, i + 1, vn)):
                    makeASTWithMeta(EMatch(PVar('_' + vn), rhs), s.metadata, s.pos);
                case EBinary(Match, {def: EVar(v)}, rhs) if (canRename(v) && !OptimizedVarUseAnalyzer.usedLater(usage, i + 1, v)):
                    makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar('_' + v), null, s.pos), rhs), s.metadata, s.pos);
                default:
                    s;
            };

            out.push(renamed);
        }

        return out;
    }

    // Extract the variable name from an assignment statement
    static function getAssignedVarName(s: ElixirAST): Null<String> {
        if (s == null || s.def == null) return null;
        return switch (s.def) {
            case EMatch(PVar(name), _): name;
            case EBinary(Match, {def: EVar(name)}, _): name;
            default: null;
        };
    }
}

#end
