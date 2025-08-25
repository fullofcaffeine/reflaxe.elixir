package elixir;

/**
 * Elixir Module utilities for runtime module operations
 * 
 * WHY: Provides type-safe access to Elixir's Module functions without __elixir__() injection
 * WHAT: Common module manipulation functions (concat, split, safe_concat) with proper types
 * HOW: Maps directly to Elixir Module functions via @:native annotations
 * 
 * DESIGN BENEFITS:
 * - Type safety: Compile-time validation instead of runtime string injection
 * - IDE support: Full autocomplete and error checking
 * - Framework consistency: Follows pure Haxe philosophy
 * - Performance: Direct function calls without dynamic evaluation
 * - Maintainability: Clear API surface and documentation
 * 
 * USAGE:
 * ```haxe
 * // Instead of: untyped __elixir__("Module.concat([App, PubSub])")
 * var pubsubModule = Module.concat([appName, "PubSub"]);
 * 
 * // Type-safe with IDE support
 * var parts = Module.split(MyModule);
 * ```
 */
@:native("Module")
extern class Module {
    
    /**
     * Concatenate module name parts into a single module atom
     * 
     * @param parts Array of module name components (atoms, strings, or modules)
     * @return Combined module atom
     * 
     * Examples:
     * - Module.concat(["MyApp", "Web"]) → MyApp.Web  
     * - Module.concat([Application.get_application(__MODULE__), "PubSub"]) → MyApp.PubSub
     */
    static function concat(parts: Array<Dynamic>): Dynamic;
    
    /**
     * Split a module name into its component parts
     * 
     * @param module Module atom to split
     * @return Array of atom components
     * 
     * Example:
     * - Module.split(MyApp.Web.Router) → [:MyApp, :Web, :Router]
     */
    static function split(module: Dynamic): Array<Dynamic>;
    
    /**
     * Safe concatenation that handles nil values gracefully
     * 
     * @param parts Array of module parts (may contain nil)
     * @return Module atom or nil if any required part is nil
     */
    static function safe_concat(parts: Array<Dynamic>): Dynamic;
}