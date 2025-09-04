/**
 * Array implementation for Reflaxe.Elixir - Layer 3 (Haxe Standard Library)
 * 
 * WHY: Provide cross-platform Array API that generates idiomatic Elixir
 * WHAT: Maps Haxe array methods to Elixir extern functions (Layer 2)
 * HOW: Uses __elixir__() for direct native calls to Enum and List modules
 * 
 * ARCHITECTURE: This is Layer 3 of the layered API architecture.
 * It builds on top of Layer 2 (Elixir externs) to provide Haxe's
 * cross-platform Array contract while generating idiomatic Elixir.
 * 
 * ## What is @:coreApi?
 * 
 * @:coreApi is a special Haxe compiler metadata that allows us to completely
 * replace Haxe's built-in types with our own custom versions. It's ONLY used
 * for core language types that are fundamental to Haxe itself.
 * 
 * ## Which Types Need @:coreApi?
 * 
 * Only these core Haxe types require @:coreApi:
 * - **Array**: Fundamental collection type (what we're defining here)
 * - **String**: Built-in string type (if we override it)
 * - **Date**: Date/time handling (if we override it)
 * - **Map types**: StringMap, IntMap, ObjectMap (if we override them)
 * - **EReg**: Regular expressions (if we override it)
 * - **Math**: Math operations (if we override it)
 * - **Std**: Standard library functions (if we override it)
 * 
 * Most standard library types (Option, Result, List, etc.) do NOT use @:coreApi
 * because they're not replacing Haxe's built-in types - they're additional types.
 * 
 * Think of it like this: Haxe comes with a default Array class that works
 * across all platforms (JavaScript, C++, Java, etc.). But when compiling to
 * Elixir, we want Arrays to become Elixir lists, not some generic Array object.
 * 
 * @:coreApi tells Haxe: "Don't use your built-in Array. Use this one instead."
 * 
 * ## Why Do We Need @:coreApi for Array?
 * 
 * 1. **Native Integration**: Without it, Haxe would generate its own Array
 *    implementation that doesn't match Elixir's lists. We'd get something like
 *    a custom Array module instead of using Elixir's native lists.
 * 
 * 2. **Idiomatic Code**: With @:coreApi, [1,2,3] in Haxe becomes [1,2,3] in Elixir
 *    (a native list), not some Array.new() wrapper object.
 * 
 * 3. **Performance**: We can map directly to Elixir's Enum functions instead
 *    of reimplementing array operations from scratch.
 * 
 * ## Requirements When Using @:coreApi
 * 
 * When we use @:coreApi, we MUST provide EVERY method that Haxe's Array has:
 * - length, push, pop, shift, unshift, etc.
 * - iterator() must return haxe.iterators.ArrayIterator<T> (not just Iterator<T>)
 * - keyValueIterator() must return haxe.iterators.ArrayKeyValueIterator<T>
 * 
 * If we miss any method or return the wrong type, compilation fails with
 * "Field X has different type than in core type" errors.
 * 
 * ## How This Works With Elixir
 * 
 * Haxe Arrays are mutable: array.push(item) modifies the array
 * Elixir lists are immutable: list ++ [item] creates a new list
 * 
 * Our @:coreApi Array bridges this gap:
 * - It provides Haxe's mutable API (for compatibility)
 * - But generates Elixir's immutable operations (for correctness)
 * - The compiler handles rebinding variables when needed
 */
@:coreApi
class Array<T> {
    /**
     * The length of the array
     */
    public var length(default, null): Int;
    
    /**
     * Creates a new Array
     */
    public function new(): Void {
        untyped __elixir__("[]");
    }
    
    /**
     * Adds an element at the end of the array
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function push(x: T): Int {
        #if elixir_warn_mutability
        // WARNING: Creates a new list in Elixir (immutable)
        #end
        // Using __elixir__ for efficiency since ++ is a native operator
        untyped __elixir__("{0} ++ [{1}]", this, x);
        return length;
    }
    
    /**
     * Removes and returns the last element
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function pop(): Null<T> {
        return untyped __elixir__('List.last({0})', this);
    }
    
    /**
     * Creates a new array by applying function f to all elements
     */
    public function map<S>(f: T -> S): Array<S> {
        return untyped __elixir__('Enum.map({0}, {1})', this, f);
    }
    
    /**
     * Returns a new array containing only elements for which f returns true
     */
    public function filter(f: T -> Bool): Array<T> {
        return untyped __elixir__('Enum.filter({0}, {1})', this, f);
    }
    
    /**
     * Concatenates two arrays
     */
    public function concat(a: Array<T>): Array<T> {
        // Using __elixir__ for ++ operator which is most efficient
        return untyped __elixir__("{0} ++ {1}", this, a);
    }
    
    /**
     * Returns a string representation of the array
     */
    public function toString(): String {
        // inspect is a Kernel function, not in our externs yet
        return untyped __elixir__("inspect({0})", this);
    }
    
    /**
     * Returns a copy of the array
     */
    public function copy(): Array<T> {
        // In Elixir, lists are already immutable, so just return self
        return untyped __elixir__("{0}", this);
    }
    
