/*
 * Copyright (C)2005-2019 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

/**
 * StringTools implementation for Elixir target
 * 
 * WHY: Provide idiomatic Elixir code generation for string operations
 * WHAT: Replaces Haxe's default StringTools with Elixir-optimized version
 * HOW: Pure Haxe implementation that generates clean Elixir code
 * 
 * NOTE: Cannot use __elixir__() here because StringTools is used by macros
 * which run at compile-time in Haxe, not in Elixir runtime.
 */
class StringTools {
    /**
     * UTF-16 surrogate code point constants
     */
    public static inline var MIN_SURROGATE_CODE_POINT = 0xD800;
    public static inline var MAX_SURROGATE_CODE_POINT = 0xDFFF;
    public static inline var MIN_HIGH_SURROGATE_CODE_POINT = 0xD800;
    public static inline var MAX_HIGH_SURROGATE_CODE_POINT = 0xDBFF;
    public static inline var MIN_LOW_SURROGATE_CODE_POINT = 0xDC00;
    public static inline var MAX_LOW_SURROGATE_CODE_POINT = 0xDFFF;

    /**
     * Encode an URL by using the standard format.
     */
    public static function urlEncode(s: String): String {
        // Basic URL encoding implementation
        var result = "";
        for (i in 0...s.length) {
            var c = s.charCodeAt(i);
            if ((c >= 65 && c <= 90) || // A-Z
                (c >= 97 && c <= 122) || // a-z
                (c >= 48 && c <= 57) || // 0-9
                c == 45 || c == 95 || c == 46 || c == 126) { // - _ . ~
                result += String.fromCharCode(c);
            } else {
                result += "%" + hex(c, 2).toUpperCase();
            }
        }
        return result;
    }

    /**
     * Decode an URL using the standard format.
     */
    public static function urlDecode(s: String): String {
        var result = "";
        var i = 0;
        while (i < s.length) {
            var c = s.charAt(i);
            if (c == "%") {
                if (i + 2 < s.length) {
                    var hex = s.substr(i + 1, 2);
                    var code = parseInt("0x" + hex);
                    if (code != null) {
                        result += String.fromCharCode(code);
                        i += 3;
                        continue;
                    }
                }
            }
            result += c;
            i++;
        }
        return result;
    }

    /**
     * Escape HTML special characters of the string `s`.
     */
    public static function htmlEscape(s: String, ?quotes: Bool): String {
        s = replace(s, "&", "&amp;");
        s = replace(s, "<", "&lt;");
        s = replace(s, ">", "&gt;");
        if (quotes) {
            s = replace(s, '"', "&quot;");
            s = replace(s, "'", "&#039;");
        }
        return s;
    }

    /**
     * Unescape HTML special characters of the string `s`.
     */
    public static function htmlUnescape(s: String): String {
        s = replace(s, "&gt;", ">");
        s = replace(s, "&lt;", "<");
        s = replace(s, "&quot;", '"');
        s = replace(s, "&#039;", "'");
        s = replace(s, "&amp;", "&");
        return s;
    }

    /**
     * Tells if the string `s` starts with the string `start`.
     */
    public static function startsWith(s: String, start: String): Bool {
        return s.length >= start.length && s.substr(0, start.length) == start;
    }

    /**
     * Tells if the string `s` ends with the string `end`.
     */
    public static function endsWith(s: String, end: String): Bool {
        var elen = end.length;
        var slen = s.length;
        return slen >= elen && s.substr(slen - elen, elen) == end;
    }

    /**
     * Tells if the character in the string `s` at position `pos` is a space.
     */
    public static function isSpace(s: String, pos: Int): Bool {
        var c = s.charCodeAt(pos);
        return (c > 8 && c < 14) || c == 32;
    }

    /**
     * Removes leading space characters of `s`.
     */
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

    /**
     * Removes trailing space characters of `s`.
     */
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

    /**
     * Removes leading and trailing space characters of `s`.
     */
    public static inline function trim(s: String): String {
        return ltrim(rtrim(s));
    }

