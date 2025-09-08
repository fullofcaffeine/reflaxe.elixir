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
 * The Elixir runtime implementation (lib/array_iterator.ex) simply returns
 * the array itself since Elixir lists are already iterable.
 * 
 * ## Usage Example (Haxe)
 * ```haxe
 * var arr = [1, 2, 3];
 * var iter = arr.iterator();  // Returns ArrayIterator
 * ```
 * 
 * ## Generated Idiomatic Elixir
 * ```elixir
 * arr = [1, 2, 3]
 * iter = ArrayIterator.new(arr)  # Returns arr itself via runtime module
 * ```
 */
@:coreApi
@:native("ArrayIterator")
class ArrayIterator<T> {
    final array: Array<T>;
    var current: Int = 0;
    
    /**
     * Create a new ArrayIterator.
     * The Elixir runtime module handles this by returning the array itself.
     */
    public function new(array: Array<T>) {
        this.array = array;
    }
    
    /**
     * Check if there are more elements.
     */
    public function hasNext(): Bool {
        return current < array.length;
    }
    
    /**
     * Get the next element.
     */
    public function next(): T {
        return array[current++];
    }
}