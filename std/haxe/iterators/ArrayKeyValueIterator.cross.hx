package haxe.iterators;

/**
 * Elixir target override: no codegen, runtime provided.
 */
extern class ArrayKeyValueIterator<T> {
    public function new(array: Array<T>);
    public function hasNext(): Bool;
    public function next(): {key: Int, value: T};
}

