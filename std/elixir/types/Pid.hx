package elixir.types;

/**
 * Type-safe abstraction for Elixir process identifiers (PIDs)
 * 
 * This abstract type provides compile-time type safety for process IDs
 * while compiling to regular Elixir PIDs at runtime with zero overhead.
 * 
 * Usage:
 * ```haxe
 * var myPid: Pid = Process.self();
 * Process.send(myPid, "Hello");
 * if (Process.alive(myPid)) { ... }
 * ```
 */
abstract Pid(Dynamic) from Dynamic to Dynamic {
    /**
     * Create a new Pid wrapper
     * Note: This is typically not called directly - PIDs come from Process functions
     */
    public inline function new(pid: Dynamic) {
        this = pid;
    }
    
    /**
     * Convert a string representation to a Pid
     * Example: "#PID<0.123.0>" becomes a valid Pid
     */
    @:from
    public static inline function fromString(str: String): Pid {
        return new Pid(untyped __elixir__('Process.pid_from_string($str)'));
    }
    
    /**
     * Convert this Pid to its string representation
     * Returns format like "#PID<0.123.0>"
     */
    @:to
    public inline function toString(): String {
        return untyped __elixir__('inspect($this)');
    }
    
    /**
     * Check if this PID represents the current process
     */
    public inline function isSelf(): Bool {
        return untyped __elixir__('$this == self()');
    }
    
    /**
     * Check if this process is alive
     */
    public inline function isAlive(): Bool {
        return untyped __elixir__('Process.alive?($this)');
    }
    
    /**
     * Get the node where this process is running
     */
    public inline function node(): String {
        return untyped __elixir__('node($this)');
    }
}