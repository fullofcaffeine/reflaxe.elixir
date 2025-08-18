package;

import elixir.Syntax;

/**
 * StringTools for Reflaxe.Elixir with idiomatic Elixir implementations
 * 
 * Uses elixir.Syntax.code() for type-safe injection of idiomatic Elixir code
 * that leverages Elixir's excellent string processing capabilities.
 */
class StringTools {
    public static function isSpace(s: String, pos: Int): Bool {
        if (pos < 0 || pos >= s.length) return false;
        var c = s.charCodeAt(pos);
        return c > 8 && c < 14 || c == 32;
    }
    
    public static function ltrim(s: String): String {
        return Syntax.code("String.trim_leading({0})", s);
    }
    
    public static function rtrim(s: String): String {
        return Syntax.code("String.trim_trailing({0})", s);
    }
    
    public static function trim(s: String): String {
        return Syntax.code("String.trim({0})", s);
    }
    
    public static function urlEncode(s: String): String {
        return Syntax.code("URI.encode({0})", s);
    }
    
    public static function urlDecode(s: String): String {
        return Syntax.code("URI.decode({0})", s);
    }
    
    public static function htmlEscape(s: String, ?quotes: Bool): String {
        if (quotes == true) {
            return Syntax.code("Phoenix.HTML.html_escape({0})", s);
        } else {
            return Syntax.code("Phoenix.HTML.html_escape({0})", s);
        }
    }
    
    public static function htmlUnescape(s: String): String {
        return Syntax.code("Phoenix.HTML.raw({0})", s);
    }
    
    public static function startsWith(s: String, start: String): Bool {
        return Syntax.code("String.starts_with?({0}, {1})", s, start);
    }
    
    public static function endsWith(s: String, end: String): Bool {
        return Syntax.code("String.ends_with?({0}, {1})", s, end);
    }
    
    public static function replace(s: String, sub: String, by: String): String {
        return Syntax.code("String.replace({0}, {1}, {2})", s, sub, by);
    }
    
    public static function lpad(s: String, c: String, l: Int): String {
        if (c.length <= 0) return s;
        return Syntax.code("String.pad_leading({0}, {1}, {2})", s, l, c);
    }
    
    public static function rpad(s: String, c: String, l: Int): String {
        if (c.length <= 0) return s;
        return Syntax.code("String.pad_trailing({0}, {1}, {2})", s, l, c);
    }
    
    public static function contains(s: String, value: String): Bool {
        return Syntax.code("String.contains?({0}, {1})", s, value);
    }
    
    public static function fastCodeAt(s: String, index: Int): Int {
        return s.charCodeAt(index);
    }
    
    public static function unsafeCodeAt(s: String, index: Int): Int {
        return s.charCodeAt(index);
    }
    
    public static function isEof(c: Int): Bool {
        return false;
    }
    
    public static function hex(n: Int, ?digits: Int): String {
        var hexStr: String = Syntax.code("Integer.to_string({0}, 16)", n);
        if (digits != null && digits > 0) {
            return Syntax.code("String.pad_leading({0}, {1}, \"0\")", hexStr, digits);
        }
        return hexStr;
    }
    
    public static function iterator(s: String): haxe.iterators.StringIterator {
        return new haxe.iterators.StringIterator(s);
    }
    
    public static function keyValueIterator(s: String): haxe.iterators.StringKeyValueIterator {
        return new haxe.iterators.StringKeyValueIterator(s);
    }
    
    public static function quoteUnixArg(argument: String): String {
        if (argument == "") {
            return "''";
        }
        // Simple implementation
        return "'" + replace(argument, "'", "'\"'\"'") + "'";
    }
    
    public static var winMetaCharacters: Array<Int> = [40, 41, 37, 33, 94, 34, 60, 62, 38, 124];
    
    public static function quoteWinArg(argument: String, escapeMetaCharacters: Bool): String {
        // Simple implementation
        if (argument.indexOf(" ") != -1 || argument == "") {
            argument = '"' + replace(argument, '"', '\\"') + '"';
        }
        return argument;
    }
    
    // UTF-16 compatibility
    #if utf16
    static inline var MIN_SURROGATE_CODE_POINT = 65536;
    
    static function utf16CodePointAt(s: String, index: Int): Int {
        var c = fastCodeAt(s, index);
        if (c >= 0xD800 && c <= 0xDBFF) {
            c = (c - 0xD800) << 10 | (fastCodeAt(s, index + 1) & 0x3FF) | 0x10000;
        }
        return c;
    }
    #end
}