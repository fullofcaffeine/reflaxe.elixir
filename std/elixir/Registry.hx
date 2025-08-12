package elixir;

#if (macro || reflaxe_runtime)

/**
 * Registry module extern definitions for Elixir OTP
 * Provides type-safe interfaces for process registry operations
 * 
 * Maps to Elixir's Registry module functions with proper type signatures
 * Essential for process discovery and supervision patterns
 */
@:native("Registry")
extern class Registry {
    
    // Registry startup and supervision
    @:native("Registry.start_link")
    public static function startLink(keys: String, name: String): {_0: String, _1: Dynamic}; // {:ok, pid} | {:error, reason}
    
    @:native("Registry.start_link")
    public static function startLinkWithOptions(keys: String, name: String, options: Map<String, Dynamic>): {_0: String, _1: Dynamic};
    
    @:native("Registry.child_spec")
    public static function childSpec(options: Map<String, Dynamic>): Map<String, Dynamic>; // Child spec for Supervisor
    
    // Process registration
    @:native("Registry.register")
    public static function register(registry: String, key: Dynamic, value: Dynamic): {_0: String, _1: Dynamic}; // {:ok, pid} | {:error, reason}
    
    @:native("Registry.unregister")
    public static function unregister(registry: String, key: Dynamic): String; // Returns :ok
    
    @:native("Registry.unregister_match")
    public static function unregisterMatch(registry: String, key: Dynamic, pattern: Dynamic): String; // Returns :ok
    
    // Process lookup and discovery
    @:native("Registry.lookup")
    public static function lookup(registry: String, key: Dynamic): Array<{_0: Dynamic, _1: Dynamic}>; // [{pid, value}]
    
    @:native("Registry.keys")
    public static function keys(registry: String, pid: Dynamic): Array<Dynamic>; // Keys for specific process
    
    @:native("Registry.values")
    public static function values(registry: String, key: Dynamic, pid: Dynamic): Array<Dynamic>; // Values for key/process
    
    // Registry information and introspection
    @:native("Registry.meta")
    public static function meta(registry: String, key: Dynamic): Dynamic; // Get registry metadata
    
    @:native("Registry.put_meta")
    public static function putMeta(registry: String, key: Dynamic, value: Dynamic): String; // Returns :ok
    
    @:native("Registry.count")
    public static function count(registry: String): Int; // Number of registered processes
    
    @:native("Registry.count_match")
    public static function countMatch(registry: String, key: Dynamic, pattern: Dynamic): Int; // Count matching entries
    
    // Registry monitoring and updates
    @:native("Registry.dispatch")
    public static function dispatch(registry: String, key: Dynamic, callback: Dynamic -> Void): String; // Returns :ok
    
    @:native("Registry.update_value")
    public static function updateValue(registry: String, key: Dynamic, callback: Dynamic -> Dynamic): {_0: String, _1: Dynamic}; // {new_value, old_value} | :error
    
    @:native("Registry.match")
    public static function match(registry: String, key: Dynamic, pattern: Dynamic): Array<{_0: Dynamic, _1: Dynamic}>; // Matching entries
    
    @:native("Registry.select")
    public static function select(registry: String, spec: Array<Dynamic>): Array<Dynamic>; // Select with match spec
    
    // Registry partitioning (for :duplicate registries)
    @:native("Registry.partition")
    public static function partition(registry: String): Int; // Get number of partitions
    
    // Registry guards and constraints (for :unique registries)
    @:native("Registry.compare")
    public static function compare(registry: String, key1: Dynamic, key2: Dynamic): String; // :lt | :eq | :gt
    
    // Registry status and monitoring
    @:native("Registry.info")
    public static function info(registry: String): Map<String, Dynamic>; // Registry information
    
    // Common registry key types for unique registries
    public static inline var UNIQUE: String = "unique";
    public static inline var DUPLICATE: String = "duplicate";
    
    // Common registry options
    public static inline function uniqueRegistry(name: String): Map<String, Dynamic> {
        return ["keys" => UNIQUE, "name" => name];
    }
    
    public static inline function duplicateRegistry(name: String): Map<String, Dynamic> {
        return ["keys" => DUPLICATE, "name" => name];
    }
    
    public static inline function registryWithPartitions(name: String, partitions: Int): Map<String, Dynamic> {
        return ["keys" => UNIQUE, "name" => name, "partitions" => partitions];
    }
    
    // Helper for common registration pattern
    public static inline function registerUnique<T>(registry: String, key: T, value: Dynamic = null): {_0: String, _1: Dynamic} {
        return register(registry, key, value != null ? value : key);
    }
    
    // Helper for process discovery
    public static inline function findProcess<T>(registry: String, key: T): Null<Dynamic> {
        var results = lookup(registry, key);
        return results.length > 0 ? results[0]._0 : null; // Return first pid or null
    }
}

#end