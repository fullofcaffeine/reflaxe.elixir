package ecto;

#if macro
import haxe.macro.Expr;
#end

/**
 * Macro bridge for TypedQuery instance methods.
 * 
 * Provides stable call sites for macros from instance inline methods,
 * avoiding reliance on @:using resolution in user code.
 */
class TypedQueryMacrosBridge {
    public static macro function where(ethis:Expr, predicate:Expr):Expr {
        return reflaxe.elixir.macros.TypedQueryLambda.buildWhereExpr(ethis, predicate);
    }
}
