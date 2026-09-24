/** Native callers can provide maps without a concrete Haxe map constructor. */
class MapInterfaceExportProbe {
	@:keep
	public static function values(map:haxe.Constraints.IMap<String, Int>):Iterator<Int> {
		return map.iterator();
	}

	@:keep
	public static function pairs(map:haxe.Constraints.IMap<String, Int>):KeyValueIterator<String, Int> {
		return map.keyValueIterator();
	}

	static function main():Void {}
}
