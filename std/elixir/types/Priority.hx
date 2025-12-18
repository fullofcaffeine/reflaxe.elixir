package elixir.types;

import elixir.types.Atom;

/**
 * Type-safe representation of process scheduling priorities in Elixir/Erlang.
 * 
 * Process priority affects how the scheduler allocates CPU time to processes.
 * Higher priority processes get more CPU time relative to lower priority ones.
 * 
 * ## Priority Levels
 * - `low`: Process runs less frequently than normal
 * - `normal`: Default priority for most processes
 * - `high`: Process runs more frequently than normal
 * - `max`: Highest priority, typically for system processes
 * 
 * ## Usage Example
 * ```haxe
 * // Set a process to high priority
 * Process.flag(ProcessFlag.priority(), Priority.high());
 * 
 * // Spawn a low priority background task
 * var pid = Process.spawnWithOptions(backgroundTask, [Priority.low()]);
 * ```
 * 
 * ## Performance Considerations
 * - Use `high` and `max` priorities sparingly to avoid starving other processes
 * - System processes typically use `max` priority
 * - Most application processes should use `normal` priority
 * 
 * @see Process.flag for setting process priority
 * @see ProcessFlag for other process flags
 */
abstract Priority(Atom) from Atom to Atom {
    
    /**
     * Low priority - process runs less frequently than normal.
     * Use for background tasks that shouldn't interfere with
     * interactive or time-sensitive operations.
     */
    public static inline function low(): Priority {
        return new Priority("low");
    }
    
    /**
     * Normal priority - default for most processes.
     * Provides balanced CPU allocation.
     */
    public static inline function normal(): Priority {
        return new Priority("normal");
    }
    
    /**
     * High priority - process runs more frequently than normal.
     * Use for time-sensitive operations that need quick response.
     */
    public static inline function high(): Priority {
        return new Priority("high");
    }
    
    /**
     * Maximum priority - highest scheduling priority.
     * Typically reserved for critical system processes.
     * Use with extreme caution as it can starve other processes.
     */
    public static inline function max(): Priority {
        return new Priority("max");
    }
    
    /**
     * Convert priority to its atom representation.
     * @return The priority as an Elixir atom
     */
    public inline function toAtom(): Atom {
        return this;
    }

    private inline function new(priority: Atom) {
        this = priority;
    }
}
