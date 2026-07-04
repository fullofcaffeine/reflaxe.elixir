package haxe.ds;

/**
 * List (Elixir target)
 *
 * WHAT
 * - BEAM-safe implementation of the canonical Haxe `haxe.ds.List` API.
 *
 * WHY
 * - The upstream linked-list implementation mutates node fields in place.
 *   Ordinary BEAM values are immutable, so nested node mutation cannot preserve
 *   Haxe's observable receiver state unless each mutating method returns an
 *   updated receiver for same-scope rebinding.
 *
 * HOW
 * - Store elements in insertion order in an immutable array/list snapshot.
 * - Register `add`, `push`, `pop`, `remove`, and `clear` in
 *   `ReceiverReturnConventions` so callers rebind the receiver after mutation.
 * - Derive iteration, string rendering, `filter`, and `map` from the ordered
 *   snapshot instead of exposing mutable linked nodes.
 *
 * EXAMPLES
 * ```haxe
 * var values = new haxe.ds.List<String>();
 * values.add("a");
 * values.push("z");
 * values.pop(); // "z"; values is rebound to contain "a"
 * ```
 */
@:native("Haxe.Ds.List")
class List<T> {
	var items:Array<T>;

	/**
	 * The number of elements in this list.
	 */
	public var length(default, null):Int;

	public function new() {
		items = [];
		length = 0;
	}

	public function add(item:T):Void {
		items = items.concat([item]);
		length = length + 1;
	}

	public function push(item:T):Void {
		items = [item].concat(items);
		length = length + 1;
	}

	public function first():Null<T> {
		return length == 0 ? null : items[0];
	}

	public function last():Null<T> {
		return length == 0 ? null : items[length - 1];
	}

	public function pop():Null<T> {
		var result:Null<T> = null;
		if (length > 0) {
			result = items[0];
			var updated = [];
			var index = 0;
			for (item in items) {
				if (index > 0) {
					updated = updated.concat([item]);
				}
				index = index + 1;
			}
			items = updated;
			length = length - 1;
		}
		return result;
	}

	public function isEmpty():Bool {
		return length == 0;
	}

	public function clear():Void {
		items = [];
		length = 0;
	}

	public function remove(v:T):Bool {
		var updated = [];
		var removed = false;
		for (item in items) {
			if (!removed && item == v) {
				removed = true;
			} else {
				updated = updated.concat([item]);
			}
		}
		if (removed) {
			items = updated;
			length = length - 1;
		}
		return removed;
	}

	public function iterator():haxe.iterators.ArrayIterator<T> {
		return cast Type.createInstance(haxe.iterators.ArrayIterator, [items]);
	}

	public function keyValueIterator():haxe.iterators.ArrayKeyValueIterator<T> {
		return cast Type.createInstance(haxe.iterators.ArrayKeyValueIterator, [items]);
	}

	public function toString():String {
		return "{" + items.join(", ") + "}";
	}

	public function join(sep:String):String {
		return items.join(sep);
	}

	public function filter(f:T->Bool):List<T> {
		var result = new List<T>();
		for (item in items) {
			if (f(item)) {
				result.add(item);
			}
		}
		return result;
	}

	public function map<X>(f:T->X):List<X> {
		var result = new List<X>();
		for (item in items) {
			result.add(f(item));
		}
		return result;
	}
}
