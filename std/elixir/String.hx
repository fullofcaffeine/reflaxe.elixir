package elixir;

#if (macro || reflaxe_runtime)

/**
 * String module extern definitions for Elixir standard library
 * Provides type-safe interfaces for string manipulation operations
 * 
 * Maps to Elixir's String module functions with proper type signatures
 * Essential for text processing, pattern matching, and string transformations
 */
@:native("String")
extern class String {
    
    // String length and size
    @:native("String.length")
    public static function length(string: String): Int; // Unicode-aware length
    
    @:native("String.byte_size")
    public static function byteSize(string: String): Int; // Size in bytes
    
    @:native("String.valid?")
    public static function valid(string: String): Bool; // Check if valid UTF-8
    
    // String case conversion
    @:native("String.downcase")
    public static function downcase(string: String): String; // Convert to lowercase
    
    @:native("String.downcase")
    public static function downcaseWithLocale(string: String, mode: String): String; // With locale/mode
    
    @:native("String.upcase")
    public static function upcase(string: String): String; // Convert to uppercase
    
    @:native("String.upcase")
    public static function upcaseWithLocale(string: String, mode: String): String;
    
    @:native("String.capitalize")
    public static function capitalize(string: String): String; // Capitalize first character
    
    @:native("String.capitalize")
    public static function capitalizeWithLocale(string: String, mode: String): String;
    
    // String trimming and padding
    @:native("String.trim")
    public static function trim(string: String): String; // Remove leading/trailing whitespace
    
    @:native("String.trim")
    public static function trimWith(string: String, toTrim: String): String; // Trim specific characters
    
    @:native("String.trim_leading")
    public static function trimLeading(string: String): String; // Trim leading whitespace
    
    @:native("String.trim_leading")
    public static function trimLeadingWith(string: String, toTrim: String): String;
    
    @:native("String.trim_trailing")
    public static function trimTrailing(string: String): String; // Trim trailing whitespace
    
    @:native("String.trim_trailing")
    public static function trimTrailingWith(string: String, toTrim: String): String;
    
    @:native("String.pad_leading")
    public static function padLeading(string: String, count: Int): String; // Pad with spaces
    
    @:native("String.pad_leading")
    public static function padLeadingWith(string: String, count: Int, padding: String): String; // Custom padding
    
    @:native("String.pad_trailing")
    public static function padTrailing(string: String, count: Int): String;
    
    @:native("String.pad_trailing")
    public static function padTrailingWith(string: String, count: Int, padding: String): String;
    
    // String slicing and extraction
    @:native("String.slice")
    public static function slice(string: String, start: Int, length: Int): String; // Extract substring
    
    @:native("String.slice")
    public static function sliceRange(string: String, range: Dynamic): String; // Slice with range
    
    @:native("String.at")
    public static function at(string: String, position: Int): Null<String>; // Get character at position
    
    @:native("String.first")
    public static function first(string: String): Null<String>; // Get first character
    
    @:native("String.last")
    public static function last(string: String): Null<String>; // Get last character
    
    // String searching and matching
    @:native("String.contains?")
    public static function contains(string: String, contents: String): Bool; // Check if contains substring
    
    @:native("String.starts_with?")
    public static function startsWith(string: String, prefix: String): Bool; // Check prefix
    
    @:native("String.starts_with?")
    public static function startsWithAny(string: String, prefixes: Array<String>): Bool; // Multiple prefixes
    
    @:native("String.ends_with?")
    public static function endsWith(string: String, suffix: String): Bool; // Check suffix
    
    @:native("String.ends_with?")
    public static function endsWithAny(string: String, suffixes: Array<String>): Bool; // Multiple suffixes
    
    @:native("String.match?")
    public static function match(string: String, regex: Dynamic): Bool; // Regex match
    
    // String replacement operations
    @:native("String.replace")
    public static function replace(subject: String, pattern: Dynamic, replacement: String): String; // Replace all
    
    @:native("String.replace")
    public static function replaceWithOptions(subject: String, pattern: Dynamic, replacement: String, options: Map<String, Dynamic>): String;
    
    @:native("String.replace_prefix")
    public static function replacePrefix(string: String, prefix: String, replacement: String): String; // Replace prefix once
    
    @:native("String.replace_suffix")
    public static function replaceSuffix(string: String, suffix: String, replacement: String): String; // Replace suffix once
    
    @:native("String.replace_leading")
    public static function replaceLeading(string: String, match: String, replacement: String): String; // Replace leading matches
    
    @:native("String.replace_trailing")
    public static function replaceTrailing(string: String, match: String, replacement: String): String; // Replace trailing matches
    
    // String splitting operations
    @:native("String.split")
    public static function split(string: String): Array<String>; // Split on whitespace
    
    @:native("String.split")
    public static function splitOn(string: String, pattern: Dynamic): Array<String>; // Split on pattern
    
    @:native("String.split")
    public static function splitWithOptions(string: String, pattern: Dynamic, options: Map<String, Dynamic>): Array<String>;
    
    @:native("String.splitter")
    public static function splitter(string: String, pattern: Dynamic): Dynamic; // Return splitter stream
    
    @:native("String.split_at")
    public static function splitAt(string: String, offset: Int): {_0: String, _1: String}; // Split at position
    
    // String analysis and inspection
    @:native("String.codepoints")
    public static function codepoints(string: String): Array<String>; // Unicode codepoints
    
    @:native("String.graphemes")
    public static function graphemes(string: String): Array<String>; // Grapheme clusters
    
    @:native("String.next_codepoint")
    public static function nextCodepoint(string: String): Null<{_0: String, _1: String}>; // {codepoint, rest}
    
    @:native("String.next_grapheme")
    public static function nextGrapheme(string: String): Null<{_0: String, _1: String}>; // {grapheme, rest}
    
    @:native("String.next_grapheme_size")
    public static function nextGraphemeSize(string: String): Null<{_0: String, _1: Int}>; // {grapheme, byte_size}
    
    // String normalization
    @:native("String.normalize")
    public static function normalize(string: String, form: String): String; // Unicode normalization (:nfc, :nfd, :nfkc, :nfkd)
    
    // String comparison
    @:native("String.equivalent?")
    public static function equivalent(string1: String, string2: String): Bool; // Unicode equivalent
    
    @:native("String.myers_difference")
    public static function myersDifference(string1: String, string2: String): Array<Dynamic>; // String diff
    
    @:native("String.jaro_distance")
    public static function jaroDistance(string1: String, string2: String): Float; // Jaro distance
    
    // String conversion and formatting
    @:native("String.to_integer")
    public static function toInteger(string: String): {_0: String, _1: Dynamic}; // {integer, remainder} | :error
    
    @:native("String.to_integer")
    public static function toIntegerWithBase(string: String, base: Int): {_0: String, _1: Dynamic};
    
    @:native("String.to_float")
    public static function toFloat(string: String): {_0: String, _1: Dynamic}; // {float, remainder} | :error
    
    @:native("String.to_atom")
    public static function toAtom(string: String): Dynamic; // Convert to atom
    
    @:native("String.to_existing_atom")
    public static function toExistingAtom(string: String): {_0: String, _1: Dynamic}; // {:ok, atom} | {:error, :not_found}
    
    @:native("String.to_charlist")
    public static function toCharlist(string: String): Array<Int>; // Convert to character list
    
    // String duplication and repetition
    @:native("String.duplicate")
    public static function duplicate(string: String, n: Int): String; // Repeat string n times
    
    // String reverse
    @:native("String.reverse")
    public static function reverse(string: String): String; // Reverse string (grapheme-aware)
    
    // String chunking
    @:native("String.chunk")
    public static function chunk(string: String, trait: String): Array<String>; // Chunk by Unicode trait
    
    // Regular expression helpers (String.replace uses these internally)
    public static inline var REGEX_GLOBAL: String = "g"; // Global replace flag
    public static inline var REGEX_CASELESS: String = "i"; // Case-insensitive flag
    public static inline var REGEX_MULTILINE: String = "m"; // Multiline flag
    
    // Helper functions for common operations
    public static inline function isEmpty(string: String): Bool {
        return length(string) == 0;
    }
    
    public static inline function isBlank(string: String): Bool {
        return isEmpty(trim(string));
    }
    
    public static inline function isNotEmpty(string: String): Bool {
        return !isEmpty(string);
    }
    
    public static inline function isNotBlank(string: String): Bool {
        return !isBlank(string);
    }
    
    public static inline function charAt(string: String, index: Int): Null<String> {
        return at(string, index);
    }
    
    public static inline function substring(string: String, start: Int, end: Int): String {
        return slice(string, start, end - start);
    }
    
    public static inline function left(string: String, length: Int): String {
        return slice(string, 0, length);
    }
    
    public static inline function right(string: String, length: Int): String {
        var len = length(string);
        return len <= length ? string : slice(string, len - length, length);
    }
    
    public static inline function mid(string: String, start: Int, length: Int): String {
        return slice(string, start, length);
    }
    
    // String joining and concatenation helpers
    public static inline function join(strings: Array<String>, separator: String): String {
        return Enum.joinWith(strings, separator);
    }
    
    public static inline function concat(strings: Array<String>): String {
        return Enum.join(strings);
    }
    
    // Case conversion shortcuts
    public static inline function toLower(string: String): String {
        return downcase(string);
    }
    
    public static inline function toUpper(string: String): String {
        return upcase(string);
    }
    
    public static inline function toTitleCase(string: String): String {
        return capitalize(string);
    }
    
    // Padding shortcuts
    public static inline function leftPad(string: String, totalLength: Int, padWith: String = " "): String {
        return length(string) >= totalLength ? string : padLeadingWith(string, totalLength, padWith);
    }
    
    public static inline function rightPad(string: String, totalLength: Int, padWith: String = " "): String {
        return length(string) >= totalLength ? string : padTrailingWith(string, totalLength, padWith);
    }
    
    public static inline function centerPad(string: String, totalLength: Int, padWith: String = " "): String {
        var len = length(string);
        if (len >= totalLength) return string;
        var padTotal = totalLength - len;
        var padLeft = Std.int(padTotal / 2);
        var padRight = padTotal - padLeft;
        return padLeadingWith(padTrailingWith(string, len + padRight, padWith), totalLength, padWith);
    }
    
    // String testing helpers
    public static inline function hasPrefix(string: String, prefix: String): Bool {
        return startsWith(string, prefix);
    }
    
    public static inline function hasSuffix(string: String, suffix: String): Bool {
        return endsWith(string, suffix);
    }
    
    public static inline function includes(string: String, substring: String): Bool {
        return contains(string, substring);
    }
    
    // String repeat helper
    public static inline function repeat(string: String, times: Int): String {
        return duplicate(string, times);
    }
    
    // Common string operations
    public static inline function removePrefix(string: String, prefix: String): String {
        return startsWith(string, prefix) ? slice(string, length(prefix), length(string) - length(prefix)) : string;
    }
    
    public static inline function removeSuffix(string: String, suffix: String): String {
        return endsWith(string, suffix) ? slice(string, 0, length(string) - length(suffix)) : string;
    }
    
    public static inline function ensurePrefix(string: String, prefix: String): String {
        return startsWith(string, prefix) ? string : prefix + string;
    }
    
    public static inline function ensureSuffix(string: String, suffix: String): String {
        return endsWith(string, suffix) ? string : string + suffix;
    }
}

#end