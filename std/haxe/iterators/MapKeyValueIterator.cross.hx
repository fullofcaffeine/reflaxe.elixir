package haxe.iterators;

import haxe.Constraints.IMap;

/**
 * Elixir target override: no codegen, runtime provided.
 */
extern class MapKeyValueIterator<K, V> {
    public function new(map: IMap<K, V>);
    public function hasNext(): Bool;
    public function next(): {key: K, value: V};
}

