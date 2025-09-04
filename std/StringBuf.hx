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
 * 
 * ## Usage Example (Haxe)
 * ```haxe
 * var buf = new StringBuf();
 * buf.add("Hello");
 * buf.add(" ");
 * buf.add("World");
 * var result = buf.toString(); // "Hello World"
 * ```
 * 
 * ## Generated Idiomatic Elixir
 * ```elixir
 * # StringBuf.new() generates:
 * iolist = []
 * 
 * # buf.add("Hello") generates:
 * iolist = iolist ++ ["Hello"]
 * 
 * # buf.toString() generates:
 * IO.iodata_to_binary(iolist)
 * ```
 * 
 * ## Performance Characteristics
 * - **O(1)** append operations (iolists are linked lists)
 * - **O(n)** final conversion to string
 * - **Memory efficient** - no intermediate string concatenations
 * - **BEAM optimized** - iolists are a core Erlang/Elixir pattern
 * 
 * @see https://www.erlang.org/doc/efficiency_guide/listhandling#iolist
 */
@:coreApi
class StringBuf {
    // Internal iolist representation for Elixir
    // Using Array<String> which will naturally compile to Elixir lists
    // The compiler will handle the conversion to proper iolist structure
    private var parts: Array<String>;
    
    /**
     * Creates a new StringBuf instance.
     * In Elixir, initializes an empty iolist.
     */
    public function new() {
        // Initialize as empty array which compiles to Elixir list
        this.parts = [];
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
        // Join all parts and measure the string length
        var joined = parts.join("");
        return joined.length;
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
        // Append to array - this compiles to list append in Elixir
        this.parts.push(str);
    }
    
    /**
     * Appends the character identified by `c` to `this` StringBuf.
     * 
     * If `c` is negative or has another invalid value, the result is unspecified.
     */
    public function addChar(c: Int): Void {
        // Convert character code to string and add
        this.parts.push(String.fromCharCode(c));
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
        
        // Extract substring and add to array
        var substr = if (len == null) {
            s.substr(pos);
        } else {
            s.substr(pos, len);
        };
        
        this.parts.push(substr);
    }
    
    /**
     * Returns the content of `this` StringBuf as a String.
     * 
     * For Elixir, this efficiently converts the iolist to a binary string.
     */
    public function toString(): String {
        // For optimal Elixir generation, we use __elixir__ to generate idiomatic iolist code
        // The parts array will be compiled as a list, and IO.iodata_to_binary is the
        // most efficient way to convert it to a binary string in Elixir
        return untyped __elixir__('IO.iodata_to_binary({0})', this.parts);
    }
}