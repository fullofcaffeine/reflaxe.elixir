package;

/**
 * StringTools for Reflaxe.Elixir
 * 
 * This provides the StringTools API for Haxe code targeting Elixir.
 * It's marked as @:coreApi to replace the standard StringTools.
 * 
 * Most methods are extern and map to Elixir runtime implementations.
 * Internal UTF-16 methods are provided as stubs for compilation compatibility.
 */
// StringTools implementation for Reflaxe.Elixir
// Note: Not using @:coreApi due to strict field requirements
extern class StringTools {
    // UTF-16 compatibility stubs - These exist only to satisfy compile-time checks
    // from StringIteratorUnicode. They're never actually used at runtime for Elixir.
    @:noCompletion @:dce
    private static inline var MIN_SURROGATE_CODE_POINT = #if utf16 65536 #else 0 #end;
    
    @:noCompletion @:dce
    private static inline function utf16CodePointAt(s: String, index: Int): Int {
        // Stub for compilation compatibility with StringIteratorUnicode
        #if utf16
        var c = fastCodeAt(s, index);
        if (c >= 0xD800 && c <= 0xDBFF) {
            c = (c - 0xD800) << 10 | (fastCodeAt(s, index + 1) & 0x3FF) | 0x10000;
        }
        return c;
        #else
        return fastCodeAt(s, index);
        #end
    }
    
    /**
     * Tells if the character at position pos is a space
     * Character codes 9,10,11,12,13 or 32 are considered spaces
     */
    public static function isSpace(s: String, pos: Int): Bool;
    
    /**
     * Removes leading space characters
     */
    public static function ltrim(s: String): String;
    
    /**
     * Removes trailing space characters
     */
    public static function rtrim(s: String): String;
    
    /**
     * Removes leading and trailing space characters
     */
    public static function trim(s: String): String;
    
    /**
     * URL encodes a string
     */
    public static function urlEncode(s: String): String;
    
    /**
     * URL decodes a string
     */
    public static function urlDecode(s: String): String;
    
    /**
     * HTML escapes a string
     */
    public static function htmlEscape(s: String, ?quotes: Bool): String;
    
    /**
     * HTML unescapes a string
     */
    public static function htmlUnescape(s: String): String;
    
    /**
     * Checks if string starts with another string
     */
    public static function startsWith(s: String, start: String): Bool;
    
    /**
     * Checks if string ends with another string
     */
    public static function endsWith(s: String, end: String): Bool;
    
    /**
     * Replaces all occurrences of a substring
     */
    public static function replace(s: String, sub: String, by: String): String;
    
    /**
     * Pads a string on the left with a character
     */
    public static function lpad(s: String, c: String, l: Int): String;
    
    /**
     * Pads a string on the right with a character
     */
    public static function rpad(s: String, c: String, l: Int): String;
    
    /**
     * Checks if string contains another string
     */
    public static function contains(s: String, value: String): Bool;
    
    /**
     * Fast character code access - same as charCodeAt but potentially faster
     * Returns character code at given position
     */
    public static function fastCodeAt(s: String, index: Int): Int;
    
    /**
     * Unsafe character code access - no bounds checking
     * Returns character code at given position
     */
    public static function unsafeCodeAt(s: String, index: Int): Int;
    
    /**
     * Checks if a character code represents end-of-file
     * Always returns false for Elixir target
     */
    public static function isEof(c: Int): Bool;
    
    /**
     * Converts an integer to a hexadecimal string
     * @param n The integer to convert
     * @param digits Optional minimum number of digits (pads with zeros)
     */
    public static function hex(n: Int, ?digits: Int): String;
    
    /**
     * Returns an iterator over the characters of a string
     */
    public static function iterator(s: String): haxe.iterators.StringIterator;
    
    /**
     * Returns a key-value iterator over the characters of a string
     */
    public static function keyValueIterator(s: String): haxe.iterators.StringKeyValueIterator;
    
    /**
     * Quote argument for Unix shell execution
     */
    public static function quoteUnixArg(argument: String): String;
    
    /**
     * Windows meta characters for shell escaping
     */
    public static var winMetaCharacters: Array<Int>;
    
    /**
     * Quote argument for Windows shell execution
     */
    public static function quoteWinArg(argument: String, escapeMetaCharacters: Bool): String;
}