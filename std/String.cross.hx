/**
 * String implementation for Elixir target
 * 
 * WHY: Override String instance methods to generate idiomatic Elixir code
 * WHAT: Provides String methods that compile to Elixir String module calls
 * HOW: Uses extern inline functions with __elixir__() for zero-cost abstractions
 * 
 * NOTE: This overrides Haxe's default String implementation for the Elixir target
 * 
 * ARCHITECTURE: String is a true primitive in Haxe, so we use extern inline
 * functions that get inlined at call sites with zero runtime overhead.
 * Unlike Array which is a class, String requires special handling.
 */
extern class String {
    /**
     * The number of characters in `this` String.
     * Maps to String.length/1 in Elixir
     */
    public var length(default, null): Int;
    
    /**
     * Returns the String itself.
     */
    extern inline public function toString(): String {
        return this;
    }
    
    /**
     * Returns the character at position `index` of `this` String.
     * If `index` is negative or exceeds `this.length`, the empty String ""
     * is returned.
     */
    extern inline public function charAt(index: Int): String {
        return untyped __elixir__('String.at({0}, {1}) || ""', this, index);
    }
    
    /**
     * Returns the character code at position `index` of `this` String.
     * If `index` is negative or exceeds `this.length`, `null` is returned.
     */
    extern inline public function charCodeAt(index: Int): Null<Int> {
        var result = untyped __elixir__(':binary.at({0}, {1})', this, index);
        return untyped __elixir__('if {0} == nil, do: nil, else: {0}', result);
    }
    
    /**
     * Returns the position of the leftmost occurrence of `str` within `this`
     * String.
     * If `str` cannot be found, -1 is returned.
     */
    extern inline public function indexOf(str: String, ?startIndex: Int = 0): Int {
        if (startIndex != 0) {
            // Handle substring search with start index
            var sub = untyped __elixir__('String.slice({0}, {1}..-1)', this, startIndex);
            var idx = untyped __elixir__('case :binary.match({0}, {1}) do
                {pos, _} -> pos + {2}
                nil -> -1
            end', sub, str, startIndex);
            return idx;
        } else {
            return untyped __elixir__('case :binary.match({0}, {1}) do
                {pos, _} -> pos
                nil -> -1
            end', this, str);
        }
    }
    
    /**
     * Returns the position of the rightmost occurrence of `str` within `this`
     * String.
     * If `str` cannot be found, -1 is returned.
     */
    extern inline public function lastIndexOf(str: String, ?startIndex: Int): Int {
        // Elixir doesn't have a direct lastIndexOf, so we need to work around it
        // Using a simple approach: reverse and find
        if (startIndex == null) {
            startIndex = length;
        }
        var sub = untyped __elixir__('String.slice({0}, 0, {1})', this, startIndex);
        return untyped __elixir__('case String.split({0}, {1}) do
            parts when length(parts) > 1 ->
                String.length(Enum.join(Enum.slice(parts, 0..-2), {1}))
            _ -> -1
        end', sub, str);
    }
    
    /**
     * Splits `this` String at each occurrence of `delimiter`.
     */
    extern inline public function split(delimiter: String): Array<String> {
        return untyped __elixir__('String.split({0}, {1})', this, delimiter);
    }
    
    /**
     * Returns `len` characters of `this` String, starting at position `pos`.
     * If `len` is omitted, all characters from position `pos` to the end of
     * `this` String are included.
     */
    extern inline public function substr(pos: Int, ?len: Int): String {
        if (len == null) {
            return untyped __elixir__('String.slice({0}, {1}..-1)', this, pos);
        } else {
            return untyped __elixir__('String.slice({0}, {1}, {2})', this, pos, len);
        }
    }
    
    /**
     * Returns the part of `this` String from `startIndex` to but not including
     * `endIndex`.
     */
    extern inline public function substring(startIndex: Int, ?endIndex: Int): String {
        if (endIndex == null) {
            return untyped __elixir__('String.slice({0}, {1}..-1)', this, startIndex);
        } else {
            var len = endIndex - startIndex;
            return untyped __elixir__('String.slice({0}, {1}, {2})', this, startIndex, len);
        }
    }
    
    /**
     * Returns a String where all characters of `this` String are lower case.
     */
    extern inline public function toLowerCase(): String {
        return untyped __elixir__('String.downcase({0})', this);
    }
    
    /**
     * Returns a String where all characters of `this` String are upper case.
     */
    extern inline public function toUpperCase(): String {
        return untyped __elixir__('String.upcase({0})', this);
    }
    
    /**
     * Returns the String corresponding to the character code `code`.
     * If `code` is negative or has another invalid value, the result is
     * unspecified.
     * 
     * @:pure indicates this function has no side effects and always returns
     * the same output for the same input. This allows the Haxe compiler to:
     * - Perform dead code elimination if the result is unused
     * - Evaluate at compile-time if given constant arguments
     * - Safely cache or reorder calls for optimization
     */
    @:pure
    extern inline public static function fromCharCode(code: Int): String {
        return untyped __elixir__('<<{0}::utf8>>', code);
    }
}