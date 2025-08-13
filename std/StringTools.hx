package;

/**
 * StringTools for Reflaxe.Elixir
 * 
 * Basic implementation that provides required methods for compilation.
 * The actual Elixir code generation is handled by the compiler.
 */
class StringTools {
    public static function isSpace(s: String, pos: Int): Bool {
        if (pos < 0 || pos >= s.length) return false;
        var c = s.charCodeAt(pos);
        return c > 8 && c < 14 || c == 32;
    }
    
    public static function ltrim(s: String): String {
        var l = s.length;
        var r = 0;
        while (r < l && isSpace(s, r)) {
            r++;
        }
        if (r > 0) {
            return s.substr(r, l - r);
        } else {
            return s;
        }
    }
    
    public static function rtrim(s: String): String {
        var l = s.length;
        var r = 0;
        while (r < l && isSpace(s, l - r - 1)) {
            r++;
        }
        if (r > 0) {
            return s.substr(0, l - r);
        } else {
            return s;
        }
    }
    
    public static function trim(s: String): String {
        return ltrim(rtrim(s));
    }
    
    public static function urlEncode(s: String): String {
        // Stub implementation
        return s;
    }
    
    public static function urlDecode(s: String): String {
        // Stub implementation
        return s;
    }
    
    public static function htmlEscape(s: String, ?quotes: Bool): String {
        // Basic implementation
        s = s.split("&").join("&amp;");
        s = s.split("<").join("&lt;");
        s = s.split(">").join("&gt;");
        if (quotes) {
            s = s.split('"').join("&quot;");
            s = s.split("'").join("&#039;");
        }
        return s;
    }
    
    public static function htmlUnescape(s: String): String {
        return s.split("&gt;").join(">")
            .split("&lt;").join("<")
            .split("&quot;").join('"')
            .split("&#039;").join("'")
            .split("&amp;").join("&");
    }
    
    public static function startsWith(s: String, start: String): Bool {
        return s.length >= start.length && s.substr(0, start.length) == start;
    }
    
    public static function endsWith(s: String, end: String): Bool {
        var elen = end.length;
        var slen = s.length;
        return slen >= elen && s.substr(slen - elen, elen) == end;
    }
    
    public static function replace(s: String, sub: String, by: String): String {
        return s.split(sub).join(by);
    }
    
    public static function lpad(s: String, c: String, l: Int): String {
        if (c.length <= 0) return s;
        var buf = "";
        l -= s.length;
        while (buf.length < l) {
            buf += c;
        }
        return buf + s;
    }
    
    public static function rpad(s: String, c: String, l: Int): String {
        if (c.length <= 0) return s;
        var buf = s;
        while (buf.length < l) {
            buf += c;
        }
        return buf;
    }
    
    public static function contains(s: String, value: String): Bool {
        return s.indexOf(value) != -1;
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
        var s = "";
        var hexChars = "0123456789ABCDEF";
        if (n < 0) {
            // Handle negative numbers
            n = -n;
            s = "-";
        }
        if (n == 0) {
            s = "0";
        } else {
            var result = "";
            while (n > 0) {
                result = hexChars.charAt(n & 15) + result;
                n = n >>> 4;
            }
            s += result;
        }
        if (digits != null) {
            while (s.length < digits) {
                s = "0" + s;
            }
        }
        return s;
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