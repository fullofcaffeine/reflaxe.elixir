/** Runtime contracts for loop results, including updates inside conditional scopes. */
class Main {
	/** An outer range value used only by an output call remains a captured local. */
	public static function interpolationOnlyRange():Void {
		for (outer in 0...3) {
			for (inner in 0...3) {
				if (inner == 1)
					break;
				Sys.println('capture:$outer:$inner');
			}
		}
	}

	/** No outer local changes: inner break must still stop only its own range loop. */
	public static function statelessRangeControl():Void {
		for (outer in 0...3) {
			for (inner in 0...3) {
				if (outer + inner > 2)
					break;
				Sys.println('range:$outer:$inner');
			}
		}
	}

	/** A side-effect-only array loop must honor continue and break without an accumulator. */
	public static function statelessArrayControl():Void {
		for (value in [0, 1, 2, 3, 4]) {
			if (value == 1)
				continue;
			if (value == 3)
				break;
			Sys.println('array:$value');
		}
	}

	/** Returns belong to the Haxe function, including inside a stateful while callback. */
	static function whileFind(limit:Int, target:Int):Int {
		var index = 0;
		while (index < limit) {
			if (index == target)
				return index + 10;
			index++;
		}
		return -1;
	}

	static function whileSearch(values:Array<Int>, target:Int):Bool {
		var left = 0;
		var right = values.length - 1;
		while (left <= right) {
			final middle = Std.int((left + right) / 2);
			if (values[middle] == target)
				return true;
			else if (values[middle] < target)
				left = middle + 1;
			else
				right = middle - 1;
		}
		return false;
	}

	static function whileControl(limit:Int, target:Int):Int {
		var index = 0;
		while (index < limit) {
			index++;
			if (index == 1)
				continue;
			if (index == 4)
				break;
			if (index == target)
				return index * 10;
		}
		return index;
	}

	static function statelessWhile(enabled:Bool):Int {
		while (enabled)
			return 7;
		return 3;
	}

	static function localClosureReturn():Int {
		var index = 0;
		var total = 0;
		while (index < 2) {
			final read = function():Int {
				return 9;
			};
			total += read();
			index++;
		}
		return total;
	}

	static function guardedPartition(values:Null<Array<Int>>):{left:Array<Int>, right:Array<Int>} {
		final left:Array<Int> = [];
		final right:Array<Int> = [];

		if (values != null)
			for (value in values) {
				if (value < 2)
					left.push(value);
				else
					right.push(value);
			}

		return {left: left, right: right};
	}

	/** Reserved local names and nested guards must preserve the same loop results. */
	static function nestedPartition(values:Null<Array<Int>>, enabled:Bool):{left:Array<Int>, right:Array<Int>} {
		final before:Array<Int> = [];
		final after:Array<Int> = [];

		if (enabled) {
			if (values != null)
				for (value in values) {
					if (value < 2)
						before.push(value);
					else
						after.push(value);
				}
		}

		return {left: before, right: after};
	}

	static function assertPartition(label:String, expectedLeft:Array<Int>, expectedRight:Array<Int>, actual:{left:Array<Int>, right:Array<Int>}):Void {
		assertInts('$label left', expectedLeft, actual.left);
		assertInts('$label right', expectedRight, actual.right);
	}

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
		interpolationOnlyRange();
		statelessRangeControl();
		statelessArrayControl();
		assertInts("while returns", [10, 12, -1, -1], [whileFind(3, 0), whileFind(3, 2), whileFind(3, 8), whileFind(0, 0)]);
		if (!whileSearch([1, 3, 5, 7, 9], 5) || whileSearch([1, 3, 5, 7, 9], 4) || whileSearch([], 1))
			throw "while binary search return or termination";
		assertInts("while control and return", [30, 4, 4, 0], [whileControl(6, 3), whileControl(6, 1), whileControl(6, 4), whileControl(0, 3)]);
		assertInts("stateless while", [7, 3], [statelessWhile(true), statelessWhile(false)]);
		if (localClosureReturn() != 18)
			throw "nested function return escaped its function";
		LoopSwitchProbe.main();
		assertPartition("null guard", [], [], guardedPartition(null));
		assertPartition("empty guard", [], [], guardedPartition([]));
		assertPartition("guarded loop", [1, 0], [2, 3], guardedPartition([1, 2, 0, 3]));
		assertPartition("nested disabled", [], [], nestedPartition([1, 2, 3], false));
		assertPartition("nested null", [], [], nestedPartition(null, true));
		assertPartition("nested loop", [1, 0], [2, 3], nestedPartition([1, 2, 0, 3], true));

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
