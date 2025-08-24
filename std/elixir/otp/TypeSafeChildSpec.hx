package elixir.otp;

import elixir.otp.Supervisor.ChildSpec;
import elixir.otp.Supervisor.RestartType;
import elixir.otp.Supervisor.ShutdownType;

/**
 * Type-safe child specifications for OTP supervisors
 * 
 * This module provides compile-time type safety for child specs, replacing
 * the string-based approach with proper type checking and IntelliSense support.
 * 
 * ## Benefits of Type-Safe Child Specs
 * 
 * - **Compile-time validation**: Module names and configurations are type-checked
 * - **IntelliSense support**: Full autocomplete for module configurations
 * - **Refactoring safety**: IDE can track module usage and renames
 * - **Documentation**: Self-documenting with proper type information
 * - **Error prevention**: Catch typos and misconfigurations at compile time
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Type-safe child specs with full autocomplete
 * var children = [
 *     TypeSafeChildSpec.PubSub("TodoApp.PubSub"),
 *     TypeSafeChildSpec.Endpoint(4000),
 *     TypeSafeChildSpec.Repo({
 *         database: "todo_app_dev",
 *         pool_size: 10
 *     }),
 *     TypeSafeChildSpec.Custom(MyWorker, {
 *         timeout: 5000,
 *         retries: 3
 *     }, Permanent)
 * ];
 * ```
 * 
 * ## Migration from Legacy ChildSpec
 * 
 * This type-safe approach replaces the legacy string-based ChildSpec:
 * 
 * ```haxe
 * // ❌ OLD: String-based (no type safety)
 * {
 *     id: "Phoenix.PubSub",
 *     start: {module: "Phoenix.PubSub", func: "start_link", args: [{name: "App.PubSub"}]}
 * }
 * 
 * // ✅ NEW: Type-safe
 * TypeSafeChildSpec.PubSub("App.PubSub")
 * ```
 * 
 * @see documentation/OTP_CHILD_SPECS.md - Complete child spec documentation
 */

/**
 * Configuration for Ecto repository child specs
 */
typedef RepoConfig = {
    ?database: String,
    ?username: String,
    ?password: String,
    ?hostname: String,
    ?port: Int,
    ?pool_size: Int,
    ?timeout: Int,
    ?ownership_timeout: Int,
    ?queue_target: Int,
    ?queue_interval: Int
}

/**
 * Configuration for Phoenix endpoint child specs
 */
typedef EndpointConfig = {
    ?port: Int,
    ?ip: String,
    ?protocol_options: Dynamic,
    ?dispatch: Dynamic,
    ?ref: String
}

/**
 * Configuration for telemetry child specs
 */
typedef TelemetryConfig = {
    ?metrics: Array<Dynamic>,
    ?reporter_options: Dynamic
}

/**
 * Configuration for Phoenix Presence child specs
 */
typedef PresenceConfig = {
    name: String,
    ?pubsub_server: String
}

/**
 * Type-safe child specification enum
 * 
 * Each variant represents a specific type of child process with
 * properly typed configuration options.
 */
enum TypeSafeChildSpec {
    /**
     * Phoenix.PubSub child spec
     * 
     * @param name The name of the PubSub system (e.g., "MyApp.PubSub")
     */
    PubSub(name: String);
    
    /**
     * Ecto repository child spec
     * 
     * @param config Optional repository configuration
     */
    Repo(?config: RepoConfig);
    
    /**
     * Phoenix endpoint child spec
     * 
     * @param port Optional port number (defaults to 4000)
     * @param config Optional endpoint configuration
     */
    Endpoint(?port: Int, ?config: EndpointConfig);
    
    /**
     * Telemetry supervisor child spec
     * 
     * @param config Optional telemetry configuration
     */
    Telemetry(?config: TelemetryConfig);
    
    /**
     * Phoenix Presence child spec
     * 
     * @param config Presence configuration with required name
     */
    Presence(config: PresenceConfig);
    
    /**
     * Generic child spec for custom modules
     * 
     * @param T The type of the initialization argument
     * @param module The module class reference
     * @param args Typed initialization arguments
     * @param restart Optional restart strategy (defaults to Permanent)
     * @param shutdown Optional shutdown strategy (defaults to Timeout(5000))
     */
    Custom<T>(
        module: Class<T>,
        args: T,
        ?restart: RestartType,
        ?shutdown: ShutdownType
    );
    
    /**
     * Legacy compatibility for migrating from string-based child specs
     * 
     * @param spec Legacy child spec map
     * @deprecated Use typed variants instead
     */
    @:deprecated("Use typed child spec variants instead")
    Legacy(spec: ChildSpec);
}

/**
 * Builder functions for common child spec patterns
 * 
 * These provide convenient factory methods for creating type-safe child specs
 * with sensible defaults and proper Phoenix conventions.
 */
class TypeSafeChildSpecBuilder {
    
