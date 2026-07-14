class Main {
	static function breakBeforeAppend(values:Array<Int>):Array<Int> {
		var output = [];
		for (value in values) {
			if (value < 0) {
				break;
			}
			output.push(value);
		}
		return output;
	}

	static function continueBeforeAppend(values:Array<Int>):Array<Int> {
		var output = [];
		for (value in values) {
			if (value < 0) {
				continue;
			}
			output.push(value);
		}
		return output;
	}

	static function carriedArrayState(values:Array<Int>):Array<Int> {
		var output = [];
		var visited = 0;
		for (value in values) {
			visited++;
			output.push(value);
			if (value == 2) {
				continue;
			}
			if (value == 3) {
				break;
			}
			output.push(value * 10);
		}
		output.push(visited);
		return output;
	}

	static function rangeControl(limit:Int):Array<Int> {
		var output = [];
		for (value in 0...limit) {
			if (value == 1) {
				continue;
			}
			output.push(value);
			if (value == 3) {
				break;
			}
		}
		return output;
	}

	static function controlAndReturn(values:Array<Int>):Array<Int> {
		var output = [];
		for (value in values) {
			if (value == -1) {
				continue;
			}
			if (value == -2) {
				break;
			}
			if (value == -3) {
				return output;
			}
			output.push(value);
		}
		return output;
	}

	static function conditionalMultiAccumulator(items:Array<String>):Array<String> {
		var results = [];
		var errors = [];
		for (item in items) {
			if (item == "error") {
				errors.push('Failed:$item');
				continue;
			}
			results.push('Processed:$item');
		}
		return errors.concat(results);
	}

	static function assertInts(label:String, expected:Array<Int>, actual:Array<Int>):Void {
		if (expected.length != actual.length) {
			throw '$label length: expected ${expected.length}, got ${actual.length}';
		}
		for (index in 0...expected.length) {
			if (expected[index] != actual[index]) {
				throw '$label index $index: expected ${expected[index]}, got ${actual[index]}';
			}
		}
	}

	static function assertStrings(label:String, expected:Array<String>, actual:Array<String>):Void {
		if (expected.length != actual.length) {
			throw '$label length: expected ${expected.length}, got ${actual.length}';
		}
		for (index in 0...expected.length) {
			if (expected[index] != actual[index]) {
				throw '$label index $index: expected ${expected[index]}, got ${actual[index]}';
			}
		}
	}

	public static function main():Void {
		assertInts("break", [1], breakBeforeAppend([1, -1, 2]));
		assertInts("continue", [1, 2], continueBeforeAppend([1, -1, 2]));
		assertInts("carried state", [1, 10, 2, 3, 3], carriedArrayState([1, 2, 3, 4]));
		assertInts("range control", [0, 2, 3], rangeControl(6));
		assertInts("combined continue/break", [1, 2], controlAndReturn([1, -1, 2, -2, 3]));
		assertInts("combined return", [1, 2], controlAndReturn([1, 2, -3, 4]));
		assertStrings("conditional multi accumulator", ["Failed:error", "Processed:valid1", "Processed:valid2"],
			conditionalMultiAccumulator(["valid1", "error", "valid2"]));
	}
}
