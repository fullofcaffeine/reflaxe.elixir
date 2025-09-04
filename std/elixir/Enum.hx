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

package elixir;

/**
 * 1:1 extern mapping to Elixir's Enum module
 * 
 * Provides direct access to Elixir's Enum functions with type safety.
 * This is Layer 2 of the layered architecture - faithful Elixir API mappings.
 * 
 * Usage:
 * ```haxe
 * import elixir.Enum;
 * 
 * var doubled = Enum.map([1, 2, 3], function(x) return x * 2);
 * var sum = Enum.reduce(doubled, 0, function(x, acc) return x + acc);
 * ```
 * 
 * For cross-platform code, use Lambda instead, which builds on top of this.
 * 
 * @see https://hexdocs.pm/elixir/Enum.html
 */
@:native("Enum")
extern class Enum {
    /**
     * Invokes fun for each element in the enumerable, passing that element and the accumulator as arguments.
     * fun's return value is stored in the accumulator.
     */
    static function reduce<T,Acc>(enumerable: Iterable<T>, acc: Acc, fun: (T, Acc) -> Acc): Acc;
    
    /**
     * Returns a list where each element is the result of invoking fun on each corresponding element of enumerable.
     */
    static function map<T,R>(enumerable: Array<T>, fun: T -> R): Array<R>;
    
    /**
     * Filters the enumerable, i.e. returns only those elements for which fun returns a truthy value.
     */
    static function filter<T>(enumerable: Array<T>, fun: T -> Bool): Array<T>;
    
    /**
     * Returns true if all elements in enumerable are truthy.
     * If fun is given, it evaluates fun for each element.
     */
    @:overload(function<T>(enumerable: Array<T>): Bool {})
    static function all<T>(enumerable: Array<T>, fun: T -> Bool): Bool;
    
    /**
     * Returns true if at least one element in enumerable is truthy.
     * If fun is given, it evaluates fun for each element.
     */
    @:overload(function<T>(enumerable: Array<T>): Bool {})
    static function any<T>(enumerable: Array<T>, fun: T -> Bool): Bool;
    
    /**
     * Finds the element at the given index (zero-based).
     * Returns default if index is out of bounds.
     */
    @:overload(function<T>(enumerable: Array<T>, index: Int): Null<T> {})
    static function at<T>(enumerable: Array<T>, index: Int, defaultValue: T): T;
    
    /**
     * Returns a list with the elements of enumerable in reverse order.
     */
    static function reverse<T>(enumerable: Array<T>): Array<T>;
    
    /**
     * Sorts the enumerable according to Erlang's term ordering.
     */
    static function sort<T>(enumerable: Array<T>): Array<T>;
    
    /**
     * Returns the size of the enumerable.
     */
    static function count<T>(enumerable: Array<T>): Int;
    
    /**
     * Invokes the given fun for each element in the enumerable.
     * Returns :ok.
     */
    static function each<T>(enumerable: Array<T>, fun: T -> Void): Void;
    
    /**
     * Determines if the enumerable is empty.
     */
    static function empty<T>(enumerable: Array<T>): Bool;
    
    /**
     * Returns the first element for which fun returns a truthy value.
     * Returns nil if no such element is found.
     */
    @:overload(function<T>(enumerable: Array<T>, defaultValue: T, fun: T -> Bool): T {})
    static function find<T>(enumerable: Array<T>, fun: T -> Bool): Null<T>;
    
    /**
     * Maps and flattens the enumerable in one pass.
     */
    @:native("flat_map")
    static function flatMap<T,R>(enumerable: Array<T>, fun: T -> Array<R>): Array<R>;
    
    /**
     * Splits the enumerable into groups based on key_fun.
     */
    @:native("group_by")
    static function groupBy<T,K>(enumerable: Array<T>, keyFun: T -> K): Map<K, Array<T>>;
    
    /**
     * Joins the given enumerable into a string using joiner as separator.
     */
    @:overload(function<T>(enumerable: Array<T>): String {})
    static function join<T>(enumerable: Array<T>, joiner: String): String;
    
    /**
     * Returns the maximal element in the enumerable.
     */
    static function max<T>(enumerable: Array<T>): T;
    
    /**
     * Returns the minimal element in the enumerable.
     */
    static function min<T>(enumerable: Array<T>): T;
    
    /**
     * Returns a random element of enumerable.
     */
    static function random<T>(enumerable: Array<T>): T;
    
    /**
     * Returns the sum of all elements.
     */
    static function sum(enumerable: Array<Float>): Float;
    
    /**
     * Takes the first count elements from the enumerable.
     */
    static function take<T>(enumerable: Array<T>, count: Int): Array<T>;
    
    /**
     * Enumerates the enumerable, removing all duplicates.
     */
    static function uniq<T>(enumerable: Array<T>): Array<T>;
    
    /**
     * Zips corresponding elements from two enumerables into a list of tuples.
     */
    static function zip<T,U>(enumerable1: Dynamic, enumerable2: Dynamic): Array<Dynamic>;
    
    /**
     * Reduce the enumerable until fun returns {:halt, acc}.
     * Use with ReduceWhileResult enum for type safety.
     */
    @:native("reduce_while")
    static function reduceWhile<T,Acc>(enumerable: Dynamic, acc: Acc, fun: (T, Acc) -> Dynamic): Acc;
    
    /**
     * Maps and reduces an enumerable, flattening the given results.
     */
    @:native("flat_map_reduce")
    static function flatMapReduce<T,R,Acc>(enumerable: Dynamic, acc: Acc, fun: (T, Acc) -> Dynamic): Dynamic;
    
    /**
     * Chunks the enumerable with count elements each.
     */
    @:native("chunk_every")
    static function chunkEvery<T>(enumerable: Dynamic, count: Int): Array<Array<T>>;
    
    /**
     * Converts enumerable to a list.
     */
    @:native("to_list")
    static function toList<T>(enumerable: Dynamic): Array<T>;
    
    /**
     * Drops the first count elements from the enumerable.
     */
    static function drop<T>(enumerable: Dynamic, count: Int): Array<T>;
    
    /**
     * Drops elements at the beginning of the enumerable while fun returns a truthy value.
     */
    @:native("drop_while")
    static function dropWhile<T>(enumerable: Dynamic, fun: T -> Bool): Array<T>;
    
    /**
     * Takes elements at the beginning of the enumerable while fun returns a truthy value.
     */
    @:native("take_while")
    static function takeWhile<T>(enumerable: Dynamic, fun: T -> Bool): Array<T>;
    
    
    /**
     * Returns true if enumerable has exactly count elements.
     */
    @:native("count")
    @:overload(function<T>(enumerable: Dynamic): Int {})
    static function countBy<T>(enumerable: Dynamic, fun: T -> Bool): Int;
    
    /**
     * Returns the first element of the enumerable or default if empty.
     */
    @:overload(function<T>(enumerable: Dynamic): Null<T> {})
    static function fetch<T>(enumerable: Dynamic, index: Int): Dynamic;
    
    /**
     * Fetches the value at the given index, erroring out if index is out of bounds.
     */
    @:native("fetch!")
    static function fetchOrThrow<T>(enumerable: Dynamic, index: Int): T;
    
    /**
     * Checks if element is a member of enumerable.
     */
    static function member<T>(enumerable: Array<T>, element: T): Bool;
    
    /**
     * Applies fun on each element of enumerable and rejects the elements for which fun returns a truthy value.
     */
    static function reject<T>(enumerable: Dynamic, fun: T -> Bool): Array<T>;
    
    /**
     * Shuffles the elements of the enumerable.
     */
    static function shuffle<T>(enumerable: Dynamic): Array<T>;
    
    /**
     * Splits enumerable into two lists based on the given function.
     * Returns a tuple with two lists.
     */
    static function split<T>(enumerable: Dynamic, count: Int): Dynamic;
    
    /**
     * Splits the enumerable in two lists according to the given function fun.
     */
    @:native("split_with")
    static function splitWith<T>(enumerable: Dynamic, fun: T -> Bool): Dynamic;
    
    /**
     * Enumerates the enumerable, returning a list where each element is a tuple with the original element
     * and its index (zero-based).
     */
    @:native("with_index")
    @:overload(function<T>(enumerable: Dynamic): Array<Dynamic> {})
    static function withIndex<T>(enumerable: Dynamic, startAt: Int): Array<Dynamic>;
}

/**
 * Result type for reduce_while operations.
 * Maps to Elixir's {:cont, acc} and {:halt, acc} tuples.
 */
enum ReduceWhileResult<T> {
    /**
     * Continue reducing with the given accumulator value
     */
    Cont(value: T);
    
    /**
     * Halt reduction and return the given accumulator value
     */
    Halt(value: T);
}