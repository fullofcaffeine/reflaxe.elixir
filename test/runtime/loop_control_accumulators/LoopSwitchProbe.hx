private enum Lookup {
	Present(value:String);
	Missing;
}

/** A switch already carrying loop state must keep its complete result. */
class LoopSwitchProbe {
	static function lookup(key:String):Lookup {
		return key == "skip" ? Missing : Present('Value: $key');
	}

	static function collect(input:Map<String, Int>):Map<String, String> {
		var result = new Map<String, String>();
		for (key in input.keys()) {
			switch (lookup(key)) {
				case Present(value):
					result.set(key, value);
				case Missing:
			}
		}
		return result;
	}

	public static function main():Void {
		final mixed = collect(["keep" => 1, "skip" => 2, "other" => 3]);
		if (mixed.get("keep") != "Value: keep" || mixed.get("other") != "Value: other" || mixed.exists("skip"))
			throw "A loop switch lost its carried map or retained a skipped entry.";
		if (collect(["skip" => 1]).exists("skip") || collect([]).exists("keep"))
			throw "An empty or missing-only loop changed its initial map.";
	}
}
