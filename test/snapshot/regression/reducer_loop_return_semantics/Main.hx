enum InputKey {
	Text(value:String);
	Other(reason:String);
}

class Main {
	static function main() {
		var ok = sumUntilNegative([1, 2, 3]);
		var stopped = sumUntilNegative([1, -2, 3]);
		if (ok != 6 || stopped != -1)
			throw "An array-loop return changed its result.";
		if (returnFromCatch() != 7)
			throw "A catch return did not exit its enclosing function.";
		if (tryAndCatch(3, 1, 2) != 20 || tryAndCatch(3, 2, 2) != 200 || tryAndCatch(3, 1, 9) != -3 || tryAndCatch(0, 1, 2) != 0)
			throw "Try/catch return or fallthrough lost its loop state.";
		if (!exactFields([], [], []) || !exactFields(["id", "label"], ["id"], ["label"]))
			throw "Valid fields were rejected.";
		if (exactFields([], ["id"], [])
			|| exactFields(["unknown", "id"], ["id"], [])
			|| exactFields(["id", "unknown", "label"], ["id"], ["label"])
			|| exactFields(["id", "unknown"], ["id"], []))
			throw "A sequential validation loop lost its rejection return.";
		if (stringKeys([Other("bad"), Text("id")]) != null
			|| stringKeys([Text("id"), Other("bad"), Text("label")]) != null
			|| stringKeys([Text("id"), Other("bad")]) != null)
			throw "An ignored enum payload lost its rejection return.";
		final empty = stringKeys([]);
		final valid = stringKeys([Text("id"), Text("label")]);
		if (empty == null || empty.length != 0 || valid == null || valid.join(",") != "id,label")
			throw "Enum fallthrough lost its accumulated values.";
		if (threeLoops([1], [2], [3]) != 36 || threeLoops([], [], []) != 30 || threeLoops([-1], [2], [3]) != -100 || threeLoops([1], [-2], [3]) != -211
			|| threeLoops([1], [2], [-3]) != -333)
			throw "Sequential returns lost intervening effects or accumulator state.";
	}

	/** Each validation loop may exit the function; later statements must not override it. */
	public static function exactFields(keys:Array<String>, required:Array<String>, optional:Array<String>):Bool {
		for (name in required)
			if (keys.indexOf(name) < 0)
				return false;
		for (name in keys)
			if (required.indexOf(name) < 0 && optional.indexOf(name) < 0)
				return false;
		return true;
	}

	/** Removing the unused payload binding must preserve the explicit null return. */
	public static function stringKeys(keys:Array<InputKey>):Null<Array<String>> {
		final names:Array<String> = [];
		for (key in keys)
			switch key {
				case Text(name):
					names.push(name);
				case Other(_):
					return null;
			}
		return names;
	}

	/** Distinct return values make execution order and continuation state observable. */
	public static function threeLoops(first:Array<Int>, second:Array<Int>, third:Array<Int>):Int {
		var total = 0;
		for (value in first) {
			if (value < 0)
				return -100 - total;
			total += value;
		}
		total += 10;
		for (value in second) {
			if (value < 0)
				return -200 - total;
			total += value;
		}
		total += 20;
		for (value in third) {
			if (value < 0)
				return -300 - total;
			total += value;
		}
		return total;
	}

	/** The finite bound makes a lost catch return fail without an infinite loop. */
	public static function returnFromCatch():Int {
		var attempt = 0;
		while (attempt < 2) {
			attempt++;
			try {
				throw "stop";
			} catch (_:String) {
				return 7;
			}
		}
		return -1;
	}

	/** Both normal and rescued paths may return early or continue with current state. */
	public static function tryAndCatch(limit:Int, failAt:Int, returnAt:Int):Int {
		var attempt = 0;
		while (attempt < limit) {
			attempt++;
			try {
				if (attempt == failAt)
					throw "stop";
				if (attempt == returnAt)
					return attempt * 10;
			} catch (_:String) {
				if (attempt == returnAt)
					return attempt * 100;
			}
		}
		return -attempt;
	}

	static function sumUntilNegative(values:Array<Int>):Int {
		var total = 0;
		for (value in values) {
			if (value < 0) {
				return -1;
			}
			total += value;
		}
		return total;
	}
}
