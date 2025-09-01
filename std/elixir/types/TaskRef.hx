package elixir.types;

/**
 * Type-safe abstraction for Elixir Task references
 * 
 * TaskRef provides a type-safe wrapper around Task.t() references,
 * enabling compile-time validation of async operations.
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Start an async task
 * var task: TaskRef = Task.async(() -> computeValue());
 * 
 * // Await the result
 * var result = Task.await(task);
 * 
 * // Check task status
 * var yieldResult = Task.yield(task);
 * switch(yieldResult) {
 *     case Some(Ok(value)): trace("Got result: " + value);
 *     case Some(Exit(reason)): trace("Task failed: " + reason);
 *     case None: trace("Task still running");
 * }
 * ```
 * 
 * ## Type Safety Benefits
 * 
 * - **Compile-time validation**: Can't mix task refs with other types
 * - **Clear API contracts**: Functions explicitly require TaskRef
 * - **Zero overhead**: Compiles to native Task.t() at runtime
 * - **Better IntelliSense**: Full autocomplete for task operations
 */
abstract TaskRef(Dynamic) from Dynamic to Dynamic {
    /**
     * Create a new TaskRef wrapper
     * Usually not called directly - returned from Task.async()
     */
    public inline function new(task: Dynamic) {
        this = task;
    }
    
    /**
     * Get the PID of the task process
     */
    public inline function pid(): Pid {
        return untyped __elixir__('$this.pid');
    }
    
    /**
     * Get the reference of the task
     */
    public inline function ref(): Dynamic {
        return untyped __elixir__('$this.ref');
    }
    
    /**
     * Get the owner PID (the process that spawned this task)
     */
    public inline function owner(): Pid {
        return untyped __elixir__('$this.owner');
    }
    
    /**
     * Check if this task is still alive
     */
    public inline function isAlive(): Bool {
        return untyped __elixir__('Process.alive?($this.pid)');
    }
    
    /**
     * Convert to string for debugging
     */
    @:to
    public inline function toString(): String {
        return untyped __elixir__('inspect($this)');
    }
}