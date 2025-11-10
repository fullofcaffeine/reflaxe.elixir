package ecto;

#if macro
import haxe.macro.Expr;
#end

/**
 * Instance-style extension macros for TypedQuery, enabling natural chaining
 * query.where(u -> ...)
 */
class TypedQueryInstanceMacros {
    public static macro function where(ethis:Expr, predicate:Expr):Expr {
        return reflaxe.elixir.macros.TypedQueryLambda.buildWhereExpr(ethis, predicate);
    }
}

