package haxe.iterators;

/**
 * Iterator over values of `haxe.DynamicAccess`.
 */
class DynamicAccessIterator<T> {
	final access:DynamicAccess<T>;
	final keys:Array<String>;
	var index:Int;

	public inline function new(access:DynamicAccess<T>) {
		this.access = access;
		this.keys = access.keys();
		index = 0;
	}

	public inline function hasNext():Bool {
		return index < keys.length;
	}

	public inline function next():T {
		return access[keys[index++]];
	}
}
