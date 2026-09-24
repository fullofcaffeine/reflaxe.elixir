/** Concrete custom maps keep their own methods, not the native-map helper. */
class CustomMapDependencyProbe {
	static function main() {
		var map = new FixedMap();
		var values = map.iterator();
		if (!values.hasNext() || values.next() != 13 || values.hasNext())
			throw "Custom value iterator was replaced";
		var pairs = map.keyValueIterator();
		if (!pairs.hasNext())
			throw "Custom pair missing";
		var pair = pairs.next();
		if (pair.key != "custom" || pair.value != 13 || pairs.hasNext())
			throw "Custom pair iterator was replaced";
	}
}

/** A fixed read-only map isolates dispatch from mutable collection behavior. */
class FixedMap implements haxe.Constraints.IMap<String, Int> {
	public function new() {}

	public function get(key:String):Null<Int>
		return key == "custom" ? 13 : null;

	public function exists(key:String):Bool
		return key == "custom";

	public function keys():Iterator<String>
		return ["custom"].iterator();

	public function iterator():Iterator<Int>
		return [13].iterator();

	public function keyValueIterator():KeyValueIterator<String, Int>
		return [{key: "custom", value: 13}].iterator();

	public function copy():haxe.Constraints.IMap<String, Int>
		return new FixedMap();

	public function toString():String
		return "custom=13";

	public function set(key:String, value:Int):Void
		throw "Read-only fixture";

	public function remove(key:String):Bool
		throw "Read-only fixture";

	public function clear():Void
		throw "Read-only fixture";
}
