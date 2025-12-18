package elixir.types;

import elixir.Kernel;
import elixir.Process;
import elixir.types.Pid;
import elixir.types.Reference;
import elixir.types.Term;

// Task.t() is a struct with these fields.
// We model it locally so TaskRef methods can compile to idiomatic `task.pid` access.
private typedef TaskStruct = {
    var pid: Pid;
    var ref: Reference;
    var owner: Pid;
};

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
abstract TaskRef(Term) from Term to Term {
    /**
     * Create a new TaskRef wrapper
     * Usually not called directly - returned from Task.async()
     */
    public inline function new(task: Term) {
        this = task;
    }
    
    /**
     * Get the PID of the task process
     */
    public inline function pid(): Pid {
        var task: TaskStruct = cast this;
        return task.pid;
    }
    
    /**
     * Get the reference of the task
     */
    public inline function ref(): Reference {
        var task: TaskStruct = cast this;
        return task.ref;
    }
    
    /**
     * Get the owner PID (the process that spawned this task)
     */
    public inline function owner(): Pid {
        var task: TaskStruct = cast this;
        return task.owner;
    }
    
    /**
     * Check if this task is still alive
     */
    public inline function isAlive(): Bool {
        return Process.alive(pid());
    }
    
    /**
     * Convert to string for debugging
     */
    @:to
    public inline function toString(): String {
        return Kernel.inspect(this);
    }
}
