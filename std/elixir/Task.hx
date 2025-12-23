package elixir;

import elixir.types.TaskRef;
import elixir.types.TaskResult;
import elixir.types.Pid;
import elixir.types.Term;
import haxe.functional.Result;

#if (macro || reflaxe_runtime)

/**
 * Task extern definitions for Elixir concurrent execution
 * Provides type-safe interfaces for async operations and background work
 * 
 * Tasks are processes meant to execute one particular action throughout their lifetime.
 * They provide a convenient way to spawn processes for concurrent work.
 * 
 * ## Type Parameters
 * - `T`: The type of value returned by the task
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Simple async operation
 * var task = Task.async(() -> expensiveComputation());
 * var result = Task.await(task);
 * 
 * // With timeout
 * var task = Task.async(() -> slowOperation());
 * switch(Task.yieldWithTimeout(task, 5000)) {
 *     case null: trace("Timeout!");
 *     case Ok(value): trace("Got: " + value);
 *     case Exit(reason): trace("Failed: " + reason);
 * }
 * 
 * // Fire and forget
 * Task.start(() -> backgroundWork());
 * ```
 */
@:native("Task")
extern class Task {
    
    // Task creation - async operations with type safety
    @:native("Task.async")
    public static function async<T>(fun: () -> T): TaskRef;
    
    @:native("Task.async")
    public static function asyncMFA<T>(module: String, func: String, args: Array<Term>): TaskRef;
    
    @:native("Task.await")
    public static function await<T>(task: TaskRef): T;
    
    @:native("Task.await")
    public static function awaitWithTimeout<T>(task: TaskRef, timeout: Int): T;
    
    // Task creation - fire and forget with Result types
    @:native("Task.start")
    public static function start(fun: () -> Void): Result<Pid, String>;
    
    @:native("Task.start")
    public static function startMFA(module: String, func: String, args: Array<Term>): Result<Pid, String>;
    
    @:native("Task.start_link")
    public static function startLink(fun: () -> Void): Result<Pid, String>;
    
    @:native("Task.start_link")
    public static function startLinkMFA(module: String, func: String, args: Array<Term>): Result<Pid, String>;
    
    // Task control with type-safe results
    @:native("Task.yield")
    public static function yield<T>(task: TaskRef): TaskYieldOption<T>;
    
    @:native("Task.yield")
    public static function yieldWithTimeout<T>(task: TaskRef, timeout: Int): TaskYieldOption<T>;
    
    @:native("Task.yield_many")
    public static function yieldMany<T>(tasks: Array<TaskRef>): Array<{task: TaskRef, result: TaskYieldOption<T>}>;
    
    @:native("Task.yield_many")
    public static function yieldManyWithTimeout<T>(tasks: Array<TaskRef>, timeout: Int): Array<{task: TaskRef, result: TaskYieldOption<T>}>;
    
    @:native("Task.shutdown")
    public static function shutdown<T>(task: TaskRef): TaskYieldOption<T>;
    
    @:native("Task.shutdown")
    public static function shutdownWithTimeout<T>(task: TaskRef, timeout: Int): TaskYieldOption<T>;
    
    // Task utilities with generics
    @:native("Task.completed")
    public static function completed<T>(result: T): TaskRef;
    
    @:native("Task.ignore")
    public static function ignore(task: TaskRef): Void;
    
    @:native("Task.child_spec")
    public static function childSpec(arg: Term): Map<String, Term>;
    
    // Async streams with type safety
    @:native("Task.async_stream")
    public static function asyncStream<T, R>(enumerable: Array<T>, fun: (T) -> R): Term; // Returns Stream
    
    @:native("Task.async_stream")
    public static function asyncStreamWithOptions<T, R>(enumerable: Array<T>, fun: (T) -> R, options: TaskStreamOptions): Term;
    
    @:native("Task.async_stream")
    public static function asyncStreamMFA<T>(enumerable: Array<T>, module: String, func: String, args: Array<Term>): Term;
    
    // Helper functions for common patterns with full type safety
    
    /**
     * Run a function asynchronously and get the result
     * @param fun The function to execute
     * @return The result of the function
     */
    public static inline function runAsync<T>(fun: () -> T): T {
        var task = async(fun);
        return await(task);
    }
    
    /**
     * Run multiple functions concurrently and collect results
     * @param funs Array of functions to execute
     * @return Array of results in the same order
     */
    public static inline function runConcurrently<T>(funs: Array<() -> T>): Array<T> {
        var tasks = [for (fun in funs) async(fun)];
        return [for (task in tasks) await(task)];
    }
    
    /**
     * Run a function with timeout
     * @param fun The function to execute
     * @param timeout Timeout in milliseconds
     * @return The result or null if timeout/failed
     */
    public static inline function runWithTimeout<T>(fun: () -> T, timeout: Int): Null<T> {
        var task = async(fun);
        var result = yieldWithTimeout(task, timeout);
        return switch(result) {
            case null: 
                shutdown(task);
                null;
            case Ok(value): value;
            case Exit(_): 
                null;
        };
    }
    
    /**
     * Fire and forget background task
     * @param fun The function to run in background
     */
    public static inline function runInBackground(fun: () -> Void): Void {
        start(fun);
    }
    
    /**
     * Run tasks in parallel and return first successful result
     * @param funs Array of functions to try
     * @return First successful result or null if all fail
     */
    public static inline function raceToSuccess<T>(funs: Array<() -> T>): Null<T> {
        var tasks = [for (fun in funs) async(fun)];
        
        while (tasks.length > 0) {
            var results = yieldMany(tasks);
            for (r in results) {
                switch(r.result) {
                    case Ok(value):
                        // Cancel remaining tasks
                        for (t in tasks) {
                            if (t != r.task) shutdown(t);
                        }
                        return value;
                    case Exit(_):
                        tasks.remove(r.task);
                    case null:
                        // Still running
                }
            }
        }
        return null;
    }
}

/**
 * Options for Task.async_stream operations
 */
typedef TaskStreamOptions = {
    /**
     * Maximum number of concurrent tasks
     * Default: System.schedulers_online()
     */
    ?max_concurrency: Int,
    
    /**
     * Whether to preserve input order in results
     * Default: true
     */
    ?ordered: Bool,
    
    /**
     * Timeout for each task in milliseconds
     * Default: 5000
     */
    ?timeout: Int,
    
    /**
     * What to do on task failure
     * :exit_on_error (default) or :ignore
     */
    ?on_timeout: Term,
    
    /**
     * Whether to zip input with results
     * Default: false
     */
    ?zip_input_on_exit: Bool
}

#end
