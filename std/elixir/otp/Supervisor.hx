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
 * Child specification formats accepted by Supervisor.start_link
 * 
 * Elixir supervisors accept multiple formats:
 * - Module reference: `MyWorker`
 * - Tuple with args: `{MyWorker, [arg1, arg2]}`
 * - Full map specification
 * 
 * @:elixirIdiomatic - This annotation tells the compiler to generate
 * proper OTP child spec formats instead of generic tagged tuples.
 * This is necessary because OTP expects specific formats like
 * {Phoenix.PubSub, [name: "MyApp"]} rather than {:module_with_config, ...}
 */
@:elixirIdiomatic
enum ChildSpecFormat {
    /**
     * Simple module reference
     * Compiles to: MyModule
     */
    ModuleRef(module: String);
    
    /**
     * Module with arguments
     * Compiles to: {MyModule, args}
     */
    ModuleWithArgs(module: String, args: Array<Dynamic>);
    
    /**
     * Module with keyword list config
     * Compiles to: {MyModule, [name: "foo", pool_size: 10]}
     */
    ModuleWithConfig(module: String, config: Array<{key: String, value: Dynamic}>);
    
    /**
     * Full child specification map
     */
    FullSpec(spec: ChildSpec);
}

/**
 * Supervisor child specification
 */
typedef ChildSpec = {
    id: String,
    start: {module: String, func: String, args: Array<Dynamic>},
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
 * 
 * @:elixirIdiomatic indicates these should compile to atoms like :one_for_one
 * instead of tuples like {0}
 */
@:elixirIdiomatic
enum SupervisorStrategy {
    OneForOne;    // Restart only failed child → :one_for_one
    OneForAll;    // Restart all children → :one_for_all
    RestForOne;   // Restart failed child and later siblings → :rest_for_one
    SimpleOneForOne;  // Dynamic children → :simple_one_for_one
}

/**
 * Helper class for creating child specifications
 */
class ChildSpecBuilder {
    /**
     * Create a worker child spec
     */
    public static function worker(module: String, args: Array<Dynamic>, ?id: String): ChildSpec {
        return {
            id: id != null ? id : module,
            start: {module: module, func: "start_link", args: args},
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
            start: {module: module, func: "start_link", args: args},
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
class SupervisorOptionsBuilder {
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
        return {
            strategy: strategy,
            max_restarts: 3,
            max_seconds: 5
        };
    }
    
    /**
     * Create supervisor options with custom restart limits
     */
    public static function withLimits(maxRestarts: Int, maxSeconds: Int): SupervisorOptions {
        return {
            strategy: OneForOne,
            max_restarts: maxRestarts,
            max_seconds: maxSeconds
        };
    }
}

/**
 * Type-safe wrapper for Supervisor module functions
 */
@:native("Supervisor")
extern class SupervisorExtern {
    /**
     * Start a supervisor
     * 
     * @param children Array of child specifications in any accepted format
     * @param options Supervisor options
     */
    @:native("start_link")
    static function startLink(children: Array<ChildSpecFormat>, options: SupervisorOptions): Dynamic;
    
    /**
     * Start a child dynamically
     */
    @:native("start_child")
    static function startChild(supervisor: Dynamic, child_spec: ChildSpec): Dynamic;
    
    /**
     * Terminate a child
     */
    @:native("terminate_child")
    static function terminateChild(supervisor: Dynamic, child_id: String): Dynamic;
    
    /**
     * Delete a child specification
     */
    @:native("delete_child")
    static function deleteChild(supervisor: Dynamic, child_id: String): Dynamic;
    
    /**
     * Restart a child
     */
    @:native("restart_child")
    static function restartChild(supervisor: Dynamic, child_id: String): Dynamic;
    
    /**
     * Get child specification
     */
    @:native("get_childspec")
    static function getChildspec(supervisor: Dynamic, child_id: String): Dynamic;
    
    /**
     * Count children
     */
    @:native("count_children")
    static function countChildren(supervisor: Dynamic): Dynamic;
    
    /**
     * List children
     */
    @:native("which_children")
    static function whichChildren(supervisor: Dynamic): Array<Dynamic>;
}