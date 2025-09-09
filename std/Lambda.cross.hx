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

/**
 * Lambda provides functional programming utilities for collections.
 * 
 * This is a cross-platform abstraction that uses Elixir's native Enum module
 * for efficient implementation on the Elixir target.
 * 
 * For Elixir-specific code, you can also use elixir.Enum directly.
 * 
 * @see https://api.haxe.org/Lambda.html
 */
class Lambda {
    /**
     * Creates an Array from an Iterable.
     */
    public static function array<T>(it: Iterable<T>): Array<T> {
        var arr = [];
        for (v in it) arr.push(v);
        return arr;
    }
    
    /**
     * Creates an Array from an Iterable (List not available on Elixir target).
     * For compatibility, this returns an Array instead of List.
     */
    public static function list<T>(it: Iterable<T>): Array<T> {
        var arr = [];
        for (v in it) arr.push(v);
        return arr;
    }
    
    /**
     * Returns a new Array containing all elements from both iterables.
     */
    public static function concat<T>(a: Iterable<T>, b: Iterable<T>): Array<T> {
        var arr = [];
        for (v in a) arr.push(v);
        for (v in b) arr.push(v);
        return arr;
    }
    
    /**
     * Returns a new Array by applying function f to all elements.
     */
    public static function map<T, S>(it: Iterable<T>, f: T -> S): Array<S> {
        #if elixir
        return untyped __elixir__('Enum.map({0}, {1})', it, f);
        #else
        var arr = [];
        for (v in it) arr.push(f(v));
        return arr;
        #end
    }
    
    /**
     * Returns a new Array containing all elements for which f returns true.
     */
    public static function filter<T>(it: Iterable<T>, f: T -> Bool): Array<T> {
        #if elixir
        return untyped __elixir__('Enum.filter({0}, {1})', it, f);
        #else
        var arr = [];
        for (v in it) {
            if (f(v)) arr.push(v);
        }
        return arr;
        #end
    }
    
    /**
     * Functional fold (reduce) with standard signature.
     * Note: Haxe's standard fold uses curried functions, but for simplicity
     * and Elixir compatibility, we use a regular two-parameter function.
     */
    public static function fold<T, A>(it: Iterable<T>, f: (T, A) -> A, first: A): A {
        #if elixir
        // Elixir's reduce expects (element, accumulator) order
        return untyped __elixir__('Enum.reduce({0}, {1}, {2})', it, first, f);
        #else
        var acc = first;
        for (v in it) {
            acc = f(v, acc);
        }
        return acc;
        #end
    }
    
    /**
     * Returns the number of elements in the Iterable.
     */
    public static function count<T>(it: Iterable<T>, ?pred: T -> Bool): Int {
        #if elixir
        if (pred == null) {
            return untyped __elixir__('Enum.count({0})', it);
        } else {
            return untyped __elixir__('Enum.count({0}, {1})', it, pred);
        }
        #else
        var n = 0;
        if (pred == null) {
            for (_ in it) n++;
        } else {
            for (v in it) {
                if (pred(v)) n++;
            }
        }
        return n;
        #end
    }
    
    /**
     * Tells if at least one element of the Iterable satisfies predicate f.
     */
    public static function exists<T>(it: Iterable<T>, f: T -> Bool): Bool {
        #if elixir
        return untyped __elixir__('Enum.any?({0}, {1})', it, f);
        #else
        for (v in it) {
            if (f(v)) return true;
        }
        return false;
        #end
    }
    
    /**
     * Tells if all elements of the Iterable satisfy predicate f.
     */
    public static function foreach<T>(it: Iterable<T>, f: T -> Bool): Bool {
        #if elixir
        return untyped __elixir__('Enum.all?({0}, {1})', it, f);
        #else
        for (v in it) {
            if (!f(v)) return false;
        }
        return true;
        #end
    }
    
    /**
     * Returns the first element for which f returns true.
     */
    public static function find<T>(it: Iterable<T>, f: T -> Bool): Null<T> {
        #if elixir
        return untyped __elixir__('Enum.find({0}, {1})', it, f);
        #else
        for (v in it) {
            if (f(v)) return v;
        }
        return null;
        #end
    }
    
    /**
     * Tells if the Iterable does not contain any element.
     */
    public static function empty<T>(it: Iterable<T>): Bool {
        #if elixir
        return untyped __elixir__('Enum.empty?({0})', it);
        #else
        for (_ in it) return false;
        return true;
        #end
    }
    
    /**
     * Returns the index of the first element for which f returns true.
     */
    public static function indexOf<T>(it: Iterable<T>, v: T): Int {
        #if elixir
        var result = untyped __elixir__('Enum.find_index({0}, fn x -> x == {1} end)', it, v);
        return result == null ? -1 : result;
        #else
        var i = 0;
        for (x in it) {
            if (x == v) return i;
            i++;
        }
        return -1;
        #end
    }
    
    /**
     * Tells if it contains v.
     */
    public static function has<T>(it: Iterable<T>, v: T): Bool {
        #if elixir
        return untyped __elixir__('Enum.member?({0}, {1})', it, v);
        #else
        for (x in it) {
            if (x == v) return true;
        }
        return false;
        #end
    }
    
    /**
     * Iterate over elements (shorthand for for loop)
     * This is essential for macro compilation compatibility
     */
    public static function iter<T>(it: Iterable<T>, f: T -> Void): Void {
        #if elixir
        untyped __elixir__('Enum.each({0}, {1})', it, f);
        #else
        for (x in it) f(x);
        #end
    }
}