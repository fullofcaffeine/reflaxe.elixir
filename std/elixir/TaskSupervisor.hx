package elixir;

#if (macro || reflaxe_runtime)

import elixir.types.Pid;
import elixir.types.TaskRef;
import elixir.types.Term;

/**
 * Task.Supervisor extern for supervised task execution
 * Provides fault-tolerant task supervision
 */
@:native("Task.Supervisor")
extern class TaskSupervisor {
    
    // Supervisor lifecycle
    @:native("Task.Supervisor.start_link")
    public static function startLink(): {_0: String, _1: Pid}; // {:ok, pid}
    
    @:native("Task.Supervisor.start_link")
    public static function startLinkWithOptions(options: Array<Term>): {_0: String, _1: Pid}; // {:ok, pid}
    
    // Supervised async operations
    @:native("Task.Supervisor.async")
    public static function async<T>(supervisor: Term, fun: () -> T): TaskRef; // Returns Task.t()
    
    @:native("Task.Supervisor.async")
    public static function asyncMFA(supervisor: Term, module: Term, func: String, args: Array<Term>): TaskRef;
    
    @:native("Task.Supervisor.async_nolink")
    public static function asyncNolink<T>(supervisor: Term, fun: () -> T): TaskRef; // Returns Task.t()
    
    @:native("Task.Supervisor.async_nolink")
    public static function asyncNolinkMFA(supervisor: Term, module: Term, func: String, args: Array<Term>): TaskRef;
    
    // Child management
    @:native("Task.Supervisor.start_child")
    public static function startChild(supervisor: Term, fun: () -> Void): {_0: String, _1: Pid}; // {:ok, pid}
    
    @:native("Task.Supervisor.start_child")
    public static function startChildMFA(supervisor: Term, module: Term, func: String, args: Array<Term>): {_0: String, _1: Pid};
    
    @:native("Task.Supervisor.start_child")
    public static function startChildWithOptions(supervisor: Term, fun: () -> Void, options: Map<String, Term>): {_0: String, _1: Pid};
    
    @:native("Task.Supervisor.terminate_child")
    public static function terminateChild(supervisor: Term, pid: Pid): Term; // :ok
    
    @:native("Task.Supervisor.children")
    public static function children(supervisor: Term): Array<Pid>; // List of pids
    
    // Async streams
    @:native("Task.Supervisor.async_stream")
    public static function asyncStream(supervisor: Term, enumerable: Term, fun: (Term) -> Term): Term; // Returns Stream
    
    @:native("Task.Supervisor.async_stream")
    public static function asyncStreamWithOptions(supervisor: Term, enumerable: Term, fun: (Term) -> Term, options: Map<String, Term>): Term;
    
    @:native("Task.Supervisor.async_stream_nolink")
    public static function asyncStreamNolink(supervisor: Term, enumerable: Term, fun: (Term) -> Term): Term;
    
    @:native("Task.Supervisor.async_stream_nolink")
    public static function asyncStreamNolinkWithOptions(supervisor: Term, enumerable: Term, fun: (Term) -> Term, options: Map<String, Term>): Term;
    
    // Helper functions
    
    /**
     * Start a supervised task and await result
     */
    public static inline function runSupervised<T>(supervisor: Term, fun: () -> T): T {
        var task = async(supervisor, fun);
        return Task.await(task);
    }
    
    /**
     * Run multiple supervised tasks concurrently
     */
    public static inline function runSupervisedConcurrently<T>(supervisor: Term, funs: Array<() -> T>): Array<T> {
        var tasks = [for (fun in funs) async(supervisor, fun)];
        return [for (task in tasks) Task.await(task)];
    }
    
    /**
     * Start a fire-and-forget supervised task
     */
    public static inline function runSupervisedInBackground(supervisor: Term, fun: () -> Void): Void {
        startChild(supervisor, fun);
    }
}

#end
