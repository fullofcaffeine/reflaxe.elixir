/**
 * Array implementation for Reflaxe.Elixir
 * 
 * WHY: Provide idiomatic Elixir code generation for array operations
 * WHAT: Maps Haxe array methods to Elixir Enum module functions
 * HOW: Uses @:native metadata and __elixir__ injection for direct Elixir generation
 * 
 * This implementation ensures that common array operations like map, filter, etc.
 * generate clean Enum.map, Enum.filter calls instead of complex while loops.
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
     */
    public function push(x: T): Int {
        untyped __elixir__("[{0} | {1}]", this, x);
        return length;
    }
    
    /**
     * Removes and returns the last element
     */
    public function pop(): Null<T> {
        return untyped __elixir__("List.last({0})", this);
    }
    
    /**
     * Creates a new array by applying function f to all elements
     */
    public function map<S>(f: T -> S): Array<S> {
        return untyped __elixir__("Enum.map({0}, {1})", this, f);
    }
    
    /**
     * Returns a new array containing only elements for which f returns true
     */
    public function filter(f: T -> Bool): Array<T> {
        return untyped __elixir__("Enum.filter({0}, {1})", this, f);
    }
    
    /**
     * Concatenates two arrays
     */
    public function concat(a: Array<T>): Array<T> {
        return untyped __elixir__("{0} ++ {1}", this, a);
    }
    
    /**
     * Returns a string representation of the array
     */
    public function toString(): String {
        return untyped __elixir__("inspect({0})", this);
    }
    
    /**
     * Returns a copy of the array
     */
    public function copy(): Array<T> {
        return untyped __elixir__("{0}", this);
    }
    
    /**
     * Reverses the array in place
     * Note: In Elixir, lists are immutable so this creates a new list
     */
    public function reverse(): Void {
        // In Elixir we can't mutate, so we just generate the reversed list
        // The compiler will need to handle assignment if needed
        untyped __elixir__("Enum.reverse({0})", this);
    }
    
    /**
     * Sorts the array in place
     * Note: In Elixir, lists are immutable so this creates a new list
     */
    public function sort(f: T -> T -> Int): Void {
        // In Elixir we can't mutate, so we just generate the sorted list
        // The compiler will need to handle assignment if needed
        untyped __elixir__("Enum.sort({0}, {1})", this, f);
    }
    
    /**
     * Checks if the array contains an element
     */
    public function contains(x: T): Bool {
        return untyped __elixir__("Enum.member?({0}, {1})", this, x);
    }
    
    /**
     * Returns the index of the first occurrence of x
     */
    public function indexOf(x: T, ?fromIndex: Int = 0): Int {
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
     */
    public function shift(): Null<T> {
        return untyped __elixir__("List.first({0})", this);
    }
    
    /**
     * Adds an element to the beginning of the array
     */
    public function unshift(x: T): Void {
        untyped __elixir__("[{1} | {0}]", this, x);
    }
    
    /**
     * Joins array elements into a string
     */
    public function join(sep: String): String {
        return untyped __elixir__("Enum.join({0}, {1})", this, sep);
    }
    
    /**
     * Returns a slice of the array
     */
    public function slice(pos: Int, ?end: Int): Array<T> {
        if (end == null) {
            return untyped __elixir__("Enum.slice({0}, {1}..-1)", this, pos);
        } else {
            return untyped __elixir__("Enum.slice({0}, {1}..{2})", this, pos, end);
        }
    }
    
    /**
     * Removes and returns an element at the specified position
     */
    public function splice(pos: Int, len: Int): Array<T> {
        return untyped __elixir__("List.delete_at({0}, {1})", this, pos);
    }
    
    /**
     * Inserts an element at a specified position
     */
    public function insert(pos: Int, x: T): Void {
        untyped __elixir__("List.insert_at({0}, {1}, {2})", this, pos, x);
    }
    
    /**
     * Removes the first occurrence of x
     */
    public function remove(x: T): Bool {
        var result = untyped __elixir__("List.delete({0}, {1})", this, x);
        return untyped __elixir__("{0} != {1}", result, this);
    }
    
    /**
     * Creates an iterator for the array
     */
    public function iterator(): haxe.iterators.ArrayIterator<T> {
        return new haxe.iterators.ArrayIterator(this);
    }
    
    /**
     * Creates a key-value iterator for the array
     */
    public function keyValueIterator(): haxe.iterators.ArrayKeyValueIterator<T> {
        return new haxe.iterators.ArrayKeyValueIterator(this);
    }
    
    /**
     * Resize the array to a specific length
     */
    public function resize(len: Int): Void {
        // In Elixir, lists are immutable so we can't truly resize
        // This is a compatibility method that doesn't actually mutate
        untyped __elixir__("Enum.take({0}, {1})", this, len);
    }
}
