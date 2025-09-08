/*
 * Copyright (C)2005-2025 Haxe Foundation
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

package haxe.iterators;

/**
 * ArrayIterator for Reflaxe.Elixir
 * 
 * This class provides type compatibility with Haxe's Array.iterator() API.
 * In Elixir, iterator patterns are transformed directly to Enum operations
 * at compile time, so this class exists only for type checking.
 * 
 * ## Usage Example (Haxe)
 * ```haxe
 * var arr = [1, 2, 3];
 * for (item in arr) {  // Uses iterator internally
 *     trace(item);
 * }
 * ```
 * 
 * ## Generated Idiomatic Elixir
 * ```elixir
 * arr = [1, 2, 3]
 * Enum.each(arr, fn item -> IO.inspect(item) end)
 * ```
 * 
 * The compiler transforms iterator-based patterns to idiomatic Enum operations,
 * so the ArrayIterator methods are never actually called in generated code.
 * 
 * Note: This class uses inline methods to provide compile-time compatibility
 * while the AST transformer handles the actual iteration pattern conversion.
 */
@:coreApi
class ArrayIterator<T> {
    final array: Array<T>;
    var current: Int = 0;
    
    /**
     * Create a new ArrayIterator.
     * This constructor exists for type compatibility with code that
     * manually creates iterators (like BalancedTree), but the actual
     * iteration is transformed to Enum operations by the compiler.
     */
    public inline function new(array: Array<T>) {
        this.array = array;
    }
    
    /**
     * Check if there are more elements.
     * At runtime, this is transformed to Enum pattern matching.
     */
    public inline function hasNext(): Bool {
        return current < array.length;
    }
    
    /**
     * Get the next element.
     * At runtime, this is transformed to Enum iteration.
     */
    public inline function next(): T {
        return array[current++];
    }
}