package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoQueryIfAssignSimplifyTransforms
 *
 * WHAT
 * - Simplify `var = if cond do var = Ecto.Query.where(var, ...) else var end`
 *   into `var = if cond do Ecto.Query.where(var, ...) else var end`.
 *
 * WHY
 * - Elixir warns that the inner `var = ...` binding inside the if-branch is unused.
 *   This shape commonly appears in compiler-generated code that incrementally
 *   refines a query variable.
 */
class EctoQueryIfAssignSimplifyTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EMatch(PVar(varName), rhs):
                    var simplified = simplifyIfAssign(varName, rhs);
                    if (simplified != null) makeASTWithMeta(EMatch(PVar(varName), simplified), n.metadata, n.pos) else n;
                case EBinary(Match, {def: EVar(varName2)}, rhs2):
                    var simplified2 = simplifyIfAssign(varName2, rhs2);
                    if (simplified2 != null) makeASTWithMeta(EBinary(Match, makeAST(EVar(varName2)), simplified2), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function simplifyIfAssign(varName:String, expr:ElixirAST): ElixirAST {
        return switch (expr.def) {
            case EIf(cond, thenExpr, elseExpr):
                // Helper to inspect a candidate statement and rewrite accordingly
                function rewriteStmt(stmt:ElixirAST):Null<ElixirAST> {
                    return switch (stmt.def) {
                        case EMatch(PVar(inner), innerRhs) if (isEctoWhere(innerRhs)):
                            rewriteInnerVar(innerRhs, inner, varName);
                        case EBinary(Match, {def: EVar(inner2)}, innerRhs2) if (isEctoWhere(innerRhs2)):
                            rewriteInnerVar(innerRhs2, inner2, varName);
                        case EMatch(PVar(innerU), innerRhsU) if (isEctoWhere(innerRhsU) && innerU == varName):
                            makeAST(EBinary(Match, makeAST(EVar('_' + innerU)), innerRhsU));
                        case EBinary(Match, {def: EVar(innerU2)}, innerRhsU2) if (isEctoWhere(innerRhsU2) && innerU2 == varName):
                            makeAST(EBinary(Match, makeAST(EVar('_' + innerU2)), innerRhsU2));
                        default: null;
                    }
                }
                var newThen = (function() {
                    switch (thenExpr.def) {
                        // Direct assignment in the then-expression
                        case EMatch(_, _) | EBinary(Match, _, _):
                            var r = rewriteStmt(thenExpr);
                            return r != null ? r : thenExpr;
                        // Then is a block: attempt to rewrite last statement if it matches
                        case EBlock(ss) if (ss.length > 0):
                            var last = ss[ss.length - 1];
                            var rewritten = rewriteStmt(last);
                            if (rewritten != null) {
                                var prefix = ss.copy();
                                prefix.pop();
                                return makeAST(EBlock(prefix.concat([rewritten])));
                            } else return thenExpr;
                        case EDo(ss2) if (ss2.length > 0):
                            var last2 = ss2[ss2.length - 1];
                            var rewritten2 = rewriteStmt(last2);
                            if (rewritten2 != null) {
                                var prefix2 = ss2.copy();
                                prefix2.pop();
                                return makeAST(EDo(prefix2.concat([rewritten2])));
                            } else return thenExpr;
                        default:
                            return thenExpr;
                    }
                })();
                makeAST( EIf(cond, newThen, elseExpr) );
            default:
                null;
        }
    }

    static function isEctoWhere(expr:ElixirAST): Bool {
        return switch (expr.def) {
            case ERemoteCall({def: EVar(m)}, fn, _) if (m == "Ecto.Query" && fn == "where"): true;
            default: false;
        }
    }

    static function rewriteInnerVar(expr: ElixirAST, from:String, to:String): ElixirAST {
        if (from == to) return expr;
        return ElixirASTTransformer.transformNode(expr, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (v == from): makeASTWithMeta(EVar(to), n.metadata, n.pos);
                default: n;
            }
        });
    }
}

#end
