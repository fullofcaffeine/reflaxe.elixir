class Main {
	static function main() {
		var users:Map<String, Int> = ["a" => 0, "b" => 1, "c" => 2];

		var names:Array<String> = [];
		for (k in users.keys()) {
			// Nested conditionals to force branch-to-accumulator value propagation.
			if (k != "a") {
				var v = users.get(k);
				if (v != null && v > 0) {
					names = names.concat([k]);
				}
			}
		}

		var views:Array<{key:String, value:Int}> = [];
		for (k in users.keys()) {
			var v2 = users.get(k);
			if (v2 != null) {
				// `Array.push` lowers to a list-concat expression on Elixir and must be rebound through the accumulator.
				views.push({key: k, value: v2});
			}
		}

		// Consume results so they are not optimized away.
		trace(names.join(","));
		trace(views.length);
	}
}
