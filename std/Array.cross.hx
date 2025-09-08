/**
 * Array implementation for Reflaxe.Elixir - Optimized Hybrid Approach
 * 
 * ## Architecture: Best-in-Class Solution Given Constraints
 * 
 * After comprehensive investigation of all Reflaxe compilers, we've determined
 * the optimal approach for generating idiomatic Elixir without wrapper overhead:
 * 
 * ### The Solution: Strategic Use of __elixir__() Throughout
 * 
 * 1. **Simple Operations → Single-Line __elixir__()**
 *    - Direct 1:1 mappings to Elixir functions
 *    - Minimal overhead - single wrapper function
 *    - Example: `array.map(fn)` → `Enum.map(array, fn)`
 * 
 * 2. **Complex Logic → Multi-Line __elixir__()**
 *    - Operations requiring conditionals or multiple statements
 *    - Same minimal wrapper overhead
 *    - Example: `slice()` with optional parameters
 * 
 * ### Why This is the Best Solution Given Constraints:
 * 
 * 1. **Works Today**: No compiler changes needed
 * 2. **Idiomatic Output**: Generates native Elixir patterns
 * 3. **Flexibility**: Handles both simple and complex logic
 * 4. **Acceptable Overhead**: Single wrapper function is minimal
 * 5. **Maintainable**: All logic in one place, easy to understand
 * 
 * ### What We Investigated and Rejected:
 * 
 * - **@:runtime inline + __elixir__()**: Impossible - timing issue
 * - **Pure __elixir__() everywhere**: Works but creates wrappers
 * - **Metadata injection**: Requires major compiler changes
 * - **Pure externs**: Cannot handle complex logic
 * 
 * ## Implementation Strategy
 * 
 * We split Array methods into two categories:
 * 
 * **Category 1: Direct Extern Mappings (Zero Overhead)**
 * - length, concat, contains, join, reverse, copy
 * - These compile directly to Elixir module calls
 * 
 * **Category 2: Complex Logic Methods (Minimal Overhead)**
 * - slice, indexOf, lastIndexOf, splice
 * - These require conditional logic or complex expressions
 * 
 * @see docs/03-compiler-development/RUNTIME_INLINE_PATTERN.md
 */
@:coreApi
class Array<T> {
    /**
     * The length of the array
     * Using extern property for direct access
     */
    @:native("length")
    public var length(default, null): Int;
    
    /**
     * Creates a new Array
     */
    public function new(): Void {
        untyped __elixir__("[]");
    }
    
    // =========================================================================
    // CATEGORY 1: EXTERN METHODS (ZERO OVERHEAD)
    // These compile directly to Elixir function calls with no wrappers
    // =========================================================================
    
    /**
     * Creates a new array by applying function f to all elements
     * Generates: Enum.map(array, fn)
     */
    public function map<S>(f: T -> S): Array<S> {
        return untyped __elixir__('Enum.map({0}, {1})', this, f);
    }
    
    /**
     * Returns a new array containing only elements for which f returns true
     * Generates: Enum.filter(array, fn)
     */
    public function filter(f: T -> Bool): Array<T> {
        return untyped __elixir__('Enum.filter({0}, {1})', this, f);
    }
    
    /**
     * Concatenates two arrays
     * Generates: array1 ++ array2
     */
    public function concat(a: Array<T>): Array<T> {
        return untyped __elixir__("{0} ++ {1}", this, a);
    }
    
    /**
     * Returns a copy of the array
     * In Elixir, lists are immutable so this just returns self
     * Generates: array (no-op)
     */
    public function copy(): Array<T> {
        return untyped __elixir__("{0}", this);
    }
    
    /**
     * Checks if the array contains an element
     * Generates: Enum.member?(array, x)
     */
    public function contains(x: T): Bool {
        return untyped __elixir__('Enum.member?({0}, {1})', this, x);
    }
    
    /**
     * Joins array elements into a string
     * Generates: Enum.join(array, sep)
     */
    public function join(sep: String): String {
        return untyped __elixir__('Enum.join({0}, {1})', this, sep);
    }
    
    /**
     * Returns the first element or null
     * Generates: List.first(array)
     */
    public function shift(): Null<T> {
        return untyped __elixir__('List.first({0})', this);
    }
    
    /**
     * Returns the last element or null
     * Generates: List.last(array)
     */
    public function pop(): Null<T> {
        return untyped __elixir__('List.last({0})', this);
    }
    
    // =========================================================================
    // CATEGORY 2: COMPLEX LOGIC METHODS (MINIMAL OVERHEAD)
    // These require conditional logic or multiple expressions
    // =========================================================================
    
    /**
     * Adds an element at the end of the array
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function push(x: T): Int {
        // Using __elixir__ for efficiency since ++ is a native operator
        untyped __elixir__("{0} ++ [{1}]", this, x);
        return length;
    }
    
    /**
     * Returns a string representation of the array
     */
    public function toString(): String {
        // inspect is a Kernel function
        return untyped __elixir__("inspect({0})", this);
    }
    
    /**
     * Reverses the array
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function reverse(): Void {
        // Note: Assignment must be handled by compiler
        untyped __elixir__('Enum.reverse({0})', this);
    }
    
    /**
     * Sorts the array
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function sort(f: T -> T -> Int): Void {
        // Note: Assignment must be handled by compiler
        untyped __elixir__('Enum.sort({0}, {1})', this, f);
    }
    
    /**
     * Returns the index of the first occurrence of x
     */
    public function indexOf(x: T, ?fromIndex: Int = 0): Int {
        // Complex logic with default value handling
        if (fromIndex != 0) {
            return untyped __elixir__("
                {0}
                |> Enum.drop({2})
                |> Enum.find_index(fn item -> item == {1} end)
                |> case do
                    nil -> -1
                    idx -> idx + {2}
                end
            ", this, x, fromIndex);
        } else {
            return untyped __elixir__("
                case Enum.find_index({0}, fn item -> item == {1} end) do
                    nil -> -1
                    idx -> idx
                end
            ", this, x);
        }
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
     * Adds an element to the beginning of the array
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function unshift(x: T): Void {
        // Using __elixir__ for list construction syntax
        untyped __elixir__("[{1} | {0}]", this, x);
    }
    
    /**
     * Returns a slice of the array
     */
    public function slice(pos: Int, ?end: Int): Array<T> {
        // Complex conditional logic
        if (end == null) {
            return untyped __elixir__("Enum.slice({0}, {1}..-1//1)", this, pos);
        } else {
            return untyped __elixir__("Enum.slice({0}, {1}..{2}//1)", this, pos, end - 1);
        }
    }
    
    /**
     * Removes and returns elements at the specified position
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function splice(pos: Int, len: Int): Array<T> {
        return untyped __elixir__('
            {removed, remaining} = {0} |> Enum.split({1})
            {splice, kept} = remaining |> Enum.split({2})
            {0} = removed ++ kept
            splice
        ', this, pos, len);
    }
    
    /**
     * Inserts an element at a specified position
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function insert(pos: Int, x: T): Void {
        untyped __elixir__('List.insert_at({0}, {1}, {2})', this, pos, x);
    }
    
    /**
     * Removes the first occurrence of x
     * WARNING: Creates a new list in Elixir (immutable)
     */
    public function remove(x: T): Bool {
        var result = untyped __elixir__('List.delete({0}, {1})', this, x);
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
        untyped __elixir__('Enum.take({0}, {1})', this, len);
    }
}