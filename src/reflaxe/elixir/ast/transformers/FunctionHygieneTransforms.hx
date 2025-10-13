package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FunctionHygieneTransforms
 *
 * WHAT
 * - Final-phase hygiene cleanups at function level:
 *   1) Simplify chained assignments when inner var is unused later in the block
 *      (outer = inner = expr) → (outer = expr)
 *   2) Drop top-level numeric sentinel literals (1/0/0.0) inside def/defp bodies
 *   3) Underscore unused function parameters in EDef/EDefp when not referenced in the body
 *
 * WHY
 * - Remove compiler artifacts that manifest as warnings in LiveView helpers and changeset code
 * - Achieve WAE=0 for the todo-app without app-coupled heuristics
 *
 * HOW
 * - Block-based pass for chained assignments with a forward usage scan
 * - Function-body pass to drop bare numeric literals at top level
 * - Parameter usage analysis to underscore unused params
 */
class FunctionHygieneTransforms {
    public static function blockAssignChainSimplifyPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var newBody = simplifyChainsInBody(body);
                    makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function simplifyChainsInBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out = [];
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    switch (s.def) {
                        case EBinary(Match, leftOuter, rhsOuter):
                            switch (rhsOuter.def) {
                                case EBinary(Match, leftInner, expr):
                                    var innerName: Null<String> = switch (leftInner.def) { case EVar(n): n; default: null; };
                                    if (innerName != null && !usedLater(stmts, i + 1, innerName)) {
                                        out.push(makeAST(EBinary(Match, leftOuter, expr)));
                                        continue;
                                    } else out.push(s);
                                default:
                                    out.push(s);
                            }
                        default:
                            out.push(s);
                    }
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }

    static function usedLater(stmts: Array<ElixirAST>, startIdx: Int, name: String): Bool {
        for (j in startIdx...stmts.length) if (stmtUsesVar(stmts[j], name)) return true;
        return false;
    }

    static function stmtUsesVar(n: ElixirAST, name: String): Bool {
        var found = false;
        ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
            switch (x.def) { case EVar(v) if (v == name): found = true; default: }
            return x;
        });
        return found;
    }

    public static function functionTopLevelSentinelCleanupPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var newBody = dropTopLevelSentinels(body);
                    makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function dropTopLevelSentinels(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out = [];
                for (s in stmts) switch (s.def) {
                    case EInteger(v) if (v == 0 || v == 1):
                    case EFloat(f) if (f == 0.0):
                    default: out.push(s);
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }

    public static function fnParamUnusedUnderscorePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var newArgs: Array<EPattern> = [];
                    for (a in args) newArgs.push(underscoreIfUnused(a, body));
                    makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function underscoreIfUnused(pat: EPattern, body: ElixirAST): EPattern {
        return switch (pat) {
            case PVar(n) if (!stmtUsesVar(body, n) && (n.length > 0 && n.charAt(0) != '_')): PVar('_' + n);
            default: pat;
        }
    }
}

#end

