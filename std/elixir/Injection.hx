package elixir;

import haxe.extern.Rest;

#if (elixir || reflaxe_runtime)
// Make the function globally available without import
using elixir.Injection;

/**
 * Global injection function for backward compatibility.
 * 
 * This provides the global `__elixir__` function that allows
 * `untyped __elixir__()` calls to parse correctly in Haxe.
 * 
 * **IMPORTANT**: This is for backward compatibility only.
 * New code should use `elixir.Syntax.code()` instead for type safety.
 * 
 * ## Migration Path
 * 
 * Old approach:
 * ```haxe
 * var result = untyped __elixir__("DateTime.utc_now()");
 * ```
 * 
 * New approach:
 * ```haxe
 * var result = elixir.Syntax.code("DateTime.utc_now()");
 * ```
 * 
 * @see elixir.Syntax - Type-safe alternative
 * @see documentation/ELIXIR_INJECTION_GUIDE.md - Complete migration guide
 */
class Injection {
    /**
     * Global injection function for Elixir code.
     * 
     * This function exists only to provide a valid identifier that Haxe
     * can parse. The actual injection processing is handled by Reflaxe
     * during compilation via the `targetCodeInjectionName` mechanism.
     * 
     * **DO NOT call this function directly** - it's only for enabling
     * syntax parsing. Use `elixir.Syntax.code()` instead.
     * 
     * @param code Elixir code string
     * @param args Optional arguments for interpolation
     * @return Dynamic (never actually called at runtime)
     */
    public static function __elixir__(code: String, args: Rest<Dynamic>): Dynamic {
        // This function should never be called at runtime.
        // It only exists to provide a valid identifier for Haxe parsing.
        // The actual injection is handled by Reflaxe's targetCodeInjectionName.
        throw "INTERNAL ERROR: __elixir__ function should never be called at runtime. Use elixir.Syntax.code() instead.";
    }
}
#end