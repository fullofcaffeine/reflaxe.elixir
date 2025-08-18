package elixir.otp;

/**
 * Type-safe wrapper for OTP Application lifecycle functions
 * 
 * Provides compile-time type checking for application start/stop functions
 * while maintaining runtime compatibility with Elixir's Application behavior.
 * 
 * Usage:
 * ```haxe
 * @:application
 * class MyApp {
 *     public static function start(type: ApplicationStartType, args: ApplicationArgs): ApplicationResult {
 *         // Type-safe application startup
 *         return ApplicationResult.ok(someState);
 *     }
 * }
 * ```
 * 
 * Compiles to:
 * ```elixir
 * defmodule MyApp.Application do
 *   use Application
 *   
 *   def start(type, args) do
 *     # Type-safe startup logic
 *     {:ok, some_state}
 *   end
 * end
 * ```
 */

/**
 * Application start type - normal, temporary, or permanent
 */
enum ApplicationStartType {
    Normal;
    Temporary;
    Permanent;
}

/**
 * Application arguments passed to start function
 */
abstract ApplicationArgs(Dynamic) from Dynamic to Dynamic {
    public static function fromDynamic(value: Dynamic): ApplicationArgs {
        return cast value;
    }
    
    public function toDynamic(): Dynamic {
        return this;
    }
}

/**
 * Application start result - success with state or error
 */
enum ApplicationResult {
    Ok(state: Dynamic);
    Error(reason: String);
    Ignore;
}

/**
 * Helper class for Application result construction
 */
class ApplicationResultTools {
    /**
     * Create a successful application start result
     */
    public static function ok<T>(state: T): ApplicationResult {
        return Ok(state);
    }
    
    /**
     * Create an error application start result
     */
    public static function error(reason: String): ApplicationResult {
        return Error(reason);
    }
    
    /**
     * Create an ignore application start result
     */
    public static function ignore(): ApplicationResult {
        return Ignore;
    }
}

/**
 * Type-safe wrapper for Application module functions
 */
@:native("Application")
extern class ApplicationExtern {
    /**
     * Start an application
     */
    static function start(app: String, ?type: String): Dynamic;
    
    /**
     * Stop an application
     */
    static function stop(app: String): Dynamic;
    
    /**
     * Get application environment
     */
    static function get_env(app: String, key: String, ?default_value: Dynamic): Dynamic;
    
    /**
     * Put application environment
     */
    static function put_env(app: String, key: String, value: Dynamic): Void;
    
    /**
     * Get all application environment
     */
    static function get_all_env(app: String): Dynamic;
    
    /**
     * Load an application
     */
    static function load(app: String): Dynamic;
    
    /**
     * Ensure an application is started
     */
    static function ensure_started(app: String, ?type: String): Dynamic;
    
    /**
     * Ensure all applications are started
     */
    static function ensure_all_started(app: String, ?type: String): Dynamic;
}