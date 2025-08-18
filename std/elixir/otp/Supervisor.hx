package elixir.otp;

/**
 * Type-safe wrapper for OTP Supervisor child specifications
 * 
 * Provides compile-time type checking for supervisor child specs while
 * maintaining runtime compatibility with Elixir's Supervisor behavior.
 * 
 * Usage:
 * ```haxe
 * var children: Array<ChildSpec> = [
 *     ChildSpec.worker("MyWorker", [arg1, arg2]),
 *     ChildSpec.supervisor("MySupervisor", [])
 * ];
 * SupervisorExtern.start_link(children, SupervisorOptions.defaults());
 * ```
 */

/**
 * Supervisor child specification
 */
typedef ChildSpec = {
    id: String,
    start: {module: String, function: String, args: Array<Dynamic>},
    ?restart: RestartType,
    ?shutdown: ShutdownType,
    ?type: ChildType,
    ?modules: Array<String>
}

/**
 * Child restart strategy
 */
enum RestartType {
    Permanent;    // Always restart
    Temporary;    // Never restart
    Transient;    // Restart only if abnormal exit
}

/**
 * Child shutdown strategy
 */
enum ShutdownType {
    Brutal;       // Kill immediately
    Timeout(ms: Int);  // Wait up to N milliseconds
    Infinity;     // Wait indefinitely
}

/**
 * Child type
 */
enum ChildType {
    Worker;
    Supervisor;
}

/**
 * Supervisor options
 */
typedef SupervisorOptions = {
    ?strategy: SupervisorStrategy,
    ?max_restarts: Int,
    ?max_seconds: Int
}

/**
 * Supervisor restart strategy
 */
enum SupervisorStrategy {
    OneForOne;    // Restart only failed child
    OneForAll;    // Restart all children
    RestForOne;   // Restart failed child and later siblings
    SimpleOneForOne;  // Dynamic children
}

/**
 * Helper class for creating child specifications
 */
class ChildSpec {
    /**
     * Create a worker child spec
     */
    public static function worker(module: String, args: Array<Dynamic>, ?id: String): ChildSpec {
        return {
            id: id != null ? id : module,
            start: {module: module, function: "start_link", args: args},
            restart: Permanent,
            shutdown: Timeout(5000),
            type: Worker,
            modules: [module]
        };
    }
    
    /**
     * Create a supervisor child spec
     */
    public static function supervisor(module: String, args: Array<Dynamic>, ?id: String): ChildSpec {
        return {
            id: id != null ? id : module,
            start: {module: module, function: "start_link", args: args},
            restart: Permanent,
            shutdown: Infinity,
            type: Supervisor,
            modules: [module]
        };
    }
    
    /**
     * Create a temporary worker (won't be restarted)
     */
    public static function tempWorker(module: String, args: Array<Dynamic>, ?id: String): ChildSpec {
        var spec = worker(module, args, id);
        spec.restart = Temporary;
        return spec;
    }
}

/**
 * Helper class for supervisor options
 */
class SupervisorOptions {
    /**
     * Default supervisor options
     */
    public static function defaults(): SupervisorOptions {
        return {
            strategy: OneForOne,
            max_restarts: 3,
            max_seconds: 5
        };
    }
    
    /**
     * Create supervisor options with custom strategy
     */
    public static function withStrategy(strategy: SupervisorStrategy): SupervisorOptions {
        var opts = defaults();
        opts.strategy = strategy;
        return opts;
    }
    
    /**
     * Create supervisor options with custom restart limits
     */
    public static function withLimits(max_restarts: Int, max_seconds: Int): SupervisorOptions {
        var opts = defaults();
        opts.max_restarts = max_restarts;
        opts.max_seconds = max_seconds;
        return opts;
    }
}

/**
 * Type-safe wrapper for Supervisor module functions
 */
@:native("Supervisor")
extern class SupervisorExtern {
    /**
     * Start a supervisor
     */
    static function start_link(children: Array<ChildSpec>, options: SupervisorOptions): Dynamic;
    
    /**
     * Start a child dynamically
     */
    static function start_child(supervisor: Dynamic, child_spec: ChildSpec): Dynamic;
    
    /**
     * Terminate a child
     */
    static function terminate_child(supervisor: Dynamic, child_id: String): Dynamic;
    
    /**
     * Delete a child specification
     */
    static function delete_child(supervisor: Dynamic, child_id: String): Dynamic;
    
    /**
     * Restart a child
     */
    static function restart_child(supervisor: Dynamic, child_id: String): Dynamic;
    
    /**
     * Get child specification
     */
    static function get_childspec(supervisor: Dynamic, child_id: String): Dynamic;
    
    /**
     * Count children
     */
    static function count_children(supervisor: Dynamic): Dynamic;
    
    /**
     * List children
     */
    static function which_children(supervisor: Dynamic): Array<Dynamic>;
}