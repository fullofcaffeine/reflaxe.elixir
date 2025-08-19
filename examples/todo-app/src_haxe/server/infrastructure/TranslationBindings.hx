package server.infrastructure;

/**
 * Type-safe translation bindings for Gettext interpolation.
 * 
 * This abstract type provides a type-safe way to pass variable bindings
 * to Gettext translation functions without using Dynamic. It internally
 * uses a Map but provides a clean API for setting interpolation values.
 * 
 * ## Usage
 * ```haxe
 * var bindings = TranslationBindings.create()
 *     .set("name", "John")
 *     .set("count", 5);
 * Gettext.gettext("Hello %{name}, you have %{count} items", bindings);
 * ```
 */
abstract TranslationBindings(Map<String, String>) {
    /**
     * Creates a new TranslationBindings instance from a map.
     */
    inline function new(map: Map<String, String>) {
        this = map;
    }
    
    /**
     * Creates an empty TranslationBindings instance.
     * 
     * @return A new empty TranslationBindings
     */
    public static function create(): TranslationBindings {
        return new TranslationBindings(new Map<String, String>());
    }
    
    /**
     * Sets a string value for interpolation.
     * 
     * @param key The interpolation key
     * @param value The string value
     * @return This TranslationBindings for chaining
     */
    public function set(key: String, value: String): TranslationBindings {
        this.set(key, value);
        return cast this;
    }
    
    /**
     * Sets an integer value for interpolation.
     * Automatically converts to string.
     * 
     * @param key The interpolation key
     * @param value The integer value
     * @return This TranslationBindings for chaining
     */
    public function setInt(key: String, value: Int): TranslationBindings {
        this.set(key, Std.string(value));
        return cast this;
    }
    
    /**
     * Sets a float value for interpolation.
     * Automatically converts to string.
     * 
     * @param key The interpolation key
     * @param value The float value
     * @return This TranslationBindings for chaining
     */
    public function setFloat(key: String, value: Float): TranslationBindings {
        this.set(key, Std.string(value));
        return cast this;
    }
    
    /**
     * Sets a boolean value for interpolation.
     * Automatically converts to string.
     * 
     * @param key The interpolation key
     * @param value The boolean value
     * @return This TranslationBindings for chaining
     */
    public function setBool(key: String, value: Bool): TranslationBindings {
        this.set(key, value ? "true" : "false");
        return cast this;
    }
    
    /**
     * Gets the underlying map for framework interop.
     * This is marked @:noCompletion to hide it from IntelliSense.
     * 
     * @return The underlying Map<String, String>
     */
    @:noCompletion
    public inline function toMap(): Map<String, String> {
        return this;
    }
}