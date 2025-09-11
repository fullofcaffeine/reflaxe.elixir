package;


/**
 * Static extension class providing functional operations for Map<K,V>
 * 
 * Usage: `using MapTools;` then call methods on Map instances:
 *   var map = ["key" => "value"];
 *   var filtered = map.filter((k, v) -> v.length > 3);
 *   var keys = map.keys();
 * 
 * All methods maintain functional programming principles:
 * - Immutable operations (return new maps)
 * - Type-safe transformations  
 * - Cross-platform compatibility
 * - Compile to idiomatic target code (Elixir Map module, etc.)
 */
class MapTools {
    
    /**
     * Filter map entries based on key-value predicate
     * @param map The map to filter
     * @param predicate Function that takes (key, value) and returns boolean
     * @return New map containing only entries that match predicate
     */
    // TODO: Fix type inference issue with Map<K,V> generic return types
    // Temporarily commented out filter method
    
    /**
     * Transform map values while preserving keys
     * @param map The map to transform
     * @param transform Function that takes (key, value) and returns new value
     * @return New map with transformed values
     */
    // TODO: Fix type inference issue with Map<K,U> generic return types
    // Temporarily commented out map method
    
    /**
     * Transform map keys while preserving values
     * @param map The map to transform
     * @param transform Function that takes (key, value) and returns new key
     * @return New map with transformed keys
     */
    // TODO: Fix type inference issue with Map<J,V> generic return types
    // Temporarily commented out mapKeys method
    
    /**
     * Fold/reduce map entries into a single value
     * @param map The map to reduce
     * @param initial Initial accumulator value
     * @param reducer Function that takes (accumulator, key, value) and returns new accumulator
     * @return Final accumulated value
     */
    public static function reduce<K, V, A>(map: Map<K, V>, initial: A, reducer: (A, K, V) -> A): A {
        return untyped __elixir__("Enum.reduce({0}, {1}, fn {k, v}, acc -> {2}.(acc, k, v) end)", map, initial, reducer);
    }
    
    /**
     * Check if any entry matches the predicate
     * @param map The map to check
     * @param predicate Function that takes (key, value) and returns boolean
     * @return True if any entry matches, false otherwise
     */
    public static function any<K, V>(map: Map<K, V>, predicate: (K, V) -> Bool): Bool {
        return untyped __elixir__("Enum.any?({0}, fn {k, v} -> {1}.(k, v) end)", map, predicate);
    }
    
    /**
     * Check if all entries match the predicate
     * @param map The map to check
     * @param predicate Function that takes (key, value) and returns boolean
     * @return True if all entries match, false otherwise
     */
    public static function all<K, V>(map: Map<K, V>, predicate: (K, V) -> Bool): Bool {
        return untyped __elixir__("Enum.all?({0}, fn {k, v} -> {1}.(k, v) end)", map, predicate);
    }
    
    /**
     * Find first entry that matches predicate
     * @param map The map to search
     * @param predicate Function that takes (key, value) and returns boolean
     * @return Entry as {key: K, value: V} or null if not found
     */
    public static function find<K, V>(map: Map<K, V>, predicate: (K, V) -> Bool): Null<{key: K, value: V}> {
        return untyped __elixir__("case Enum.find({0}, fn {k, v} -> {1}.(k, v) end) do\n      {k, v} -> %{key: k, value: v}\n      nil -> nil\n    end", map, predicate);
    }
    
    /**
     * Get all keys from the map
     * @param map The map to get keys from
     * @return Array of all keys
     */
    public static function keys<K, V>(map: Map<K, V>): Array<K> {
        return untyped __elixir__("Map.keys({0}) |> Enum.to_list()", map);
    }
    
    /**
     * Get all values from the map
     * @param map The map to get values from  
     * @return Array of all values
     */
    public static function values<K, V>(map: Map<K, V>): Array<V> {
        return untyped __elixir__("Map.values({0}) |> Enum.to_list()", map);
    }
    
    /**
     * Convert map to array of key-value pairs
     * @param map The map to convert
     * @return Array of {key: K, value: V} objects
     */
    public static function toArray<K, V>(map: Map<K, V>): Array<{key: K, value: V}> {
        return untyped __elixir__("Enum.map({0}, fn {k, v} -> %{key: k, value: v} end)", map);
    }
    
    /**
     * Create map from array of key-value pairs
     * @param pairs Array of {key: K, value: V} objects
     * @return New map containing all pairs
     */
    // TODO: Fix type inference issue with Map<K,V> generic return types
    // Temporarily commented out fromArray method
    
    /**
     * Merge two maps, with second map values taking precedence
     * @param map1 First map
     * @param map2 Second map (values override first map)
     * @return New map containing merged entries
     */
    // TODO: Fix type inference issue with Map<K,V> generic return types
    // Temporarily commented out merge method
    
    /**
     * Check if map is empty
     * @param map The map to check
     * @return True if map has no entries, false otherwise
     */
    public static function isEmpty<K, V>(map: Map<K, V>): Bool {
        return untyped __elixir__("Enum.empty?({0})", map);
    }
    
    /**
     * Get the size/length of the map
     * @param map The map to measure
     * @return Number of entries in the map
     */
    public static function size<K, V>(map: Map<K, V>): Int {
        return untyped __elixir__("map_size({0})", map);
    }
}