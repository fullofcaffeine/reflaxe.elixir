package haxe.iterators;

/**
 * Key/Value iterator over `haxe.DynamicAccess`.
 */
class DynamicAccessKeyValueIterator<T> {
    final access: DynamicAccess<T>;
    final keys: Array<String>;
    var index: Int;

    public inline function new(access: DynamicAccess<T>) {
        this.access = access;
        this.keys = access.keys();
        index = 0;
    }

    public inline function hasNext(): Bool {
        return index < keys.length;
    }

    public inline function next(): {key: String, value: T} {
        var key = keys[index++];
        return {value: (access[key] : T), key: key};
    }
}

