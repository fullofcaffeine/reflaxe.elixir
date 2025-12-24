package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * HandleEventLocalUnusedUnderscoreTransforms
 *
 * WHAT
 * - In `handle_event/3` functions, underscore local binders like
 *   `name = Map.get(params, ...)` when `name` is not referenced later
 *   in the same function body.
 *
 * WHY
 * - Shape-based cleanup to silence warnings such as
 *   "variable \"sort_by\" is unused" without altering behavior.
 *   The extractor statement remains, but the binder is renamed to `_name`.
 *
 * HOW
 * - Detect EDef/EDefp with name `handle_event` and 3 args.
 * - For EBlock body, scan statements; when a statement is an assignment to
 *   a PVar binder and that binder is not referenced in subsequent statements,
 *   rewrite the binder to `_binder`.
 */
class HandleEventLocalUnusedUnderscoreTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "handle_event" && args != null && args.length == 3):
                    var rewrittenBody = underscoreUnusedLocals(body);
                    makeASTWithMeta(EDef(name, args, guards, rewrittenBody), n.metadata, n.pos);
                case EDefp(name, args, guards, body) if (name == "handle_event" && args != null && args.length == 3):
                    var rewrittenBody = underscoreUnusedLocals(body);
                    makeASTWithMeta(EDefp(name, args, guards, rewrittenBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function underscoreUnusedLocals(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length) {
                    var stmt = stmts[i];
                    var rewrittenStmt = switch (stmt.def) {
                        case EMatch(PVar(binder), rhs):
                            if (canUnderscoreBinder(binder) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binder)) makeASTWithMeta(EMatch(PVar('_' + binder), rhs), stmt.metadata, stmt.pos) else stmt;
                        case EBinary(Match, left, right):
                            switch (left.def) {
                                case EVar(binderName) if (canUnderscoreBinder(binderName) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binderName)):
                                    makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + binderName)), right), stmt.metadata, stmt.pos);
                                default: stmt;
                            }
                        case ECase(expr, clauses):
                            var newClauses = [];
                            for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: underscoreUnusedLocals(cl.body) });
                            makeASTWithMeta(ECase(expr, newClauses), stmt.metadata, stmt.pos);
                        default:
                            stmt;
                    };
                    out.push(rewrittenStmt);
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            case EDo(statements):
                var useIndex = OptimizedVarUseAnalyzer.buildExact(statements);
                var out:Array<ElixirAST> = [];
                for (i in 0...statements.length) {
                    var stmt = statements[i];
                    var rewrittenStmt = switch (stmt.def) {
                        case EMatch(PVar(binder), rhs):
                            if (canUnderscoreBinder(binder) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binder)) makeASTWithMeta(EMatch(PVar('_' + binder), rhs), stmt.metadata, stmt.pos) else stmt;
                        case EBinary(Match, left, right):
                            switch (left.def) {
                                case EVar(binderName) if (canUnderscoreBinder(binderName) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binderName)):
                                    makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + binderName)), right), stmt.metadata, stmt.pos);
                                default: stmt;
                            }
                        case ECase(expr, clauses):
                            var newClauses = [];
                            for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: underscoreUnusedLocals(cl.body) });
                            makeASTWithMeta(ECase(expr, newClauses), stmt.metadata, stmt.pos);
                        default:
                            stmt;
                    };
                    out.push(rewrittenStmt);
                }
                makeASTWithMeta(EDo(out), body.metadata, body.pos);
            default:
                body;
        }
    }

    static inline function canUnderscoreBinder(name: String): Bool {
        return name != null && name.length > 0 && name != "_" && name.charAt(0) != '_';
    }
}

#end
