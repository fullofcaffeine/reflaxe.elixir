/** Map lookup alone must not require the iterator runtime. */
class MapLookupDependencyProbe {
	static function main() {
		var strings = new haxe.ds.StringMap<Int>();
		strings.set("one", 7);
		var integers = new haxe.ds.IntMap<String>();
		integers.set(4, "four");
		if (strings.get("one") != 7 || integers.get(4) != "four")
			throw "Map lookup changed";
	}
}
