/** Ordinary map APIs must retain their runtime without explicit helper imports. */
class MapRuntimeDependencyProbe {
	static function main() {
		var strings = new haxe.ds.StringMap<Int>();
		strings.set("one", 7);
		var values = strings.iterator();
		if (!values.hasNext() || values.next() != 7 || values.hasNext())
			throw "StringMap value iterator changed its cursor";
		var pairs = strings.keyValueIterator();
		if (!pairs.hasNext())
			throw "StringMap pair missing";
		var pair = pairs.next();
		if (pair.key != "one" || pair.value != 7 || pairs.hasNext())
			throw "StringMap pair iterator changed its entry";

		var integers = new haxe.ds.IntMap<String>();
		integers.set(4, "four");
		var integerValues = integers.iterator();
		if (!integerValues.hasNext() || integerValues.next() != "four" || integerValues.hasNext())
			throw "IntMap value iterator changed its cursor";
		var integerPairs = integers.keyValueIterator();
		if (!integerPairs.hasNext())
			throw "IntMap pair missing";
		var integerPair = integerPairs.next();
		if (integerPair.key != 4 || integerPair.value != "four" || integerPairs.hasNext())
			throw "IntMap pair iterator changed its entry";

		var empty = new Map<String, Int>();
		if (empty.iterator().hasNext() || empty.keyValueIterator().hasNext())
			throw "Empty map has entries";
		checkInterface(strings);
	}

	/** An interface-typed receiver must retain the same cursor contract. */
	static function checkInterface(map:haxe.Constraints.IMap<String, Int>):Void {
		var values = map.iterator();
		if (!values.hasNext() || values.next() != 7 || values.hasNext())
			throw "Interface value iterator changed its cursor";
	}
}
