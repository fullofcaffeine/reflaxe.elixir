package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * ControllerLocalUnusedUnderscoreTransforms
 *
 * WHAT
 * - In Phoenix Controller modules, underscore local assignment binders that are
 *   not referenced later in the same function body. This silences warnings like
 *   "variable \"data\" is unused", without changing behavior.
 *
 * SCOPE
 * - Modules detected as Controllers by metadata (AnnotationTransforms) or by
 *   module name ending in "Controller" under Web namespace.
 */
class ControllerLocalUnusedUnderscoreTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (isControllerModule(n, name)):
                    var out:Array<ElixirAST> = [];
                    for (b in body) out.push(applyToDefs(b));
                    makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
                case EDefmodule(modName, doBlock) if (isControllerDoBlock(n, doBlock)):
                    makeASTWithMeta(EDefmodule(modName, applyToDefs(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function applyToDefs(node:ElixirAST):ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, underscoreUnused(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, underscoreUnused(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function underscoreUnused(body:ElixirAST):ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length) {
                    var stmt = stmts[i];
                    var rewrittenStmt = switch (stmt.def) {
                        case EMatch(PVar(b), rhs) if (canUnderscoreBinder(b) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, b)):
                            makeASTWithMeta(EMatch(PVar('_' + b), rhs), stmt.metadata, stmt.pos);
                        case EBinary(Match, left, right):
                            switch (left.def) {
                                case EVar(binderName) if (canUnderscoreBinder(binderName) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binderName)):
                                    makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + binderName)), right), stmt.metadata, stmt.pos);
                                default: stmt;
                            }
                        case ECase(expr, clauses):
                            var newClauses = [];
                            for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: underscoreUnused(cl.body) });
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
                        case EMatch(PVar(b), rhs) if (canUnderscoreBinder(b) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, b)):
                            makeASTWithMeta(EMatch(PVar('_' + b), rhs), stmt.metadata, stmt.pos);
                        case EBinary(Match, left, right):
                            switch (left.def) {
                                case EVar(binderName) if (canUnderscoreBinder(binderName) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binderName)):
                                    makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + binderName)), right), stmt.metadata, stmt.pos);
                                default: stmt;
                            }
                        case ECase(expr, clauses):
                            var newClauses = [];
                            for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: underscoreUnused(cl.body) });
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

    static inline function isControllerModule(node:ElixirAST, name:String):Bool {
        if (node.metadata?.isPhoenixWeb == true && node.metadata?.phoenixContext == PhoenixContext.Controller) return true;
        return name != null && name.indexOf("Web.") >= 0 && StringTools.endsWith(name, "Controller");
    }

    static inline function isControllerDoBlock(node:ElixirAST, doBlock:ElixirAST):Bool {
        // Rely on bubbled metadata when available
        return node.metadata?.phoenixContext == PhoenixContext.Controller;
    }
}

#end
