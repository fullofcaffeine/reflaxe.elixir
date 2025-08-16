package;

/**
 * ArrayTools static extension for functional array methods
 * 
 * Provides functional programming methods for Array<T> including:
 * - Accumulation: reduce, fold
 * - Search: find, findIndex  
 * - Predicates: exists/any, all/foreach
 * - Collection ops: forEach, take, drop, flatMap
 * 
 * Usage:
 *   using ArrayTools;
 *   var numbers = [1, 2, 3, 4, 5];
 *   var sum = numbers.reduce((acc, item) -> acc + item, 0);
 */
class ArrayTools {
    
    /**
     * Reduces array to single value using accumulator function
     * @param array The array to reduce
     * @param func Accumulator function (acc, item) -> newAcc
     * @param initial Initial accumulator value
     * @return Final accumulated value
     */
    public static function reduce<T, U>(array: Array<T>, func: (U, T) -> U, initial: U): U {
        var acc = initial;
        for (item in array) {
            acc = func(acc, item);
        }
        return acc;
    }
    
    /**
     * Alias for reduce - reduces array to single value
     * @param array The array to fold
     * @param func Accumulator function (acc, item) -> newAcc  
     * @param initial Initial accumulator value
     * @return Final accumulated value
     */
    public static function fold<T, U>(array: Array<T>, func: (U, T) -> U, initial: U): U {
        return reduce(array, func, initial);
    }
    
    /**
     * Finds first element matching predicate
     * @param array The array to search
     * @param predicate Test function
     * @return First matching element or null
     */
    public static function find<T>(array: Array<T>, predicate: T -> Bool): Null<T> {
        for (item in array) {
            if (predicate(item)) return item;
        }
        return null;
    }
    
    /**
     * Finds index of first element matching predicate
     * @param array The array to search
     * @param predicate Test function
     * @return Index of first match or -1
     */
    public static function findIndex<T>(array: Array<T>, predicate: T -> Bool): Int {
        for (i in 0...array.length) {
            if (predicate(array[i])) return i;
        }
        return -1;
    }
    
    /**
     * Tests if any element matches predicate
     * @param array The array to test
     * @param predicate Test function
     * @return True if any element matches
     */
    public static function exists<T>(array: Array<T>, predicate: T -> Bool): Bool {
        for (item in array) {
            if (predicate(item)) return true;
        }
        return false;
    }
    
    /**
     * Alias for exists - tests if any element matches
     */
    public static function any<T>(array: Array<T>, predicate: T -> Bool): Bool {
        return exists(array, predicate);
    }
    
    /**
     * Tests if all elements match predicate
     * @param array The array to test
     * @param predicate Test function
     * @return True if all elements match
     */
    public static function foreach<T>(array: Array<T>, predicate: T -> Bool): Bool {
        for (item in array) {
            if (!predicate(item)) return false;
        }
        return true;
    }
    
    /**
     * Alias for foreach - tests if all elements match
     */
    public static function all<T>(array: Array<T>, predicate: T -> Bool): Bool {
        return foreach(array, predicate);
    }
    
    /**
     * Executes function for each element (side effects)
     * @param array The array to iterate
     * @param action Function to execute for each element
     */
    public static function forEach<T>(array: Array<T>, action: T -> Void): Void {
        for (item in array) {
            action(item);
        }
    }
    
    /**
     * Returns first n elements
     * @param array The source array
     * @param n Number of elements to take
     * @return New array with first n elements
     */
    public static function take<T>(array: Array<T>, n: Int): Array<T> {
        return array.slice(0, n);
    }
    
    /**
     * Skips first n elements
     * @param array The source array  
     * @param n Number of elements to skip
     * @return New array without first n elements
     */
    public static function drop<T>(array: Array<T>, n: Int): Array<T> {
        return array.slice(n);
    }
    
    /**
     * Maps and flattens the result
     * @param array The source array
     * @param mapper Function that returns array for each element
     * @return Flattened result array
     */
    public static function flatMap<T, U>(array: Array<T>, mapper: T -> Array<U>): Array<U> {
        var result: Array<U> = [];
        for (item in array) {
            var mapped = mapper(item);
            for (mappedItem in mapped) {
                result.push(mappedItem);
            }
        }
        return result;
    }
}