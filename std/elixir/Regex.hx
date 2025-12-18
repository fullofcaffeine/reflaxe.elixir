package elixir;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

/**
 * Regex module extern definitions for Elixir standard library
 * Provides type-safe interfaces for regular expression operations
 * 
 * Maps to Elixir's Regex module functions with proper type signatures
 * Essential for pattern matching, text processing, and string manipulation
 */
@:native("Regex")
extern class Regex {
    
    // Compilation
    @:native("compile")
    static function compile(pattern: String): {_0: String, _1: Term}; // {:ok, regex} | {:error, reason}
    
    @:native("compile")
    static function compileWithOptions(pattern: String, options: String): {_0: String, _1: Term};
    
    @:native("compile!")
    static function compileBang(pattern: String): Term; // Returns regex or raises
    
    @:native("compile!")
    static function compileBangWithOptions(pattern: String, options: String): Term;
    
    @:native("recompile")
    static function recompile(regex: Term): Term;
    
    @:native("recompile!")
    static function recompileBang(regex: Term): Term;
    
    // Pattern information
    @:native("source")
    static function source(regex: Term): String; // Get the source pattern
    
    @:native("opts")
    static function opts(regex: Term): String; // Get the options
    
    @:native("names")
    static function names(regex: Term): Array<String>; // Get named capture groups
    
    @:native("version")
    static function version(): String; // PCRE version
    
    // Matching
    @:native("match?")
    static function match(regex: Term, string: String): Bool;
    
    @:native("run")
    static function run(regex: Term, string: String): Null<Array<String>>; // Returns matches or nil
    
    @:native("run")
    static function runWithOptions(regex: Term, string: String, options: Array<Term>): Null<Array<String>>;
    
    @:native("scan")
    static function scan(regex: Term, string: String): Array<Array<String>>; // All matches
    
    @:native("scan")
    static function scanWithOptions(regex: Term, string: String, options: Array<Term>): Array<Array<String>>;
    
    @:native("named_captures")
    static function namedCaptures(regex: Term, string: String): Map<String, String>; // Named captures
    
    @:native("named_captures")
    static function namedCapturesWithOptions(regex: Term, string: String, options: Array<Term>): Map<String, String>;
    
    // Replacement
    @:native("replace")
    static function replace(regex: Term, string: String, replacement: String): String;
    
    @:native("replace")
    static function replaceWithFunction(regex: Term, string: String, replacement: String -> String): String;
    
    @:native("replace")
    static function replaceWithOptions(regex: Term, string: String, replacement: Term, options: Array<Term>): String;
    
    // Splitting
    @:native("split")
    static function split(regex: Term, string: String): Array<String>;
    
    @:native("split")
    static function splitWithOptions(regex: Term, string: String, options: Array<Term>): Array<String>;
    
    // Escaping
    @:native("escape")
    static function escape(string: String): String; // Escape special regex characters
    
    // Helper functions for common operations
    public static inline function test(pattern: String, string: String): Bool {
        var result = compile(pattern);
        if (result._0 == "ok") {
            return match(result._1, string);
        }
        return false;
    }
    
    public static inline function quickMatch(pattern: String, string: String): Null<Array<String>> {
        var result = compile(pattern);
        if (result._0 == "ok") {
            return run(result._1, string);
        }
        return null;
    }
    
    public static inline function quickReplace(pattern: String, string: String, replacement: String): String {
        var result = compile(pattern);
        if (result._0 == "ok") {
            return replace(result._1, string, replacement);
        }
        return string;
    }
    
    public static inline function quickSplit(pattern: String, string: String): Array<String> {
        var result = compile(pattern);
        if (result._0 == "ok") {
            return split(result._1, string);
        }
        return [string];
    }
    
    public static inline function extractAll(pattern: String, string: String): Array<Array<String>> {
        var result = compile(pattern);
        if (result._0 == "ok") {
            return scan(result._1, string);
        }
        return [];
    }
    
    public static inline function extractFirst(pattern: String, string: String): Null<String> {
        var matches = quickMatch(pattern, string);
        return matches != null && matches.length > 0 ? matches[0] : null;
    }
    
    public static inline function replaceAll(pattern: String, string: String, replacement: String): String {
        var result = compile(pattern);
        if (result._0 == "ok") {
            return replace(result._1, string, replacement);
        }
        return string;
    }
    
    public static inline function getNamedGroups(pattern: String, string: String): Map<String, String> {
        var result = compile(pattern);
        if (result._0 == "ok") {
            return namedCaptures(result._1, string);
        }
        return new Map<String, String>();
    }
}

/**
 * Common regex patterns as constants
 */
class RegexPatterns {
    public static inline var EMAIL = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$";
    public static inline var URL = "^(https?|ftp)://[^\\s/$.?#].[^\\s]*$";
    public static inline var IP_ADDRESS = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
    public static inline var PHONE_US = "^\\(?([0-9]{3})\\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$";
    public static inline var ZIP_US = "^[0-9]{5}(-[0-9]{4})?$";
    public static inline var USERNAME = "^[a-zA-Z0-9_]{3,16}$";
    public static inline var PASSWORD_STRONG = "^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\\$%\\^&\\*]).{8,}$";
    public static inline var HEX_COLOR = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$";
    public static inline var SLUG = "^[a-z0-9-]+$";
    public static inline var UUID = "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$";
    public static inline var WHITESPACE = "\\s+";
    public static inline var DIGITS_ONLY = "^[0-9]+$";
    public static inline var LETTERS_ONLY = "^[a-zA-Z]+$";
    public static inline var ALPHANUMERIC = "^[a-zA-Z0-9]+$";
}

/**
 * Regex options as string flags
 */
class RegexOptions {
    public static inline var CASE_INSENSITIVE = "i";
    public static inline var MULTILINE = "m";
    public static inline var DOTALL = "s";
    public static inline var EXTENDED = "x";
    public static inline var UNICODE = "u";
    public static inline var UNGREEDY = "U";
    public static inline var FIRSTLINE = "f";
}

#end
