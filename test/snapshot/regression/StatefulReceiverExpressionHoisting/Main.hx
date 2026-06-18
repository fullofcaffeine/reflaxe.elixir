class Main {
	static function valueFrom(input:Int):Int {
		return input + 1;
	}

	static function requireTrue(value:Bool, label:String):Void {
		if (!value) {
			throw label;
		}
	}

	static function requireFalse(value:Bool, label:String):Void {
		if (value) {
			throw label;
		}
	}

	static function main() {
		var map = new haxe.DynamicAccess<Int>();
		var seed = 0;

		var bracketResult = (map["foo"] = valueFrom(seed)) == 1;
		map.set("bar", 2);
		var methodResult = map.set("baz", 3) == 3;

		var removedFirst = map.remove("bar");
		var removedSecond = map.remove("bar");

		requireTrue(bracketResult, "bracket result");
		requireTrue(methodResult, "method result");
		requireTrue(map.exists("foo"), "foo exists");
		requireFalse(map.exists("bar"), "bar removed");
		requireTrue(map.exists("baz"), "baz exists");
		requireTrue(removedFirst, "first remove");
		requireFalse(removedSecond, "second remove");
	}
}