    /**
     * Pad `s` by appending `c` at its right until its length is at least `l`.
     */
    public static function lpad(s: String, c: String, l: Int): String {
        if (c.length <= 0) return s;
        var buf = "";
        while (buf.length + s.length < l) {
            buf += c;
        }
        return buf + s;
    }

    /**
     * Pad `s` by appending `c` at its left until its length is at least `l`.
     */
    public static function rpad(s: String, c: String, l: Int): String {
        if (c.length <= 0) return s;
        var buf = s;
        while (buf.length < l) {
            buf += c;
        }
        return buf;
    }

    /**
     * Replace all occurrences of the string `sub` in the string `s` with the string `by`.
     */
    public static function replace(s: String, sub: String, by: String): String {
        // Use split/join pattern for replacement
        return s.split(sub).join(by);
    }

    /**
     * Encode a number into a hexadecimal representation, with an optional number of zeros for left padding.
     */
    public static function hex(n: Int, ?digits: Int): String {
        var s = "";
        var hexChars = "0123456789ABCDEF";
        do {
            s = hexChars.charAt(n & 15) + s;
            n >>>= 4;
        } while (n > 0);
        
        if (digits != null) {
            while (s.length < digits) {
                s = "0" + s;
            }
        }
        return s;
    }

    /**
     * Provides fast integer matching for switches on strings
     */
    public static inline function fastCodeAt(s: String, index: Int): Int {
        return s.charCodeAt(index);
    }

    /**
     * Returns `true` if `s` contains `value` and `false` otherwise.
     */
    public static function contains(s: String, value: String): Bool {
        return s.indexOf(value) != -1;
    }

    /**
     * Check if a character code represents end of file
     * Used with character reading functions that return -1 for EOF
     */
    public static inline function isEof(c: Int): Bool {
        return c < 0;
    }

    /**
     * Get the UTF-16 code point at the given position
     * This is a compatibility function for unicode iterators
     */
    public static function utf16CodePointAt(s: String, index: Int): Int {
        return s.charCodeAt(index);
    }

    /**
     * Check if a code point is a high surrogate
     */
    public static inline function isHighSurrogate(code: Int): Bool {
        return code >= MIN_HIGH_SURROGATE_CODE_POINT && code <= MAX_HIGH_SURROGATE_CODE_POINT;
    }

    /**
     * Check if a code point is a low surrogate
     */
    public static inline function isLowSurrogate(code: Int): Bool {
        return code >= MIN_LOW_SURROGATE_CODE_POINT && code <= MAX_LOW_SURROGATE_CODE_POINT;
    }

    /**
     * Escape special characters in a string for use in a regular expression
     */
    public static function quoteRegexpMeta(s: String): String {
        // Escape regex special characters
        var specialChars = ["\\", "^", "$", ".", "|", "?", "*", "+", "(", ")", "[", "]", "{", "}"];
        for (char in specialChars) {
            s = replace(s, char, "\\" + char);
        }
        return s;
    }

    /**
     * Convert a string to an integer value, returning null if not possible
     */
    public static function parseInt(str: String): Null<Int> {
        // Handle hex numbers
        if (str.substr(0, 2) == "0x") {
            var hex = str.substr(2);
            var result = 0;
            for (i in 0...hex.length) {
                var c = hex.charCodeAt(i);
                result *= 16;
                if (c >= 48 && c <= 57) { // 0-9
                    result += c - 48;
                } else if (c >= 65 && c <= 70) { // A-F
                    result += c - 65 + 10;
                } else if (c >= 97 && c <= 102) { // a-f
                    result += c - 97 + 10;
                } else {
                    return null;
                }
            }
            return result;
        }
        
        // Handle decimal numbers
        var result = 0;
        var negative = false;
        var start = 0;
        
        if (str.charAt(0) == "-") {
            negative = true;
            start = 1;
        } else if (str.charAt(0) == "+") {
            start = 1;
        }
        
        for (i in start...str.length) {
            var c = str.charCodeAt(i);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            } else {
                return null;
            }
        }
        
        return negative ? -result : result;
    }

    /**
     * Convert a string to a float value, returning null if not possible
     */
    public static function parseFloat(str: String): Null<Float> {
        // Simple float parsing
        return Std.parseFloat(str);
    }
}