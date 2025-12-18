package elixir.otp;

import elixir.types.Term;

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
 *
 * WHAT
 * - Marked with @:elixirIdiomatic so enum constructors compile to atoms
 *   (:normal, :temporary, :permanent) instead of numeric tuple tags ({0}, {1}, {2}).
 *
 * WHY
 * - OTP and Phoenix code pattern match on atoms for start types. Numeric tags are
 *   non-idiomatic and make matching verbose and fragile. This aligns output with
 *   standard Elixir expectations and makes generated code look hand-written.
 *
 * DEFAULT (without marker)
 * - Reflaxe.Elixir emits Haxe enums as tuples tagged by the constructor's
 *   integer index: {0}, {1}, {2}, or {idx, arg...}. This is the generic,
 *   target‑agnostic mapping that mirrors the underlying Haxe enum indices
 *   and avoids relying on names when tags are not explicitly defined.
 *
 * HOW
 * - When @:elixirIdiomatic is present, the compiler switches from index tags to
 *   atom tags, producing {:normal}/{:temporary}/{:permanent} tuples instead
 *   (see ElixirCompiler.buildEnumAST idiomatic path).
 *
 * EXAMPLES
 * Haxe:   ApplicationStartType.Normal → Elixir: {:normal}
 * Haxe:   ApplicationStartType.Permanent → Elixir: {:permanent}
 */
@:elixirIdiomatic
enum ApplicationStartType {
    Normal;
    Temporary;
    Permanent;
}

/**
 * Application arguments passed to start function
 */
abstract ApplicationArgs(Term) from Term to Term {
    public static function fromDynamic(value: Term): ApplicationArgs {
        return cast value;
    }
    
    public function toDynamic(): Term {
        return this;
    }
}

/**
 * Application start result - success with state or error
 *
 * WHAT
 * - Marked with @:elixirIdiomatic so constructors compile to {:ok, state},
 *   {:error, reason}, and :ignore instead of {0, state}, {1, reason}, {2}.
 *
 * WHY
 * - OTP/Application.start/2 idioms use :ok/:error/:ignore. Numeric tags prevent
 *   idiomatic pattern matching and confuse maintainers.
 *
 * DEFAULT (without marker)
 * - The generic enum emission uses integer indices and yields {0, state},
 *   {1, reason}, {2}. This preserves Haxe enum identity but is not idiomatic
 *   for OTP.
 *
 * HOW
 * - @:elixirIdiomatic switches enum tag emission from integer indices to atoms
 *   so output matches OTP conventions.
 *
 * EXAMPLES
 * Haxe:   ApplicationResult.Ok(state)    → Elixir: {:ok, state}
 * Haxe:   ApplicationResult.Error("x")  → Elixir: {:error, "x"}
 * Haxe:   ApplicationResult.Ignore       → Elixir: {:ignore}
 */
@:elixirIdiomatic
enum ApplicationResult {
    Ok(state: Term);
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
        return Ok(cast state);
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
    static function start(app: String, ?type: String): Term;
    
    /**
     * Stop an application
     */
    static function stop(app: String): Term;
    
    /**
     * Get application environment
     */
    static function get_env(app: String, key: String, ?default_value: Term): Term;
    
    /**
     * Put application environment
     */
    static function put_env(app: String, key: String, value: Term): Void;
    
    /**
     * Get all application environment
     */
    static function get_all_env(app: String): Term;
    
    /**
     * Load an application
     */
    static function load(app: String): Term;
    
    /**
     * Ensure an application is started
     */
    static function ensure_started(app: String, ?type: String): Term;
    
    /**
     * Ensure all applications are started
     */
    static function ensure_all_started(app: String, ?type: String): Term;
}
