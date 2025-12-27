/**
 * String implementation for Elixir target
 * 
 * WHY: Override String instance methods to generate idiomatic Elixir code
 * WHAT: Provides String methods that compile to Elixir String module calls
 * HOW: Uses extern method declarations that the compiler lowers to Elixir AST
 *      (String.*, :binary.*, Enum.*) with correct Haxe semantics.
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
    extern public function toString(): String;
    
    /**
     * Returns the character at position `index` of `this` String.
     * If `index` is negative or exceeds `this.length`, the empty String ""
     * is returned.
     */
    extern public function charAt(index: Int): String;
    
    /**
     * Returns the character code at position `index` of `this` String.
     * If `index` is negative or exceeds `this.length`, `null` is returned.
     */
    extern public function charCodeAt(index: Int): Null<Int>;
    
    /**
     * Returns the position of the leftmost occurrence of `str` within `this`
     * String.
     * If `str` cannot be found, -1 is returned.
     */
    extern public function indexOf(str: String, ?startIndex: Int = 0): Int;
    
    /**
     * Returns the position of the rightmost occurrence of `str` within `this`
     * String.
     * If `str` cannot be found, -1 is returned.
     */
    extern public function lastIndexOf(str: String, ?startIndex: Int): Int;
    
    /**
     * Splits `this` String at each occurrence of `delimiter`.
     */
    extern public function split(delimiter: String): Array<String>;
    
    /**
     * Returns `len` characters of `this` String, starting at position `pos`.
     * If `len` is omitted, all characters from position `pos` to the end of
     * `this` String are included.
     */
    extern public function substr(pos: Int, ?len: Int): String;
    
    /**
     * Returns the part of `this` String from `startIndex` to but not including
     * `endIndex`.
     */
    extern public function substring(startIndex: Int, ?endIndex: Int): String;
    
    /**
     * Returns a String where all characters of `this` String are lower case.
     */
    extern public function toLowerCase(): String;
    
    /**
     * Returns a String where all characters of `this` String are upper case.
     */
    extern public function toUpperCase(): String;
    
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
