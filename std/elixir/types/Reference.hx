package elixir.types;

/**
 * Type-safe abstraction for Elixir references
 * 
 * References are unique identifiers used for monitors, timers, and other
 * operations that need tracking. This abstract provides compile-time type
 * safety while compiling to regular Elixir references at runtime.
 * 
 * Usage:
 * ```haxe
 * var monitorRef: Reference = Process.monitor(pid);
 * Process.demonitor(monitorRef);
 * 
 * var timerRef: Reference = Process.sendAfter(pid, "timeout", 5000);
 * Process.cancelTimer(timerRef);
 * ```
 */
abstract Reference(Term) from Term to Term {
    /**
     * Create a new Reference wrapper
     * Note: This is typically not called directly - refs come from Process/timer functions
     */
    public inline function new(ref: Term) {
        this = ref;
    }
    
    /**
     * Create a new unique reference
     * Useful for creating unique identifiers
     */
    public static inline function make(): Reference {
        return new Reference(untyped __elixir__('make_ref()'));
    }
    
    /**
     * Convert this reference to its string representation
     * Returns format like "#Reference<0.123.456.789>"
     */
    @:to
    public inline function toString(): String {
        return untyped __elixir__('inspect($this)');
    }
    
    /**
     * Check if this is a valid reference
     */
    public inline function isValid(): Bool {
        return untyped __elixir__('is_reference($this)');
    }
}
