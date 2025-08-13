package elixir;

#if (macro || reflaxe_runtime)

/**
 * Supervisor restart strategies
 */
enum SupervisorStrategy {
    ONE_FOR_ONE;      // Only restart the failed child
    REST_FOR_ONE;     // Restart failed child and all after it  
    ONE_FOR_ALL;      // Restart all children if one fails
}

/**
 * Child restart options
 */
enum RestartOption {
    PERMANENT;        // Always restart
    TEMPORARY;        // Never restart
    TRANSIENT;        // Only restart on abnormal termination
}

/**
 * Supervisor extern definitions for Elixir OTP
 * Provides type-safe interfaces for supervision tree management
 * 
 * The Supervisor module is used to start, supervise and restart child processes
 */
@:native("Supervisor")
extern class Supervisor {
    
    // Supervisor startup
    @:native("Supervisor.start_link")
    public static function startLink(children: Array<Dynamic>, options: Dynamic): {_0: String, _1: Dynamic}; // {:ok, pid} | {:error, reason}
    
    @:native("Supervisor.start_link")
    public static function startLinkWithModule(module: String, initArg: Dynamic): {_0: String, _1: Dynamic};
    
    @:native("Supervisor.start_link")
    public static function startLinkWithModuleAndOptions(module: String, initArg: Dynamic, options: Array<Dynamic>): {_0: String, _1: Dynamic};
    
    // Child management
    @:native("Supervisor.which_children")
    public static function whichChildren(supervisor: Dynamic): Array<{_0: Dynamic, _1: Dynamic, _2: String, _3: Array<String>}>; // [{id, child, type, modules}]
    
    @:native("Supervisor.count_children")
    public static function countChildren(supervisor: Dynamic): Map<String, Int>; // %{specs: n, active: n, supervisors: n, workers: n}
    
    @:native("Supervisor.restart_child")
    public static function restartChild(supervisor: Dynamic, childId: Dynamic): {_0: String, _1: Dynamic}; // {:ok, child} | {:ok, child, info} | {:error, reason}
    
    @:native("Supervisor.terminate_child")
    public static function terminateChild(supervisor: Dynamic, childId: Dynamic): String; // :ok | {:error, reason}
    
    @:native("Supervisor.delete_child")
    public static function deleteChild(supervisor: Dynamic, childId: Dynamic): String; // :ok | {:error, reason}
    
    @:native("Supervisor.start_child")
    public static function startChild(supervisor: Dynamic, childSpec: Dynamic): {_0: String, _1: Dynamic}; // {:ok, child} | {:error, reason}
    
    // Supervisor control
    @:native("Supervisor.stop")
    public static function stop(supervisor: Dynamic): String; // :ok
    
    @:native("Supervisor.stop")
    public static function stopWithReason(supervisor: Dynamic, reason: String): String; // :ok
    
    @:native("Supervisor.stop")
    public static function stopWithReasonAndTimeout(supervisor: Dynamic, reason: String, timeout: Int): String; // :ok
    
    // Child specification
    @:native("Supervisor.child_spec")
    public static function childSpec(moduleOrMap: Dynamic): Map<String, Dynamic>; // Child spec map
    
    @:native("Supervisor.child_spec")
    public static function childSpecWithOverrides(moduleOrMap: Dynamic, overrides: Map<String, Dynamic>): Map<String, Dynamic>;
    
    // Supervisor initialization (for module-based supervisors)
    @:native("Supervisor.init")
    public static function init(children: Array<Dynamic>, options: Map<String, Dynamic>): {_0: String, _1: Dynamic}; // {:ok, {sup_flags, children}}
    
    // Helper functions for common patterns
    
    /**
     * Create a simple one-for-one supervisor configuration
     */
    public static inline function simpleOneForOne(maxRestarts: Int = 3, maxSeconds: Int = 5): Map<String, Dynamic> {
        return [
            "strategy" => "one_for_one",
            "max_restarts" => maxRestarts,
            "max_seconds" => maxSeconds
        ];
    }
    
    /**
     * Create a child specification for a GenServer
     */
    public static inline function workerSpec(module: String, args: Dynamic, ?id: String, ?restart: String = "permanent"): Map<String, Dynamic> {
        var spec: Map<String, Dynamic> = [
            "start" => {_0: module, _1: "start_link", _2: [args]},
            "restart" => restart,
            "type" => "worker"
        ];
        if (id != null) spec["id"] = id;
        else spec["id"] = module;
        return spec;
    }
    
    /**
     * Create a child specification for another supervisor
     */
    public static inline function supervisorSpec(module: String, args: Dynamic, ?id: String, ?restart: String = "permanent"): Map<String, Dynamic> {
        var spec: Map<String, Dynamic> = [
            "start" => {_0: module, _1: "start_link", _2: [args]},
            "restart" => restart,
            "type" => "supervisor"
        ];
        if (id != null) spec["id"] = id;
        else spec["id"] = module;
        return spec;
    }
    
    /**
     * Check if a supervisor is running
     */
    public static inline function isAlive(supervisor: Dynamic): Bool {
        return Process.alive(supervisor);
    }
    
    /**
     * Get supervisor statistics
     */
    public static inline function getStats(supervisor: Dynamic): {specs: Int, active: Int, supervisors: Int, workers: Int} {
        var counts = countChildren(supervisor);
        return {
            specs: counts["specs"],
            active: counts["active"],
            supervisors: counts["supervisors"],
            workers: counts["workers"]
        };
    }
}

#end