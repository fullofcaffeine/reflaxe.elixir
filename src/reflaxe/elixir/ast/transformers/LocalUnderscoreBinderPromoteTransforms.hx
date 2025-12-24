package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * LocalUnderscoreBinderPromoteTransforms
 *
 * WHAT
 * - Promote local binders from _name to name when subsequent code references
 *   the non-underscored variant and does not reference the underscored one.
 *
 * WHY
 * - Some hygiene passes underscore local assignments to silence warnings, but
 *   later code may correctly reference the base name (e.g., query). Promote
 *   the binder to match usage and avoid undefined variable errors.
 *
 * HOW
 * - Walk EBlock statements; for each EMatch(PVar("_name"), rhs) at index i,
 *   scan statements (i+1..end) for references to "name" and "_name". If name
 *   is referenced and _name is not, rewrite binder to PVar("name").
 *
 * EXAMPLES
 * Before:
 *   _query = String.downcase(search_query)
 *   Enum.filter(todos, fn t -> match?(... query ...) end)
 * After:
 *   query = String.downcase(search_query)
 *   Enum.filter(todos, fn t -> match?(... query ...) end)
 */
class LocalUnderscoreBinderPromoteTransforms {
    public static function promotePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
                    var out:Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        switch (s.def) {
                            case EMatch(PVar(name), rhs) if (name != null && name.length > 1 && name.charAt(0) == '_'):
                                var base = name.substr(1);
                                var usedBase = OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, base);
                                var usedUnderscore = OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, name);
                                if (usedBase && !usedUnderscore) {
                                    out.push(makeASTWithMeta(EMatch(PVar(base), rhs), s.metadata, s.pos));
                                } else {
                                    out.push(s);
                                }
                            case EBinary(Match, left, rhs):
                                // Handle plain assignment: _name = rhs
                                switch (left.def) {
                                    case EVar(binderName) if (binderName != null && binderName.length > 1 && binderName.charAt(0) == '_'):
                                        var baseName = binderName.substr(1);
                                        var baseUsedLater = OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, baseName);
                                        var underscoreUsedLater = OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binderName);
                                        if (baseUsedLater && !underscoreUsedLater) {
                                            out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(baseName), left.metadata, left.pos), rhs), s.metadata, s.pos));
                                        } else {
                                            out.push(s);
                                        }
                                    default:
                                        out.push(s);
                                }
                            default:
                                out.push(s);
                        }
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                case EDo(bodyStmts):
                    // Treat do/end blocks similarly to EBlock
                    var block = makeAST(EBlock(bodyStmts));
                    var transformed = promotePass(block);
                    // Extract back inner statements if still a block
                    switch (transformed.def) {
                        case EBlock(xs): makeASTWithMeta(EDo(xs), n.metadata, n.pos);
                        default: n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
