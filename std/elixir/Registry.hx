package elixir;

import elixir.types.Result;
import elixir.types.RegistryKey;
import elixir.types.RegistryOptions;
import elixir.types.Pid;
import elixir.types.Term;

#if (macro || reflaxe_runtime)

/**
 * Registry module extern definitions for Elixir OTP
 * Provides type-safe interfaces for process registry operations
 * 
 * Registry is a local, decentralized, and scalable key-value store
 * for processes. It allows processes to register under a given key
 * and enables process discovery via that key.
 * 
 * ## Type Parameters
 * - `K`: The type of registry keys
 * - `V`: The type of values stored with registrations
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Start a unique registry
 * var result = Registry.startLink(RegistryOptionsBuilder.unique("MyRegistry"));
 * 
 * // Register current process
 * Registry.register("MyRegistry", "user_service", self());
 * 
 * // Look up processes
 * var processes = Registry.lookup("MyRegistry", "user_service");
 * for (p in processes) {
 *     trace("Found process: " + p.pid);
 * }
 * ```
 * 
 * Maps to Elixir's Registry module functions with proper type signatures
 * Essential for process discovery and supervision patterns
 */
@:native("Registry")
extern class Registry {
    
    // Registry startup and supervision with type-safe options
    @:native("Registry.start_link")
    public static function startLink(options: RegistryOptions): Result<Pid, String>;
    
    @:native("Registry.child_spec")
    public static function childSpec(options: RegistryOptions): Map<String, Term>;
    
    // Process registration with generics
    @:native("Registry.register")
    public static function register<K, V>(registry: String, key: K, value: V): Result<Pid, RegistryError>;
    
    @:native("Registry.unregister")
    public static function unregister<K>(registry: String, key: K): Void;
    
    @:native("Registry.unregister_match")
    public static function unregisterMatch<K, V>(registry: String, key: K, pattern: V): Void;
    
    // Process lookup and discovery with type safety
    @:native("Registry.lookup")
    public static function lookup<K, V>(registry: String, key: K): Array<{pid: Pid, value: V}>;
    
    @:native("Registry.keys")
    public static function keys<K>(registry: String, pid: Pid): Array<K>;
    
    @:native("Registry.values")
    public static function values<K, V>(registry: String, key: K, pid: Pid): Array<V>;
    
    // Registry metadata with generics
    @:native("Registry.meta")
    public static function meta<M>(registry: String, key: String): Null<M>;
    
    @:native("Registry.put_meta")
    public static function putMeta<M>(registry: String, key: String, value: M): Void;
    
    // Registry information and counting
    @:native("Registry.count")
    public static function count(registry: String): Int;
    
    @:native("Registry.count_match")
    public static function countMatch<K, V>(registry: String, key: K, pattern: V): Int;
    
    // Registry operations with callbacks
    @:native("Registry.dispatch")
    public static function dispatch<K, V>(registry: String, key: K, callback: (Array<{pid: Pid, value: V}>) -> Void): Void;
    
    @:native("Registry.update_value")
    public static function updateValue<K, V>(registry: String, key: K, callback: (V) -> V): Result<{newValue: V, oldValue: V}, String>;
    
    // Pattern matching with type safety
    @:native("Registry.match")
    public static function match<K, V>(registry: String, key: K, pattern: V): Array<{pid: Pid, value: V}>;
    
    @:native("Registry.select")
    public static function select<T>(registry: String, spec: Array<Term>): Array<T>;
    
    // Registry partitioning
    @:native("Registry.partition")
    public static function partition(registry: String): Int;
    
    // Registry comparison (for ordered keys)
    @:native("Registry.compare")
    public static function compare<K>(registry: String, key1: K, key2: K): ComparisonResult;
    
    // Registry status
    @:native("Registry.info")
    public static function info(registry: String): RegistryInfo;
    
    // Helper functions for common patterns
    
    /**
     * Register current process under a key
     * @param registry The registry name
     * @param key The key to register under
     * @param value Optional value to store (defaults to pid)
     */
    public static inline function registerSelf<K, V>(registry: String, key: K, ?value: V): Result<Pid, RegistryError> {
        return register(registry, key, value != null ? value : untyped __elixir__('self()'));
    }
    
    /**
     * Find first process registered under a key
     * @param registry The registry name
     * @param key The key to look up
     * @return The first process pid or null if none found
     */
    public static inline function findProcess<K>(registry: String, key: K): Null<Pid> {
        var results = lookup(registry, key);
        return results.length > 0 ? results[0].pid : null;
    }
    
    /**
     * Find all processes registered under a key
     * @param registry The registry name
     * @param key The key to look up
     * @return Array of process pids
     */
    public static inline function findAllProcesses<K>(registry: String, key: K): Array<Pid> {
        var results = lookup(registry, key);
        return [for (r in results) r.pid];
    }
    
    /**
     * Check if a key is registered
     * @param registry The registry name
     * @param key The key to check
     * @return True if at least one process is registered under the key
     */
    public static inline function isRegistered<K>(registry: String, key: K): Bool {
        return lookup(registry, key).length > 0;
    }
    
    /**
     * Register with automatic unregister on exit
     * @param registry The registry name
     * @param key The key to register under
     * @param value The value to store
     * @return Registration result
     */
    public static inline function registerTemporary<K, V>(registry: String, key: K, value: V): Result<Pid, RegistryError> {
        // The registry automatically handles process exit
        return register(registry, key, value);
    }
}

/**
 * Registry error types
 */
enum RegistryError {
    /**
     * Key is already registered (for unique registries)
     * Compiles to: {:already_registered, pid}
     */
    AlreadyRegistered(pid: Pid);
    
    /**
     * Generic registration error
     * Compiles to: {:error, reason}
     */
    Error(reason: String);
}

/**
 * Comparison results for Registry.compare
 */
enum ComparisonResult {
    /**
     * First key is less than second
     * Compiles to: :lt
     */
    LessThan;
    
    /**
     * Keys are equal
     * Compiles to: :eq
     */
    Equal;
    
    /**
     * First key is greater than second
     * Compiles to: :gt
     */
    GreaterThan;
}

/**
 * Registry information structure
 */
typedef RegistryInfo = {
    /**
     * Registry name
     */
    name: String,
    
    /**
     * Key type (:unique or :duplicate)
     */
    keys: String,
    
    /**
     * Number of partitions
     */
    partitions: Int,
    
    /**
     * Number of registered processes
     */
    size: Int,
    
    /**
     * Registry metadata
     */
    meta: Map<String, Term>
}

#end
