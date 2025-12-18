package elixir.types;

import elixir.Kernel;

/**
 * Type-safe abstraction for Registry keys
 * 
 * RegistryKey provides a flexible way to use any type as a registry key,
 * with automatic conversions for common types like strings and integers.
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // String keys
 * var key1: RegistryKey = "user_service";
 * Registry.register("MyRegistry", key1, self());
 * 
 * // Integer keys
 * var key2: RegistryKey = 12345;
 * Registry.register("MyRegistry", key2, self());
 * 
 * // Tuple keys for compound identification
 * var key3: RegistryKey = RegistryKey.tuple("user", 123);
 * Registry.register("MyRegistry", key3, self());
 * ```
 * 
 * ## Type Safety Benefits
 * 
 * - **Flexible key types**: Use any type as a registry key
 * - **Automatic conversions**: Strings, ints, and tuples work seamlessly
 * - **Compile-time validation**: Can't accidentally use incompatible key types
 * - **Zero overhead**: Compiles to native Elixir terms
 */
abstract RegistryKey(Term) from Term to Term {
    /**
     * Create a new RegistryKey from any value
     */
    public inline function new(key: Term) {
        this = key;
    }
    
    /**
     * Convert from String to RegistryKey
     * Enables: `var key: RegistryKey = "my_key";`
     */
    @:from
    public static inline function fromString(str: String): RegistryKey {
        // Registry keys can be any term; using strings avoids atom leaks.
        return new RegistryKey(str);
    }
    
    /**
     * Convert from Int to RegistryKey
     * Enables: `var key: RegistryKey = 123;`
     */
    @:from
    public static inline function fromInt(i: Int): RegistryKey {
        return new RegistryKey(i);
    }
    
    /**
     * Convert from tuple to RegistryKey
     * Useful for compound keys
     */
    @:from
    public static inline function fromTuple2<A, B>(t: {_0: A, _1: B}): RegistryKey {
        return new RegistryKey(t);
    }
    
    /**
     * Create a tuple key from two values
     * @param a First element of the tuple
     * @param b Second element of the tuple
     */
    public static inline function tuple<A, B>(a: A, b: B): RegistryKey {
        return new RegistryKey({_0: a, _1: b});
    }
    
    /**
     * Create a triple tuple key
     * @param a First element
     * @param b Second element
     * @param c Third element
     */
    public static inline function tuple3<A, B, C>(a: A, b: B, c: C): RegistryKey {
        return new RegistryKey({_0: a, _1: b, _2: c});
    }
    
    /**
     * Create a via tuple for custom registry
     * @param module The registry module
     * @param name The name to register under
     */
    public static inline function via(module: String, name: Term): RegistryKey {
        return new RegistryKey(untyped __elixir__('{:via, String.to_atom($module), $name}'));
    }
    
    /**
     * Convert to string for debugging
     */
    @:to
    public inline function toString(): String {
        return Kernel.inspect(this);
    }
}