    /**
     * Create a Phoenix.PubSub child spec
     * 
     * @param appName Application name (e.g., "TodoApp")
     * @return TypeSafeChildSpec for Phoenix.PubSub
     */
    public static function pubsub(appName: String): TypeSafeChildSpec {
        return PubSub(appName + ".PubSub");
    }
    
    /**
     * Create an Ecto repository child spec
     * 
     * @param appName Application name (e.g., "TodoApp")  
     * @param config Optional repository configuration
     * @return TypeSafeChildSpec for repository
     */
    public static function repo(appName: String, ?config: RepoConfig): TypeSafeChildSpec {
        return Repo(config);
    }
    
    /**
     * Create a Phoenix endpoint child spec
     * 
     * @param appName Application name (e.g., "TodoApp")
     * @param port Optional port number (defaults to 4000)
     * @param config Optional endpoint configuration
     * @return TypeSafeChildSpec for endpoint
     */
    public static function endpoint(appName: String, ?port: Int, ?config: EndpointConfig): TypeSafeChildSpec {
        return Endpoint(port ?? 4000, config);
    }
    
    /**
     * Create a telemetry supervisor child spec
     * 
     * @param appName Application name (e.g., "TodoApp")
     * @param config Optional telemetry configuration
     * @return TypeSafeChildSpec for telemetry
     */
    public static function telemetry(appName: String, ?config: TelemetryConfig): TypeSafeChildSpec {
        return Telemetry(config);
    }
    
    /**
     * Create a Phoenix Presence child spec
     * 
     * @param appName Application name (e.g., "TodoApp")
     * @param pubsubName Optional PubSub server name
     * @return TypeSafeChildSpec for presence
     */
    public static function presence(appName: String, ?pubsubName: String): TypeSafeChildSpec {
        return Presence({
            name: '${appName}.Presence',
            pubsub_server: pubsubName ?? '${appName}.PubSub'
        });
    }
    
    /**
     * Create a worker child spec for custom modules
     * 
     * @param T The type of the worker's initialization argument
     * @param module The worker module class
     * @param args Initialization arguments for the worker
     * @return TypeSafeChildSpec for custom worker
     */
    public static function worker<T>(module: Class<T>, args: T): TypeSafeChildSpec {
        return Custom(module, args, Permanent, Timeout(5000));
    }
    
    /**
     * Create a supervisor child spec for custom modules
     * 
     * @param T The type of the supervisor's initialization argument
     * @param module The supervisor module class
     * @param args Initialization arguments for the supervisor
     * @return TypeSafeChildSpec for custom supervisor
     */
    public static function supervisor<T>(module: Class<T>, args: T): TypeSafeChildSpec {
        return Custom(module, args, Permanent, Infinity);
    }
}

/**
 * Utilities for working with type-safe child specs
 */
class TypeSafeChildSpecTools {
    
    /**
     * Convert TypeSafeChildSpec to legacy ChildSpec format
     * 
     * This is used during the migration period when the compiler
     * still expects the old string-based format.
     * 
     * @param spec Type-safe child spec
     * @param appName Application name for module resolution
     * @return Legacy ChildSpec format
     */
    public static function toLegacy(spec: TypeSafeChildSpec, appName: String): ChildSpec {
        return switch (spec) {
            case PubSub(name):
                {
                    id: "Phoenix.PubSub",
                    start: {
                        module: "Phoenix.PubSub",
                        func: "start_link",
                        args: [{name: name}]
                    }
                };
                
            case Repo(config):
                var repoModule = '${appName}.Repo';
                var args = config != null ? [config] : [];
                {
                    id: repoModule,
                    start: {
                        module: repoModule,
                        func: "start_link",
                        args: args
                    }
                };
                
            case Endpoint(port, config):
                var endpointModule = '${appName}Web.Endpoint';
                var args = [];
                if (port != null || config != null) {
                    var endpointConfig: Dynamic = {};
                    if (port != null) endpointConfig.port = port;
                    if (config != null) {
                        for (field in Reflect.fields(config)) {
                            Reflect.setField(endpointConfig, field, Reflect.field(config, field));
                        }
                    }
                    args = [endpointConfig];
                }
                {
                    id: endpointModule,
                    start: {
                        module: endpointModule,
                        func: "start_link",
                        args: args
                    }
                };
                
            case Telemetry(config):
                var telemetryModule = '${appName}Web.Telemetry';
                var args = config != null ? [config] : [];
                {
                    id: telemetryModule,
                    start: {
                        module: telemetryModule,
                        func: "start_link",
                        args: args
                    }
                };
                
            case Presence(config):
                var presenceModule = '${appName}.Presence';
                {
                    id: presenceModule,
                    start: {
                        module: presenceModule,
                        func: "start_link",
                        args: [config]
                    }
                };
                
            case Custom(module, args, restart, shutdown):
                var moduleClass = cast(module, Class<Dynamic>);
                var moduleName = Type.getClassName(moduleClass);
                {
                    id: moduleName,
                    start: {
                        module: moduleName,
                        func: "start_link",
                        args: [args]
                    },
                    restart: restart,
                    shutdown: shutdown
                };
                
            case Legacy(spec):
                spec;
        };
    }
    
