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
 * A String buffer is an efficient way to build a big string by appending small elements together.
 * 
 * For Elixir target, this is implemented using iolists for optimal performance.
 * Instead of string concatenation, we build a list that Elixir can efficiently convert to binary.
 */
class StringBuf {
    // Store strings in a list for efficient iolist conversion
    private var parts: Array<String>;
    
    /**
     * Creates a new StringBuf instance.
     */
    public function new() {
        parts = [];
    }
    
    /**
     * Returns the length of `this` StringBuf in characters.
     * 
     * Note: This requires iterating through all parts to calculate total length.
     * For performance-critical code, avoid calling this frequently.
     */
    public var length(get, never): Int;
    
    private function get_length(): Int {
        var len = 0;
        for (part in parts) {
            len += part.length;
        }
        return len;
    }
    
    /**
     * Appends the representation of `x` to `this` StringBuf.
     * 
     * The exact representation of `x` may vary per platform.
     * 
     * If `x` is null, the String "null" is appended.
     */
    public function add<T>(x: T): Void {
        if (x == null) {
            parts.push("null");
        } else {
            parts.push(Std.string(x));
        }
    }
    
    /**
     * Appends the character identified by `c` to `this` StringBuf.
     * 
     * If `c` is negative or has another invalid value, the result is unspecified.
     */
    public function addChar(c: Int): Void {
        parts.push(String.fromCharCode(c));
    }
    
    /**
     * Appends a substring of `s` to `this` StringBuf.
     * 
     * This function appends `len` characters of `s`, starting at position `pos`,
     * to `this` StringBuf.
     * 
     * If `len` is omitted, `s` is appended from `pos` to its end.
     * 
     * If `pos` or `len` are negative or exceed the boundaries of `s`, the result
     * is unspecified.
     */
    public function addSub(s: String, pos: Int, ?len: Int): Void {
        if (s == null) return;
        
        if (len == null) {
            parts.push(s.substr(pos));
        } else {
            parts.push(s.substr(pos, len));
        }
    }
    
    /**
     * Returns the content of `this` StringBuf as a String.
     * 
     * For Elixir, this efficiently converts the iolist to a binary string.
     */
    public function toString(): String {
        // Join all parts into a single string
        // In Elixir, this will be optimized to use iolist_to_binary
        return parts.join("");
    }
}