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
@:coreApi
class StringBuf {
    // Internal iolist representation for Elixir
    // This will be compiled to an Elixir list that can contain binaries and nested lists
    @:native("iolist")
    private var parts: Dynamic;
    
    /**
     * Creates a new StringBuf instance.
     * In Elixir, initializes an empty iolist.
     */
    public function new() {
        untyped __elixir__('[]');
        // Initialize as empty iolist
        this.parts = untyped __elixir__('[]');
    }
    
    /**
     * Returns the length of `this` StringBuf in characters.
     * 
     * Note: This requires converting iolist to binary and measuring.
     * For performance-critical code, avoid calling this frequently.
     */
    public var length(get, never): Int;
    
    private function get_length(): Int {
        // Convert iolist to binary and get byte size
        return untyped __elixir__('byte_size(IO.iodata_to_binary({0}))', this.parts);
    }
    
    /**
     * Appends the representation of `x` to `this` StringBuf.
     * 
     * The exact representation of `x` may vary per platform.
     * 
     * If `x` is null, the String "null" is appended.
     */
    public function add<T>(x: T): Void {
        var str = if (x == null) "null" else Std.string(x);
        // Append to iolist - this is O(1) in Elixir
        this.parts = untyped __elixir__('{0} ++ [{1}]', this.parts, str);
    }
    
    /**
     * Appends the character identified by `c` to `this` StringBuf.
     * 
     * If `c` is negative or has another invalid value, the result is unspecified.
     */
    public function addChar(c: Int): Void {
        // In Elixir, we can add the character code directly to the iolist
        // It will be treated as a byte value
        this.parts = untyped __elixir__('{0} ++ [{1}]', this.parts, c);
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
        
        // Extract substring and add to iolist
        var substr = if (len == null) {
            untyped __elixir__('String.slice({0}, {1}..-1)', s, pos);
        } else {
            untyped __elixir__('String.slice({0}, {1}, {2})', s, pos, len);
        };
        
        this.parts = untyped __elixir__('{0} ++ [{1}]', this.parts, substr);
    }
    
    /**
     * Returns the content of `this` StringBuf as a String.
     * 
     * For Elixir, this efficiently converts the iolist to a binary string.
     */
    public function toString(): String {
        // Use IO.iodata_to_binary to efficiently convert iolist to string
        // This is the idiomatic way in Elixir
        return untyped __elixir__('IO.iodata_to_binary({0})', this.parts);
    }
}