    /**
     * Reverses the array
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function reverse(): Void {
        #if elixir_warn_mutability
        @:compilerWarning("Array.reverse() creates a new list in Elixir, not in-place mutation")
        #end
        // Note: Assignment must be handled by compiler
        untyped __elixir__('Enum.reverse({0})', this);
    }
    
    /**
     * Sorts the array
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function sort(f: T -> T -> Int): Void {
        #if elixir_warn_mutability
        @:compilerWarning("Array.sort() creates a new list in Elixir, not in-place mutation")
        #end
        // Note: Assignment must be handled by compiler
        untyped __elixir__('Enum.sort({0})', this);
    }
    
    /**
     * Checks if the array contains an element
     */
    public function contains(x: T): Bool {
        return untyped __elixir__('Enum.member?({0}, {1})', this, x);
    }
    
    /**
     * Returns the index of the first occurrence of x
     */
    public function indexOf(x: T, ?fromIndex: Int = 0): Int {
        // Using __elixir__ for complex expression with || operator
        return untyped __elixir__("Enum.find_index({0}, fn item -> item == {1} end) || -1", this, x);
    }
    
    /**
     * Returns the index of the last occurrence of x
     */
    public function lastIndexOf(x: T, ?fromIndex: Int): Int {
        if (fromIndex == null) {
            return untyped __elixir__("
                case Enum.reverse({0}) |> Enum.find_index(fn item -> item == {1} end) do
                    nil -> -1
                    idx -> length({0}) - idx - 1
                end
            ", this, x);
        } else {
            // Handle fromIndex case
            return untyped __elixir__("
                {0}
                |> Enum.slice(0, {2} + 1)
                |> Enum.reverse()
                |> Enum.find_index(fn item -> item == {1} end)
                |> case do
                    nil -> -1
                    idx -> {2} - idx
                end
            ", this, x, fromIndex);
        }
    }
    
    /**
     * Removes and returns the first element
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function shift(): Null<T> {
        return untyped __elixir__('List.first({0})', this);
    }
    
    /**
     * Adds an element to the beginning of the array
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function unshift(x: T): Void {
        #if elixir_warn_mutability
        // WARNING: Creates a new list in Elixir (immutable)
        #end
        // Using __elixir__ for list construction syntax
        untyped __elixir__("[{1} | {0}]", this, x);
    }
    
    /**
     * Joins array elements into a string
     */
    public function join(sep: String): String {
        return untyped __elixir__('Enum.join({0}, {1})', this, sep);
    }
    
    /**
     * Returns a slice of the array
     */
    public function slice(pos: Int, ?end: Int): Array<T> {
        // Using __elixir__ for range syntax which is most efficient
        if (end == null) {
            return untyped __elixir__("Enum.slice({0}, {1}..-1)", this, pos);
        } else {
            return untyped __elixir__("Enum.slice({0}, {1}..{2})", this, pos, end);
        }
    }
    
    /**
     * Removes and returns an element at the specified position
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function splice(pos: Int, len: Int): Array<T> {
        return untyped __elixir__('List.delete_at({0}, {1})', this, pos);
    }
    
    /**
     * Inserts an element at a specified position
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function insert(pos: Int, x: T): Void {
        #if elixir_warn_mutability
        @:compilerWarning("Array.insert() creates a new list in Elixir, not in-place insertion")
        #end
        untyped __elixir__('List.insert_at({0}, {1}, {2})', this, pos, x);
    }
    
    /**
     * Removes the first occurrence of x
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function remove(x: T): Bool {
        var result = untyped __elixir__('List.delete({0}, {1})', this, x);
        // Using __elixir__ for != comparison
        return untyped __elixir__("{0} != {1}", result, this);
    }
    
    /**
     * Creates an iterator for the array
     * 
     * Required by @:coreApi to return haxe.iterators.ArrayIterator<T>.
     * The ArrayIterator class exists only for type compatibility.
     * The Reflaxe.Elixir compiler transforms for-in loops directly
     * to Elixir's Enum operations, never actually using this iterator.
     * 
     * Transformation example:
     * Haxe:   for (item in array) { ... }
     * Elixir: Enum.each(array, fn item -> ... end)
     */
    public inline function iterator(): haxe.iterators.ArrayIterator<T> {
        return new haxe.iterators.ArrayIterator(this);
    }
    
    /**
     * Creates a key-value iterator for the array
     * 
     * Required by @:coreApi to return haxe.iterators.ArrayKeyValueIterator<T>.
     * The ArrayKeyValueIterator class exists only for type compatibility.
     * The Reflaxe.Elixir compiler transforms key-value loops directly
     * to Elixir's Enum.with_index, never actually using this iterator.
     * 
     * Transformation example:
     * Haxe:   for (i => v in array) { ... }
     * Elixir: Enum.with_index(array) |> Enum.each(fn {v, i} -> ... end)
     */
    public inline function keyValueIterator(): haxe.iterators.ArrayKeyValueIterator<T> {
        return new haxe.iterators.ArrayKeyValueIterator(this);
    }
    
    /**
     * Resize the array to a specific length
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function resize(len: Int): Void {
        #if elixir_warn_mutability
        @:compilerWarning("Array.resize() creates a new list in Elixir, not in-place resizing")
        #end
        // Note: Assignment must be handled by compiler
        untyped __elixir__('Enum.take({0}, {1})', this, len);
    }
}
