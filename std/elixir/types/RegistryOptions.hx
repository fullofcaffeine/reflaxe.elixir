package elixir.types;

/**
 * Type-safe options for Registry.start_link
 * 
 * Provides compile-time validation of Registry configuration options.
 */
typedef RegistryOptions = {
    /**
     * The type of keys: :unique or :duplicate
     * :unique - each key can only be registered once
     * :duplicate - multiple processes can register under the same key
     */
    keys: RegistryType,
    
    /**
     * The registry name (atom or via tuple)
     */
    name: Dynamic,
    
    /**
     * Number of partitions for the registry
     * Improves concurrent access performance
     * Default: System.schedulers_online()
     */
    ?partitions: Int,
    
    /**
     * Metadata to store with the registry
     */
    ?meta: Array<{key: Dynamic, value: Dynamic}>,
    
    /**
     * Whether to compress ETS tables
     * Can reduce memory usage for large registries
     */
    ?compressed: Bool,
    
    /**
     * Custom listener modules for registry events
     */
    ?listeners: Array<Dynamic>
}

/**
 * Registry key types
 */
enum RegistryType {
    /**
     * Each key can only be registered once
     * Compiles to: :unique
     */
    Unique;
    
    /**
     * Multiple processes can register under the same key
     * Compiles to: :duplicate
     */
    Duplicate;
}

/**
 * Helper class for building Registry options
 */
class RegistryOptionsBuilder {
    /**
     * Create options for a unique registry
     */
    public static inline function unique(name: String): RegistryOptions {
        return {
            keys: Unique,
            name: untyped __elixir__('String.to_atom($name)')
        };
    }
    
    /**
     * Create options for a duplicate registry
     */
    public static inline function duplicate(name: String): RegistryOptions {
        return {
            keys: Duplicate,
            name: untyped __elixir__('String.to_atom($name)')
        };
    }
    
    /**
     * Create options with custom partitions
     */
    public static inline function withPartitions(options: RegistryOptions, partitions: Int): RegistryOptions {
        options.partitions = partitions;
        return options;
    }
    
    /**
     * Create options with compression
     */
    public static inline function withCompression(options: RegistryOptions): RegistryOptions {
        options.compressed = true;
        return options;
    }
    
    /**
     * Add metadata to registry
     */
    public static inline function withMeta(options: RegistryOptions, key: Dynamic, value: Dynamic): RegistryOptions {
        if (options.meta == null) options.meta = [];
        options.meta.push({key: key, value: value});
        return options;
    }
}