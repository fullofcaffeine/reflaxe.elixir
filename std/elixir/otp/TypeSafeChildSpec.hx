package elixir.otp;

import elixir.otp.Supervisor.ChildSpecFormat;
import elixir.otp.Supervisor.ChildSpec;

/**
 * Type-safe child specifications for OTP supervisors
 * 
 * Provides compile-time checked child specs that generate proper Elixir child specifications.
 * Each method returns a proper child spec map or module reference that Supervisor.start_link expects.
 * 
 * ## Usage Example
 * 
 * ```haxe
 * var children = [
 *     TypeSafeChildSpec.pubSub("MyApp.PubSub"),
 *     TypeSafeChildSpec.repo("MyApp.Repo", {
 *         database: "myapp_dev",
 *         username: "postgres",
 *         pool_size: 10
 *     }),
 *     TypeSafeChildSpec.endpoint("MyAppWeb.Endpoint"),
 *     TypeSafeChildSpec.telemetry()
 * ];
 * 
 * Supervisor.start_link(children, opts);
 * ```
 * 
 * ## Generated Elixir Code
 * 
 * These methods generate proper child specifications:
 * - Module references: `MyAppWeb.Endpoint`
 * - Tuple specs: `{Phoenix.PubSub, [name: "MyApp.PubSub"]}`
 * - Map specs: `%{id: MyWorker, start: {MyWorker, :start_link, []}}`
 */
class TypeSafeChildSpec {
    
    /**
     * Phoenix PubSub child specification
     * 
     * @param name The PubSub name (e.g., "MyApp.PubSub")
     * @return Child spec for Phoenix.PubSub
     */
    public static function pubSub(name: String): ChildSpecFormat {
        // Phoenix.PubSub expects a keyword list with name
        return ModuleWithConfig("Phoenix.PubSub", [{key: "name", value: name}]);
    }
    
    /**
     * Ecto Repository child specification
     * 
     * @param module The repo module name (e.g., "MyApp.Repo")
     * @param config Optional configuration as keyword list
     * @return Child spec for the repository
     */
    public static function repo(module: String, ?config: Array<{key: String, value: Dynamic}>): ChildSpecFormat {
        if (config != null) {
            return ModuleWithConfig(module, config);
        } else {
            // Just the module reference
            return ModuleRef(module);
        }
    }
    
    /**
     * Phoenix Endpoint child specification
     * 
     * @param module The endpoint module name
     * @return Module reference for the endpoint
     */
    public static function endpoint(module: String): ChildSpecFormat {
        return ModuleRef(module);
    }
    
    /**
     * Telemetry supervisor child specification
     * 
     * @param module The telemetry module name
     * @return Module reference for telemetry
     */
    public static function telemetry(module: String): ChildSpecFormat {
        return ModuleRef(module);
    }
    
    /**
     * Generic worker child specification
     * 
     * @param module The worker module
     * @param args Arguments to pass to start_link
     * @return Child spec for the worker
     */
    public static function worker(module: String, ?args: Array<Dynamic>): ChildSpecFormat {
        if (args != null && args.length > 0) {
            return ModuleWithArgs(module, args);
        } else {
            return ModuleRef(module);
        }
    }
    
    /**
     * Generic supervisor child specification
     * 
     * @param module The supervisor module
     * @param args Arguments to pass to start_link
     * @param opts Additional options for full spec
     * @return Child spec for the supervisor
     */
    public static function supervisor(module: String, ?args: Array<Dynamic>, ?opts: ChildSpec): ChildSpecFormat {
        if (opts != null) {
            // Use full spec with provided options
            var spec = opts;
            spec.id = module;
            spec.start = {module: module, func: "start_link", args: args != null ? args : []};
            if (spec.type == null) spec.type = Supervisor;
            return FullSpec(spec);
        } else if (args != null && args.length > 0) {
            return ModuleWithArgs(module, args);
        } else {
            return ModuleRef(module);
        }
    }
    
    /**
     * Task supervisor child specification
     * 
     * @param name The task supervisor name
     * @return Child spec for Task.Supervisor
     */
    public static function taskSupervisor(name: String): ChildSpecFormat {
        return ModuleWithConfig("Task.Supervisor", [{key: "name", value: name}]);
    }
    
    /**
     * Registry child specification
     * 
     * @param name The registry name
     * @param opts Registry options as keyword list
     * @return Child spec for Registry
     */
    public static function registry(name: String, ?opts: Array<{key: String, value: Dynamic}>): ChildSpecFormat {
        var config = [{key: "name", value: name}];
        if (opts != null) {
            config = config.concat(opts);
        }
        return ModuleWithConfig("Registry", config);
    }
    
    /**
     * Dynamic child specification from a map
     * 
     * @param spec The child spec map
     * @return The child spec as a full specification
     */
    public static function fromMap(spec: ChildSpec): ChildSpecFormat {
        return FullSpec(spec);
    }
    
    /**
     * Create a simple child spec from module and arguments
     * 
     * @param module The module to start
     * @param args Arguments for start_link
     * @return Simple module-based child spec
     */
    public static function simple(module: String, ?args: Array<Dynamic>): ChildSpecFormat {
        if (args != null && args.length > 0) {
            return ModuleWithArgs(module, args);
        } else {
            return ModuleRef(module);
        }
    }
}