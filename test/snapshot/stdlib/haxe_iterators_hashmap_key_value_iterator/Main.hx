import haxe.ds.HashMap;
import haxe.iterators.HashMapKeyValueIterator;

class HashIteratorKey {
	final id:Int;
	final code:Int;

	public function new(id:Int, code:Int) {
		this.id = id;
		this.code = code;
	}

	public function hashCode():Int {
		return code;
	}

	public function toString():String {
		return 'key:$id';
	}
}

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition) {
			throw message;
		}
	}

	static function main():Void {
		var first = new HashIteratorKey(1, 10);
		var second = new HashIteratorKey(2, 20);
		var map = new HashMap<HashIteratorKey, String>();
		map.set(first, "one");
		map.set(second, "two");

		var iterator = new HashMapKeyValueIterator<HashIteratorKey, String>(map);
		var seen = new Array<String>();
		while (iterator.hasNext()) {
			var pair = iterator.next();
			seen.push(pair.key.toString() + "=" + pair.value);
		}
		seen.sort(Reflect.compare);

		assertThat(seen.join(",") == "key:1=one,key:2=two", "explicit HashMapKeyValueIterator should preserve key/value pairs");
	}
}
