package elixir;

import elixir.types.Term;

/**
 * Elixir Application utilities for runtime application operations
 * 
 * WHY: Provides type-safe access to Application functions without __elixir__() injection
 * WHAT: Common application introspection functions with proper types
 * HOW: Maps directly to Elixir Application functions via @:native annotations
 * 
 * DESIGN BENEFITS:
 * - Framework-agnostic: Works for any Elixir application, not just Phoenix
 * - Type safety: Compile-time validation of application operations
 * - Dynamic resolution: Resolves application names at runtime based on current module
 * - Performance: Direct function calls without string evaluation
 * 
 * USAGE:
 * ```haxe
 * // Get the application that owns the current module
 * var appName = Application.get_application(__MODULE__);
 * 
 * // Get application environment configuration  
 * var config = Application.get_env(appName, :some_key, defaultValue);
 * ```
 */
@:native("Application")
extern class Application {
    
    /**
     * Get the application that owns the given module
     * 
     * @param module Module atom (typically __MODULE__ for current module)
     * @return Application name atom, or nil if not found
     * 
     * Example:
     * - Application.get_application(MyApp.Web.Router) → :my_app
     */
    static function get_application(module: Term): Term;
    
    /**
     * Get application environment configuration value
     * 
     * @param app Application name atom  
     * @param key Configuration key atom
     * @param defaultValue Default value if key not found
     * @return Configuration value or default
     */
    static function get_env(app: Term, key: Term, ?defaultValue: Term): Term;
    
    /**
     * Get all environment configuration for an application
     * 
     * @param app Application name atom
     * @return Map of all configuration key-value pairs
     */
    static function get_all_env(app: Term): Term;
}
