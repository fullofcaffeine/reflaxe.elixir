package haxe.iterators;

/**
 * Key/Value iterator over `haxe.DynamicAccess`.
 */
class DynamicAccessKeyValueIterator<T> {
	final access:DynamicAccess<T>;
	final keys:Array<String>;
	var index:Int;

	public inline function new(access:DynamicAccess<T>) {
		this.access = access;
		this.keys = access.keys();
		index = 0;
	}

	public inline function hasNext():Bool {
		return keys[index] != null;
	}

	public inline function next():{key:String, value:T} {
		var key = keys[index];
		index = index + 1;
		return {value: Reflect.field(access, key), key: key};
	}
}
