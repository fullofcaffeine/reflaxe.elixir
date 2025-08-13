package elixir;

#if (macro || reflaxe_runtime)

/**
 * Task extern definitions for Elixir concurrent execution
 * Provides type-safe interfaces for async operations and background work
 * 
 * Tasks are processes meant to execute one particular action throughout their lifetime
 */
@:native("Task")
extern class Task {
    
    // Task creation - async operations
    @:native("Task.async")
    public static function async(fun: () -> Dynamic): Dynamic; // Returns Task.t()
    
    @:native("Task.async")
    public static function asyncMFA(module: String, func: String, args: Array<Dynamic>): Dynamic; // Returns Task.t()
    
    @:native("Task.await")
    public static function await(task: Dynamic): Dynamic; // Returns task result
    
    @:native("Task.await")
    public static function awaitWithTimeout(task: Dynamic, timeout: Int): Dynamic; // Returns task result
    
    // Task creation - fire and forget
    @:native("Task.start")
    public static function start(fun: () -> Void): {_0: String, _1: Dynamic}; // {:ok, pid}
    
    @:native("Task.start")
    public static function startMFA(module: String, func: String, args: Array<Dynamic>): {_0: String, _1: Dynamic}; // {:ok, pid}
    
    @:native("Task.start_link")
    public static function startLink(fun: () -> Void): {_0: String, _1: Dynamic}; // {:ok, pid}
    
    @:native("Task.start_link")
    public static function startLinkMFA(module: String, func: String, args: Array<Dynamic>): {_0: String, _1: Dynamic}; // {:ok, pid}
    
    // Task control
    @:native("Task.yield")
    public static function yield(task: Dynamic): Null<{_0: String, _1: Dynamic}>; // {:ok, result} | {:exit, reason} | nil
    
    @:native("Task.yield")
    public static function yieldWithTimeout(task: Dynamic, timeout: Int): Null<{_0: String, _1: Dynamic}>; // {:ok, result} | {:exit, reason} | nil
    
    @:native("Task.yield_many")
    public static function yieldMany(tasks: Array<Dynamic>): Array<{_0: Dynamic, _1: Null<{_0: String, _1: Dynamic}>}>; // [{task, result}]
    
    @:native("Task.yield_many")
    public static function yieldManyWithTimeout(tasks: Array<Dynamic>, timeout: Int): Array<{_0: Dynamic, _1: Null<{_0: String, _1: Dynamic}>}>; // [{task, result}]
    
    @:native("Task.shutdown")
    public static function shutdown(task: Dynamic): Null<{_0: String, _1: Dynamic}>; // {:ok, result} | {:exit, reason} | nil
    
    @:native("Task.shutdown")
    public static function shutdownWithTimeout(task: Dynamic, timeout: Int): Null<{_0: String, _1: Dynamic}>; // {:ok, result} | {:exit, reason} | nil
    
    // Task utilities
    @:native("Task.completed")
    public static function completed(result: Dynamic): Dynamic; // Returns completed Task.t()
    
    @:native("Task.ignore")
    public static function ignore(task: Dynamic): String; // :ok
    
    @:native("Task.child_spec")
    public static function childSpec(arg: Dynamic): Map<String, Dynamic>; // Child spec for supervision
    
    // Async streams
    @:native("Task.async_stream")
    public static function asyncStream(enumerable: Array<Dynamic>, fun: (Dynamic) -> Dynamic): Dynamic; // Returns Stream
    
    @:native("Task.async_stream")
    public static function asyncStreamWithOptions(enumerable: Array<Dynamic>, fun: (Dynamic) -> Dynamic, options: Map<String, Dynamic>): Dynamic;
    
    @:native("Task.async_stream")
    public static function asyncStreamMFA(enumerable: Array<Dynamic>, module: String, func: String, args: Array<Dynamic>): Dynamic;
    
    // Helper functions for common patterns
    
    /**
     * Run a function asynchronously and get the result
     */
    public static inline function runAsync<T>(fun: () -> T): T {
        var task = async(fun);
        return await(task);
    }
    
    /**
     * Run multiple functions concurrently and collect results
     */
    public static inline function runConcurrently(funs: Array<() -> Dynamic>): Array<Dynamic> {
        var tasks = [for (fun in funs) async(fun)];
        return [for (task in tasks) await(task)];
    }
    
    /**
     * Run a function with timeout
     */
    public static inline function runWithTimeout<T>(fun: () -> T, timeout: Int): Null<T> {
        var task = async(fun);
        var result = yieldWithTimeout(task, timeout);
        if (result != null && result._0 == "ok") {
            return result._1;
        }
        shutdown(task);
        return null;
    }
    
    /**
     * Fire and forget background task
     */
    public static inline function runInBackground(fun: () -> Void): Void {
        start(fun);
    }
}


#end