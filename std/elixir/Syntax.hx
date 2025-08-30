package elixir;

import haxe.extern.Rest;

#if (elixir || reflaxe_runtime)
/**
 * Type-safe Elixir code injection API
 * 
 * This provides the modern, type-safe way to inject Elixir code into your Haxe programs.
 * Similar to `haxe.Syntax.code()` for other targets.
 * 
 * ## Usage
 * 
 * ```haxe
 * import elixir.Syntax;
 * 
 * // Inject pure Elixir code
 * var now = Syntax.code("DateTime.utc_now()");
 * 
 * // Inject code with parameters (using {0}, {1}, etc as placeholders)
 * var name = "World";
 * Syntax.code("IO.puts(\"Hello, {0}!\")", name);
 * 
 * // Use in expressions
 * var result = Syntax.code("Enum.map({0}, {1})", list, fn);
 * ```
 * 
 * ## Benefits over `untyped __elixir__()`
 * 
 * - **Type Safety**: Import required, preventing accidental usage
 * - **Modern API**: Follows Haxe's standard `Syntax.code()` pattern
 * - **Better IDE Support**: Autocomplete and documentation
 * - **Future-Proof**: The recommended approach going forward
 * 
 * @see elixir.Injection - Legacy __elixir__() support
 * @see documentation/ELIXIR_INJECTION_GUIDE.md - Complete injection guide
 */
extern class Syntax {
    /**
     * Inject Elixir code directly into the compiled output.
     * 
     * The code string is injected as-is, with placeholders {0}, {1}, etc
     * replaced by the compiled versions of the provided arguments.
     * 
     * ## Examples
     * 
     * ```haxe
     * // Simple injection
     * Syntax.code("IO.inspect(\"Debug output\")");
     * 
     * // With parameters
     * var items = [1, 2, 3];
     * var doubled = Syntax.code("Enum.map({0}, fn x -> x * 2 end)", items);
     * 
     * // Complex expressions
     * var result = Syntax.code(
     *     "case {0} do {:ok, val} -> val; {:error, _} -> {1} end", 
     *     operation(), 
     *     defaultValue
     * );
     * ```
     * 
     * @param code The Elixir code to inject, with {N} placeholders for arguments
     * @param args Values to substitute for {0}, {1}, etc in the code string
     * @return The result of the injected code (type depends on the code)
     */
    public static function code(code: String, args: Rest<Dynamic>): Dynamic;
    
    /**
     * Create an Elixir atom.
     * 
     * ```haxe
     * var status = Syntax.atom("ok");  // Generates: :ok
     * var tuple = {status, "Success"}; // Generates: {:ok, "Success"}
     * ```
     * 
     * @param name The atom name (without the colon)
     * @return An Elixir atom
     */
    public static function atom(name: String): Dynamic;
    
    /**
     * Create an Elixir tuple.
     * 
     * ```haxe
     * var result = Syntax.tuple(Syntax.atom("ok"), value);  // {:ok, value}
     * var triple = Syntax.tuple(1, 2, 3);                    // {1, 2, 3}
     * ```
     * 
     * @param args The values to include in the tuple
     * @return An Elixir tuple
     */
    public static function tuple(args: Rest<Dynamic>): Dynamic;
    
    /**
     * Create an Elixir keyword list.
     * 
     * ```haxe
     * var opts = Syntax.keyword([
     *     {key: "name", value: "test"},
     *     {key: "timeout", value: 5000}
     * ]);
     * // Generates: [name: "test", timeout: 5000]
     * ```
     * 
     * @param pairs Array of key-value pairs
     * @return An Elixir keyword list
     */
    public static function keyword(pairs: Array<{key: String, value: Dynamic}>): Dynamic;
}
#end