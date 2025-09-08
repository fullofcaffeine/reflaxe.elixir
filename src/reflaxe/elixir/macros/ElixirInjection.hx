package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ElixirInjection: Provides __elixir__ as a macro function
 * 
 * WHY: The Reflaxe injection mechanism doesn't work with `extern inline` because
 * those functions are typed before Reflaxe can inject the __elixir__ identifier.
 * By providing __elixir__ as a macro function, it exists during typing.
 * 
 * WHAT: A macro function that returns an AST node that Reflaxe will recognize
 * as target code injection during compilation.
 * 
 * HOW: Returns a TIdent("__elixir__") node wrapped in the expected structure
 * that TargetCodeInjection.hx will recognize.
 */
class ElixirInjection {
    /**
     * Macro implementation of __elixir__ that exists during typing phase
     */
    public static macro function __elixir__(code: String, args: Array<Expr>): Expr {
        // Create the AST that Reflaxe expects for injection
        var callArgs = [macro $v{code}].concat(args);
        
        // Return untyped call to __elixir__ that will be processed by Reflaxe
        return macro untyped __elixir__($a{callArgs});
    }
}
#end