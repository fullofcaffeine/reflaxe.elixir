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
 * ArrayKeyValueIterator for Reflaxe.Elixir - Type Compatibility Layer
 * 
 * WHY THIS EXISTS:
 * When using @:coreApi on Array, Haxe's type system expects keyValueIterator()
 * to return specifically haxe.iterators.ArrayKeyValueIterator<T>.
 * This is a requirement of the @:coreApi metadata for maintaining type compatibility.
 * 
 * HOW IT WORKS:
 * 1. This class exists purely for type compatibility with Haxe's core Array API
 * 2. The Reflaxe.Elixir compiler recognizes and optimizes away this iterator
 * 3. For-in loops with key-value pairs are transformed to Elixir's Enum.with_index
 * 4. This class is NEVER actually used at runtime in generated Elixir code
 * 
 * ELIXIR TRANSFORMATION:
 * Haxe:   for (i => v in array) { trace(i, v); }
 * Elixir: Enum.with_index(array) |> Enum.each(fn {v, i} -> IO.inspect({i, v}) end)
 * 
 * The ArrayKeyValueIterator is completely eliminated during compilation.
 */
class ArrayKeyValueIterator<T> {
    final array: Array<T>;
    var current: Int = 0;
    
    /**
     * Create a new ArrayKeyValueIterator.
     * NOTE: This constructor is only called at compile-time for type checking.
     * The actual iterator is never instantiated in generated Elixir code.
     */
    public inline function new(array: Array<T>) {
        this.array = array;
    }
    
    /**
     * Check if there are more elements.
     * NOTE: Transformed to Enum.with_index in Elixir.
     */
    public inline function hasNext(): Bool {
        return current < array.length;
    }
    
    /**
     * Get the next key-value pair.
     * NOTE: Transformed to Enum.with_index in Elixir.
     */
    public inline function next(): {key: Int, value: T} {
        var index = current++;
        return {key: index, value: array[index]};
    }
}