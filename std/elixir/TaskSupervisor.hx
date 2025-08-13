package elixir;

#if (macro || reflaxe_runtime)

/**
 * Task.Supervisor extern for supervised task execution
 * Provides fault-tolerant task supervision
 */
@:native("Task.Supervisor")
extern class TaskSupervisor {
    
    // Supervisor lifecycle
    @:native("Task.Supervisor.start_link")
    public static function startLink(): {_0: String, _1: Dynamic}; // {:ok, pid}
    
    @:native("Task.Supervisor.start_link")
    public static function startLinkWithOptions(options: Array<Dynamic>): {_0: String, _1: Dynamic}; // {:ok, pid}
    
    // Supervised async operations
    @:native("Task.Supervisor.async")
    public static function async(supervisor: Dynamic, fun: () -> Dynamic): Dynamic; // Returns Task.t()
    
    @:native("Task.Supervisor.async")
    public static function asyncMFA(supervisor: Dynamic, module: String, func: String, args: Array<Dynamic>): Dynamic;
    
    @:native("Task.Supervisor.async_nolink")
    public static function asyncNolink(supervisor: Dynamic, fun: () -> Dynamic): Dynamic; // Returns Task.t()
    
    @:native("Task.Supervisor.async_nolink")
    public static function asyncNolinkMFA(supervisor: Dynamic, module: String, func: String, args: Array<Dynamic>): Dynamic;
    
    // Child management
    @:native("Task.Supervisor.start_child")
    public static function startChild(supervisor: Dynamic, fun: () -> Void): {_0: String, _1: Dynamic}; // {:ok, pid}
    
    @:native("Task.Supervisor.start_child")
    public static function startChildMFA(supervisor: Dynamic, module: String, func: String, args: Array<Dynamic>): {_0: String, _1: Dynamic};
    
    @:native("Task.Supervisor.start_child")
    public static function startChildWithOptions(supervisor: Dynamic, fun: () -> Void, options: Map<String, Dynamic>): {_0: String, _1: Dynamic};
    
    @:native("Task.Supervisor.terminate_child")
    public static function terminateChild(supervisor: Dynamic, pid: Dynamic): String; // :ok
    
    @:native("Task.Supervisor.children")
    public static function children(supervisor: Dynamic): Array<Dynamic>; // List of pids
    
    // Async streams
    @:native("Task.Supervisor.async_stream")
    public static function asyncStream(supervisor: Dynamic, enumerable: Array<Dynamic>, fun: (Dynamic) -> Dynamic): Dynamic; // Returns Stream
    
    @:native("Task.Supervisor.async_stream")
    public static function asyncStreamWithOptions(supervisor: Dynamic, enumerable: Array<Dynamic>, fun: (Dynamic) -> Dynamic, options: Map<String, Dynamic>): Dynamic;
    
    @:native("Task.Supervisor.async_stream_nolink")
    public static function asyncStreamNolink(supervisor: Dynamic, enumerable: Array<Dynamic>, fun: (Dynamic) -> Dynamic): Dynamic;
    
    @:native("Task.Supervisor.async_stream_nolink")
    public static function asyncStreamNolinkWithOptions(supervisor: Dynamic, enumerable: Array<Dynamic>, fun: (Dynamic) -> Dynamic, options: Map<String, Dynamic>): Dynamic;
    
    // Helper functions
    
    /**
     * Start a supervised task and await result
     */
    public static inline function runSupervised<T>(supervisor: Dynamic, fun: () -> T): T {
        var task = async(supervisor, fun);
        return Task.await(task);
    }
    
    /**
     * Run multiple supervised tasks concurrently
     */
    public static inline function runSupervisedConcurrently(supervisor: Dynamic, funs: Array<() -> Dynamic>): Array<Dynamic> {
        var tasks = [for (fun in funs) async(supervisor, fun)];
        return [for (task in tasks) Task.await(task)];
    }
    
    /**
     * Start a fire-and-forget supervised task
     */
    public static inline function runSupervisedInBackground(supervisor: Dynamic, fun: () -> Void): Void {
        startChild(supervisor, fun);
    }
}

#end