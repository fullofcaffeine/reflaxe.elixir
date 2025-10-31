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
                default:
                    n;
            }
        });
    }

    static function simplifyIfAssign(varName:String, expr:ElixirAST): ElixirAST {
        return switch (expr.def) {
            case EIf(cond, thenExpr, elseExpr):
                var newThen = (function() {
                    switch (thenExpr.def) {
                        // Exact match on the same binder name
                        case EMatch(PVar(inner), innerRhs) if (isEctoWhere(innerRhs)):
                            return rewriteInnerVar(innerRhs, inner, varName);
                        case EBinary(Match, {def: EVar(inner2)}, innerRhs2) if (isEctoWhere(innerRhs2)):
                            return rewriteInnerVar(innerRhs2, inner2, varName);
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
