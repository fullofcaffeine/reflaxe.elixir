package elixir;

import haxe.extern.Rest;

/**
 * Generate Elixir syntax not directly supported by Haxe.
 * Use only at low-level when specific target-specific code-generation is required.
 * 
 * This follows the js.Syntax pattern from Haxe core, providing type-safe injection
 * methods for Elixir code generation. 
 * 
 * ## API Design Philosophy
 * 
 * Following js.Syntax design principles:
 * - `code()` and `plainCode()` for general injection
 * - No convenience methods for language constructs (use code() instead)
 * - Type-safe alternative to `untyped __elixir__()`
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Basic code injection  
 * var result = elixir.Syntax.code("DateTime.utc_now()");
 * 
 * // Code injection with parameters
 * var formatted = elixir.Syntax.code("String.slice({0}, {1}, {2})", str, start, length);
 * 
 * // Non-interpolated injection
 * var atom = elixir.Syntax.plainCode(":ok");
 * 
 * // Any Elixir construct via code()
 * var tuple = elixir.Syntax.code("{{0}, {1}}", "ok", result);
 * var atom = elixir.Syntax.code(":{0}", "success");  
 * var keyword = elixir.Syntax.code("[{0}: {1}]", "name", "value");
 * ```
 * 
 * @see js.Syntax - Reference pattern from Haxe core
 * @see documentation/REFLAXE_SYNTAX_INJECTION_RESEARCH.md - Complete research analysis
 */
// TODO: Convert to proper extern class with @:reflaxeElixir annotations
// See: documentation/EXTERN_CLASS_SYNTAX_INJECTION.md
@:noClosure  
class Syntax {
    /**
     * Inject `code` directly into generated Elixir source.
     * 
     * `code` must be a string constant.
     * 
     * Additional `args` are supported to provide code interpolation, for example:
     * ```haxe
     * Syntax.code("Map.put({0}, {1}, {2})", map, key, value);
     * ```
     * will generate
     * ```elixir
     * Map.put(map, key, value)
     * ```
     * 
     * Emits a compilation error if the count of `args` does not match the count of placeholders in `code`.
     * 
     * @param code Elixir code string with {N} placeholders for interpolation
     * @param args Arguments to interpolate into placeholders  
     * @return Dynamic result (typed as needed by context)
     */
    public static function code(code: String, args: Rest<Dynamic>): Dynamic {
        throw "elixir.Syntax.code() should be handled by the compiler, not executed at runtime";
    }
    
    /**
     * Inject `code` directly into generated Elixir source.
     * The same as `elixir.Syntax.code` except this one does not provide code interpolation.
     * 
     * @param code Raw Elixir code string without interpolation
     * @return Dynamic result (typed as needed by context)
     */
    public static function plainCode(code: String): Dynamic {
        throw "elixir.Syntax.plainCode() should be handled by the compiler, not executed at runtime";
    }
}