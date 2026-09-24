/** Interface-only calls must retain the native map iterator implementation. */
class MapInterfaceDependencyProbe {
	static function main() {
		var map:haxe.Constraints.IMap<String, Int> = new haxe.ds.StringMap<Int>();
		map.set("entry", 13);
		var values = map.iterator();
		if (!values.hasNext() || values.next() != 13 || values.hasNext())
			throw "Interface value cursor changed";
		var pairs = map.keyValueIterator();
		if (!pairs.hasNext())
			throw "Interface pair missing";
		var pair = pairs.next();
		if (pair.key != "entry" || pair.value != 13 || pairs.hasNext())
			throw "Interface pair cursor changed";
	}
}
