package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * TopLevelNilAssignDiscardTransforms
 *
 * WHAT
 * - Discard top-level assignments to nil in function bodies when the variable
 *   is not used later: `var = nil` → `_ = nil` to eliminate unused-variable warnings.
 */
class TopLevelNilAssignDiscardTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length) {
                    var stmt = stmts[i];
                    switch (stmt.def) {
                        case EBinary(Match, left, right) if (isNil(right) && isVar(left)):
                            var binderName = getVar(left);
                            if (!OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binderName)) out.push(makeASTWithMeta(EMatch(PWildcard, right), stmt.metadata, stmt.pos)) else out.push(stmt);
                        case EMatch(pat, right) if (isNil(right) && isPVar(pat)):
                            var binderName = getPVar(pat);
                            if (!OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binderName)) out.push(makeASTWithMeta(EMatch(PWildcard, right), stmt.metadata, stmt.pos)) else out.push(stmt);
                        default:
                            out.push(stmt);
                    }
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }

    static inline function isNil(e: ElixirAST):Bool {
        return switch (e.def) { case ENil: true; default: false; };
    }
    static inline function isVar(e: ElixirAST):Bool {
        return switch (e.def) { case EVar(_): true; default: false; };
    }
    static inline function isPVar(p: EPattern):Bool {
        return switch (p) { case PVar(_): true; default: false; };
    }
    static inline function getVar(e: ElixirAST):String {
        return switch (e.def) { case EVar(n): n; default: null; };
    }
    static inline function getPVar(p: EPattern):String {
        return switch (p) { case PVar(n): n; default: null; };
    }
}

#end
