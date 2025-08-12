package elixir;

#if (macro || reflaxe_runtime)

/**
 * String module extern definitions for Elixir standard library
 * Provides type-safe interfaces for String operations
 * 
 * Maps to Elixir's String module functions with proper type signatures
 */
@:native("String")
extern class ElixirString {
    
    // Length and measurement
    @:native("String.length")
    public static function length(string: String): Int;
    
    @:native("String.byte_size") 
    public static function byteSize(string: String): Int;
    
    @:native("String.valid?")
    public static function valid(string: String): Bool;
    
    // Case conversion
    @:native("String.downcase")
    public static function downcase(string: String): String;
    
    @:native("String.upcase")
    public static function upcase(string: String): String;
    
    @:native("String.capitalize")
    public static function capitalize(string: String): String;
    
    // Trimming operations
    @:native("String.trim")
    public static function trim(string: String): String;
    
    @:native("String.trim")
    public static function trimWith(string: String, chars: String): String;
    
    @:native("String.trim_leading")
    public static function trimLeading(string: String): String;
    
    @:native("String.trim_leading")
    public static function trimLeadingWith(string: String, chars: String): String;
    
    @:native("String.trim_trailing")
    public static function trimTrailing(string: String): String;
    
    @:native("String.trim_trailing")
    public static function trimTrailingWith(string: String, chars: String): String;
    
    // Padding operations
    @:native("String.pad_leading")
    public static function padLeading(string: String, count: Int): String;
    
    @:native("String.pad_leading")  
    public static function padLeadingWith(string: String, count: Int, padding: String): String;
    
    @:native("String.pad_trailing")
    public static function padTrailing(string: String, count: Int): String;
    
    @:native("String.pad_trailing")
    public static function padTrailingWith(string: String, count: Int, padding: String): String;
    
    // Slicing and substring operations
    @:native("String.slice")
    public static function slice(string: String, start: Int, length: Int): String;
    
    @:native("String.slice")
    public static function sliceRange(string: String, range: {start: Int, stop: Int}): String;
    
    @:native("String.at")
    public static function at(string: String, position: Int): Null<String>;
    
    @:native("String.first")
    public static function first(string: String): Null<String>;
    
    @:native("String.last")
    public static function last(string: String): Null<String>;
    
    // Pattern matching and searching
    @:native("String.contains?")
    public static function contains(string: String, substring: String): Bool;
    
    @:native("String.starts_with?")
    public static function startsWith(string: String, prefix: String): Bool;
    
    @:native("String.ends_with?")
    public static function endsWith(string: String, suffix: String): Bool;
    
    @:native("String.match?")
    public static function match(string: String, regex: String): Bool; // Simple regex matching
    
    // String splitting
    @:native("String.split")
    public static function split(string: String): Array<String>; // Split on whitespace
    
    @:native("String.split")
    public static function splitOn(string: String, pattern: String): Array<String>;
    
    @:native("String.split")
    public static function splitWithOptions(string: String, pattern: String, options: Array<String>): Array<String>; // Options like "trim", "global"
    
    @:native("String.split_at")
    public static function splitAt(string: String, position: Int): {_0: String, _1: String};
    
    // String joining and concatenation  
    @:native("String.duplicate")
    public static function duplicate(string: String, n: Int): String;
    
    @:native("String.reverse")
    public static function reverse(string: String): String;
    
    // Replacement operations
    @:native("String.replace")
    public static function replace(string: String, pattern: String, replacement: String): String;
    
    @:native("String.replace")
    public static function replaceWithOptions(string: String, pattern: String, replacement: String, options: Array<String>): String;
    
    @:native("String.replace_leading")
    public static function replaceLeading(string: String, pattern: String, replacement: String): String;
    
    @:native("String.replace_trailing")
    public static function replaceTrailing(string: String, pattern: String, replacement: String): String;
    
    @:native("String.replace_prefix")
    public static function replacePrefix(string: String, prefix: String, replacement: String): String;
    
    @:native("String.replace_suffix")
    public static function replaceSuffix(string: String, suffix: String, replacement: String): String;
    
    // Unicode operations
    @:native("String.normalize")
    public static function normalize(string: String, form: String): String; // "nfc", "nfd", "nfkc", "nfkd"
    
    @:native("String.equivalent?")
    public static function equivalent(string1: String, string2: String): Bool;
    
    @:native("String.printable?")
    public static function printable(string: String): Bool;
    
    // Conversion operations
    @:native("String.to_atom")
    public static function toAtom(string: String): String; // Atom represented as string
    
    @:native("String.to_existing_atom")
    public static function toExistingAtom(string: String): String;
    
    @:native("String.to_charlist")
    public static function toCharlist(string: String): Array<Int>;
    
    @:native("String.to_float")
    public static function toFloat(string: String): Float;
    
    @:native("String.to_integer")
    public static function toInteger(string: String): Int;
    
    @:native("String.to_integer")
    public static function toIntegerWithBase(string: String, base: Int): Int;
    
    // Advanced operations
    @:native("String.chunk")
    public static function chunk(string: String, trait: String): Array<String>; // Chunk by grapheme, codepoint, etc.
    
    @:native("String.codepoints")
    public static function codepoints(string: String): Array<String>;
    
    @:native("String.graphemes")
    public static function graphemes(string: String): Array<String>;
    
    @:native("String.next_codepoint")
    public static function nextCodepoint(string: String): Null<{_0: String, _1: String}>; // {codepoint, rest}
    
    @:native("String.next_grapheme")
    public static function nextGrapheme(string: String): Null<{_0: String, _1: String}>; // {grapheme, rest}
    
    // Jaro-Winkler distance for fuzzy matching
    @:native("String.jaro_distance")
    public static function jaroDistance(string1: String, string2: String): Float;
    
    // Myers difference algorithm  
    @:native("String.myers_difference")
    public static function myersDifference(string1: String, string2: String): Array<{_0: String, _1: String}>; // [:eq | :ins | :del, substring]
    
    // Stream-based operations for large strings
    @:native("String.splitter")
    public static function splitter(string: String, pattern: String): Dynamic; // Returns a Stream
    
    // Bag distance for approximate matching
    @:native("String.bag_distance")
    public static function bagDistance(string1: String, string2: String): Float;
    
    // Helper functions for common operations
    public static inline function isEmpty(string: String): Bool {
        return length(string) == 0;
    }
    
    public static inline function isBlank(string: String): Bool {
        return isEmpty(trim(string));
    }
    
    public static inline function leftPad(string: String, totalLength: Int, padWith: String = " "): String {
        return length(string) >= totalLength ? string : padLeadingWith(string, totalLength, padWith);
    }
    
    public static inline function repeat(string: String, times: Int): String {
        return duplicate(string, times);
    }
}

#end