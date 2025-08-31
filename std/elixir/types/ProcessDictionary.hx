package elixir.types;

/**
 * Type-safe abstraction for the process dictionary
 * 
 * The process dictionary in Elixir/Erlang can store any term as both keys and values.
 * This abstract provides a type-safe interface while maintaining flexibility.
 * 
 * Usage:
 * ```haxe
 * var dict: ProcessDictionary = Process.get();
 * var value = dict.get("my_key");
 * dict.put("my_key", "my_value");
 * ```
 */
abstract ProcessDictionary(Map<Dynamic, Dynamic>) from Map<Dynamic, Dynamic> to Map<Dynamic, Dynamic> {
    /**
     * Create a new ProcessDictionary wrapper
     */
    public inline function new(dict: Map<Dynamic, Dynamic>) {
        this = dict;
    }
    
    /**
     * Get a value from the dictionary with a typed key
     */
    @:generic
    public inline function get<K, V>(key: K): Null<V> {
        return cast this.get(key);
    }
    
    /**
     * Put a typed key-value pair into the dictionary
     */
    @:generic
    public inline function put<K, V>(key: K, value: V): Null<V> {
        var previous = this.get(key);
        this.set(key, value);
        return cast previous;
    }
    
    /**
     * Check if a key exists in the dictionary
     */
    @:generic
    public inline function exists<K>(key: K): Bool {
        return this.exists(key);
    }
    
    /**
     * Remove a key from the dictionary
     */
    @:generic
    public inline function remove<K, V>(key: K): Null<V> {
        var value = this.get(key);
        this.remove(key);
        return cast value;
    }
    
    /**
     * Get all keys from the dictionary
     */
    public inline function keys(): Array<Dynamic> {
        var result = [];
        for (key in this.keys()) {
            result.push(key);
        }
        return result;
    }
    
    /**
     * Convert to iterator for iteration
     */
    public inline function iterator(): Iterator<{key: Dynamic, value: Dynamic}> {
        var iter = this.keyValueIterator();
        return {
            hasNext: () -> iter.hasNext(),
            next: () -> {
                var kv = iter.next();
                return {key: kv.key, value: kv.value};
            }
        };
    }
}