    /**
     * Get the module name for a type-safe child spec
     * 
     * @param spec Type-safe child spec
     * @param appName Application name for module resolution
     * @return Module name string
     */
    public static function getModuleName(spec: TypeSafeChildSpec, appName: String): String {
        return switch (spec) {
            case PubSub(_): "Phoenix.PubSub";
            case Repo(_): '${appName}.Repo';
            case Endpoint(_, _): '${appName}Web.Endpoint';
            case Telemetry(_): '${appName}Web.Telemetry';
            case Presence(_): '${appName}.Presence';
            case Custom(module, _, _, _): Type.getClassName(cast(module, Class<Dynamic>));
            case Legacy(spec): spec.id;
        };
    }
    
    /**
     * Check if a child spec should use modern tuple format
     * 
     * @param spec Type-safe child spec
     * @return True if should generate tuple format
     */
    public static function usesTupleFormat(spec: TypeSafeChildSpec): Bool {
        return switch (spec) {
            case PubSub(_): true;        // {Phoenix.PubSub, name: ...}
            case Repo(_): true;          // MyApp.Repo or {MyApp.Repo, config}
            case Endpoint(_, _): true;   // MyAppWeb.Endpoint or {MyAppWeb.Endpoint, config}
            case Telemetry(_): true;     // MyAppWeb.Telemetry
            case Presence(_): true;      // {MyApp.Presence, config}
            case Custom(_, _, _, _): false;  // Custom specs use map format
            case Legacy(_): false;       // Legacy specs use map format
        };
    }
    
    /**
     * Validate a type-safe child spec configuration
     * 
     * @param spec Type-safe child spec to validate
     * @return Array of validation errors (empty if valid)
     */
    public static function validate(spec: TypeSafeChildSpec): Array<String> {
        var errors: Array<String> = [];
        
        switch (spec) {
            case PubSub(name):
                if (name == null || name == "") {
                    errors.push("PubSub name cannot be empty");
                }
                if (name != null && name.indexOf(".") == -1) {
                    errors.push("PubSub name should follow 'AppName.PubSub' convention");
                }
                
            case Repo(_):
                // Repo validation is optional since many configs are environment-specific
                
            case Endpoint(port, _):
                if (port != null && (port < 1 || port > 65535)) {
                    errors.push("Endpoint port must be between 1 and 65535");
                }
                
            case Telemetry(_):
                // Telemetry validation is optional
                
            case Presence(config):
                if (config.name == null || config.name == "") {
                    errors.push("Presence name is required");
                }
                
            case Custom(module, args, restart, shutdown):
                if (module == null) {
                    errors.push("Custom child spec module cannot be null");
                }
                
            case Legacy(spec):
                // Legacy specs use old validation logic
                if (spec.id == null || spec.id == "") {
                    errors.push("Legacy child spec id cannot be empty");
                }
        }
        
        return errors;
    }
}

/**
 * Abstract type for arrays of type-safe child specs
 * 
 * This provides a convenient way to work with collections of child specs
 * while maintaining type safety and providing utility methods.
 */
abstract TypeSafeChildSpecArray(Array<TypeSafeChildSpec>) from Array<TypeSafeChildSpec> to Array<TypeSafeChildSpec> {
    
    /**
     * Convert to legacy ChildSpec array for compiler compatibility
     * 
     * @param appName Application name for module resolution
     * @return Array of legacy ChildSpec objects
     */
    public function toLegacyArray(appName: String): Array<ChildSpec> {
        return this.map(spec -> TypeSafeChildSpecTools.toLegacy(spec, appName));
    }
    
    /**
     * Validate all child specs in the array
     * 
     * @return Array of validation errors (empty if all valid)
     */
    public function validateAll(): Array<String> {
        var errors: Array<String> = [];
        for (i in 0...this.length) {
            var specErrors = TypeSafeChildSpecTools.validate(this[i]);
            for (error in specErrors) {
                errors.push('Child spec ${i}: ${error}');
            }
        }
        return errors;
    }
    
    /**
     * Get module names for all child specs
     * 
     * @param appName Application name for module resolution
     * @return Array of module name strings
     */
    public function getModuleNames(appName: String): Array<String> {
        return this.map(spec -> TypeSafeChildSpecTools.getModuleName(spec, appName));
    }
    
    /**
     * Filter child specs by constructor name
     * 
     * @param constructorName Name of the enum constructor to filter by (e.g., "PubSub")
     * @return Array of matching child specs
     */
    public function filterByConstructor(constructorName: String): Array<TypeSafeChildSpec> {
        return this.filter(spec -> Type.enumConstructor(spec) == constructorName);
    }
}