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
 * This is Layer 3 of the layered architecture - Haxe's cross-platform abstractions
 * built on top of Elixir's native Enum module for efficient implementation.
 * 
 * For Elixir-specific code, you can also use elixir.Enum directly for more idiomatic patterns.
 * 
 * @see https://api.haxe.org/Lambda.html
 */
class Lambda {
    /**
     * Creates an Array from an Iterable.
     * If the Iterable is already an Array, returns it unchanged.
     */
    public static function array<T>(it: Iterable<T>): Array<T> {
        #if elixir
        // Use Elixir's Enum.to_list for efficient conversion
        return elixir.Enum.toList(it);
        #else
        var arr = new Array<T>();
        for (v in it) arr.push(v);
        return arr;
        #end
    }
    
    /**
     * Returns a List containing all elements of the Iterable.
     * Note: In Elixir target, List is represented as Array
     */
    public static function list<T>(it: Iterable<T>): List<T> {
        #if elixir
        // In Elixir, we use arrays for lists
        var result = elixir.Enum.toList(it);
        return List.fromArray(result);
        #else
        var l = new List<T>();
        for (v in it) l.add(v);
        return l;
        #end
    }
    
    /**
     * Creates a new List by applying function f to all elements of the Iterable.
     */
    public static function map<T,R>(it: Iterable<T>, f: T -> R): List<R> {
        #if elixir
        var result = elixir.Enum.map(it, f);
        return List.fromArray(result);
        #else
        var l = new List<R>();
        for (v in it) l.add(f(v));
        return l;
        #end
    }
    
    /**
     * Creates a new List by applying function f to all elements of the Iterable
     * and concatenating the results.
     */
    public static function flatMap<T,R>(it: Iterable<T>, f: T -> Iterable<R>): List<R> {
        #if elixir
        var result = elixir.Enum.flatMap(it, f);
        return List.fromArray(result);
        #else
        var l = new List<R>();
        for (v in it) {
            for (r in f(v)) {
                l.add(r);
            }
        }
        return l;
        #end
    }
    
    /**
     * Returns a List containing only elements of the Iterable for which f returns true.
     */
    public static function filter<T>(it: Iterable<T>, f: T -> Bool): List<T> {
        #if elixir
        var result = elixir.Enum.filter(it, f);
        return List.fromArray(result);
        #else
        var l = new List<T>();
        for (v in it) {
            if (f(v)) l.add(v);
        }
        return l;
        #end
    }
    
    /**
     * Functional fold (left-to-right), also known as reduce.
     * Applies function f to the first element and the initial value first,
     * then applies f to the result and the next element, and so on.
     */
    public static function fold<T,Acc>(it: Iterable<T>, f: T -> Acc -> Acc, first: Acc): Acc {
        #if elixir
        // Note: Elixir's reduce has parameters in different order (element, acc)
        return elixir.Enum.reduce(it, first, function(item, acc) return f(item)(acc));
        #else
        for (v in it) {
            first = f(v)(first);
        }
        return first;
        #end
    }
    
    /**
     * Returns the number of elements in the Iterable.
     */
    public static function count<T>(it: Iterable<T>, ?pred: T -> Bool): Int {
        #if elixir
        if (pred == null) {
            return elixir.Enum.count(it);
        } else {
            return elixir.Enum.countBy(it, pred);
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
     * Tells if the Iterable does not contain any element.
     */
    public static function empty<T>(it: Iterable<T>): Bool {
        #if elixir
        return elixir.Enum.empty(it);
        #else
        for (_ in it) return false;
        return true;
        #end
    }
    
    /**
     * Tells if at least one element of the Iterable satisfies predicate f.
     */
    public static function exists<T>(it: Iterable<T>, f: T -> Bool): Bool {
        #if elixir
        return elixir.Enum.any(it, f);
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
        return elixir.Enum.all(it, f);
        #else
        for (v in it) {
            if (!f(v)) return false;
        }
        return true;
        #end
    }
    
    /**
     * Calls function f for each element of the Iterable.
     */
    public static function iter<T>(it: Iterable<T>, f: T -> Void): Void {
        #if elixir
        elixir.Enum.each(it, f);
        #else
        for (v in it) f(v);
        #end
    }
    
    /**
     * Returns the first element of the Iterable for which predicate f returns true.
     * Returns null if no such element is found.
     */
    public static function find<T>(it: Iterable<T>, f: T -> Bool): Null<T> {
        #if elixir
        return elixir.Enum.find(it, f);
        #else
        for (v in it) {
            if (f(v)) return v;
        }
        return null;
        #end
    }
    
    /**
     * Returns the index of the first element for which predicate f returns true.
     * Returns -1 if no such element is found.
     */
    public static function findIndex<T>(it: Iterable<T>, f: T -> Bool): Int {
        #if elixir
        // Use Enum.with_index to get indexed pairs, then find
        var indexed = elixir.Enum.withIndex(it);
        for (pair in indexed) {
            // pair is a tuple {element, index}
            var element = untyped __elixir__('elem({0}, 0)', pair);
            var index = untyped __elixir__('elem({0}, 1)', pair);
            if (f(element)) return index;
        }
        return -1;
        #else
        var i = 0;
        for (v in it) {
            if (f(v)) return i;
            i++;
        }
        return -1;
        #end
    }
    
    /**
     * Returns a List containing elements e of the Iterable for which
     * pred(e) is true. Also returns a List containing all other elements.
     * Returned as {trues: List<T>, falses: List<T>}
     */
    public static function partition<T>(it: Iterable<T>, pred: T -> Bool): {trues: List<T>, falses: List<T>} {
        #if elixir
        var result = elixir.Enum.splitWith(it, pred);
        // result is a tuple {trues, falses}
        var trues = untyped __elixir__('elem({0}, 0)', result);
        var falses = untyped __elixir__('elem({0}, 1)', result);
        return {
            trues: List.fromArray(trues),
            falses: List.fromArray(falses)
        };
        #else
        var trues = new List<T>();
        var falses = new List<T>();
        for (v in it) {
            if (pred(v)) {
                trues.add(v);
            } else {
                falses.add(v);
            }
        }
        return {trues: trues, falses: falses};
        #end
    }
    
    /**
     * Tells if element v is part of the Iterable.
     */
    public static function has<T>(it: Iterable<T>, v: T): Bool {
        #if elixir
        return elixir.Enum.member(it, v);
        #else
        for (x in it) {
            if (x == v) return true;
        }
        return false;
        #end
    }
    
    /**
     * Returns the index of element v within the Iterable.
     * Returns -1 if element is not found.
     */
    public static function indexOf<T>(it: Iterable<T>, v: T): Int {
        #if elixir
        var indexed = elixir.Enum.withIndex(it);
        for (pair in indexed) {
            var element = untyped __elixir__('elem({0}, 0)', pair);
            var index = untyped __elixir__('elem({0}, 1)', pair);
            if (element == v) return index;
        }
        return -1;
        #else
        var i = 0;
        for (x in it) {
            if (x == v) return i;
            i++;
        }
        return -1;
        #end
    }
}