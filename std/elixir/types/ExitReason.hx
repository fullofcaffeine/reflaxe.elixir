package elixir.types;

/**
 * Type-safe abstraction for process exit reasons
 * 
 * In Elixir/Erlang, exit reasons are terms that describe why a process terminated.
 * Common exit reasons include atoms like :normal, :kill, :shutdown, or tuples 
 * like {:shutdown, term}. While technically any term can be an exit reason,
 * this abstract provides type-safe constructors for the most common patterns.
 * 
 * ## Why Dynamic?
 * 
 * We use Dynamic as the underlying type because exit reasons in Elixir can be:
 * - Atoms (:normal, :kill, :shutdown, :timeout)
 * - Tuples ({:shutdown, :immediate}, {:error, "failed to connect"})
 * - Any arbitrary term (strings, numbers, complex structures)
 * 
 * This flexibility is essential for OTP compliance and error propagation.
 * 
 * ## The @:to and @:from metadata
 * 
 * The abstract uses Haxe's implicit casting metadata:
 * - `from Dynamic`: Allows any Dynamic value to be implicitly cast to ExitReason
 * - `to Dynamic`: Allows ExitReason to be implicitly cast to Dynamic when needed
 * - `@:to` on toString(): Allows implicit conversion to String in string contexts
 * 
 * This provides type safety at API boundaries while maintaining flexibility.
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Using predefined exit reasons
 * Process.exit(pid, ExitReason.normal());        // :normal
 * Process.exit(pid, ExitReason.kill());          // :kill  
 * Process.exit(pid, ExitReason.shutdown());      // :shutdown
 * 
 * // Using custom exit reasons
 * Process.exit(pid, ExitReason.custom("timeout"));     // "timeout"
 * Process.exit(pid, ExitReason.shutdownWith("db"));    // {:shutdown, "db"}
 * 
 * // Implicit conversion from Dynamic
 * var reason: Dynamic = getExitReasonFromSomewhere();
 * Process.exit(pid, reason);  // Works due to 'from Dynamic'
 * 
 * // Implicit conversion to String
 * var exitReason = ExitReason.normal();
 * trace("Process exited with: " + exitReason);  // Uses toString() via @:to
 * ```
 */
abstract ExitReason(Dynamic) from Dynamic to Dynamic {
    /**
     * Create a new ExitReason wrapper
     */
    public inline function new(reason: Dynamic) {
        this = reason;
    }
    
    /**
     * Normal exit reason
     */
    public static inline function normal(): ExitReason {
        return new ExitReason(untyped __elixir__(':normal'));
    }
    
    /**
     * Kill exit reason (untrappable)
     */
    public static inline function kill(): ExitReason {
        return new ExitReason(untyped __elixir__(':kill'));
    }
    
    /**
     * Shutdown exit reason
     */
    public static inline function shutdown(): ExitReason {
        return new ExitReason(untyped __elixir__(':shutdown'));
    }
    
    /**
     * Shutdown with additional info
     */
    public static inline function shutdownWith(info: Dynamic): ExitReason {
        return new ExitReason(untyped __elixir__('{:shutdown, $info}'));
    }
    
    /**
     * Custom exit reason
     */
    public static inline function custom(reason: Dynamic): ExitReason {
        return new ExitReason(reason);
    }
    
    /**
     * Convert exit reason to string representation
     * 
     * The `@:to` metadata makes this an implicit cast operator in Haxe.
     * This means ExitReason values will automatically be converted to String
     * when used in string contexts, such as:
     * 
     * - String concatenation: `"Exit: " + exitReason`
     * - String interpolation: `'Process exited: $exitReason'`
     * - Passing to functions expecting String: `trace(exitReason)`
     * - Explicit casting: `var s: String = exitReason`
     * 
     * The implementation uses Elixir's inspect/1 function to produce
     * a readable string representation of any exit reason term.
     * 
     * Examples:
     * - `:normal` becomes "#atom<normal>"
     * - `{:shutdown, "db"}` becomes "{:shutdown, \"db\"}"
     * - Custom terms are inspected appropriately
     * 
     * @return String representation suitable for logging/debugging
     */
    @:to
    public inline function toString(): String {
        return untyped __elixir__('inspect($this)');
    }
}