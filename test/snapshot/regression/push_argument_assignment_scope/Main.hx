class Main {
	public static function probe():Int {
		var values = [1];
		var alias = values;

		values.push({
			alias = [];
			alias.length;
		});

		return alias.length;
	}

	static function consume(value:Int):Int {
		return value;
	}

	static function combine(first:Int, second:Int):Int {
		return first * 10 + second;
	}

	static function pair(first:Int, second:Int):Array<Int> {
		return [first, second];
	}

	static function assertText(expected:String, actual:String):Void {
		if (expected != actual)
			throw 'Expected [$expected], received [$actual]';
	}

	/** Printed line breaks must not introduce a function scope around an argument. */
	public static function multilineSliceArgumentProbe():Int {
		var values = [1, 2, 3, 4];
		var start = 1;
		assertText("2,3", values.slice(start, start = 3).join(","));
		return start;
	}

	public static function joinAssignmentValueProbe():Int {
		var first = 1;
		if (pair(first, first = 3).join(",") != "1,3") {
			throw 'Expected join to preserve the values passed to its array-producing call';
		}
		return first;
	}

	public static function assignmentValueProbe():Int {
		var first = 1;
		var result = combine(first, first = 3);
		return result * 10 + first;
	}

	public static function nestedAssignmentValueProbe():Int {
		var first = 1;
		if (consume(combine(first, first = 3)) != 13) {
			throw 'Expected nested calls to capture earlier arguments before assignment';
		}
		return first;
	}

	public static function ordinaryCallProbe():Int {
		var alias = [1];

		consume({
			alias = [];
			alias.length;
		});

		return alias.length;
	}

	public static function blockLocalProbe():Int {
		return consume({
			var local = 4;
			local + 1;
		});
	}

	public static function argumentOrderProbe():Int {
		var first = [1];
		var second = [1];
		return combine({
			first = [];
			second.length;
		}, {
			second = [];
			first.length;
		});
	}

	public static function main():Void {
		if (multilineSliceArgumentProbe() != 3) {
			throw 'Expected multiline slice arguments to preserve caller writes';
		}
		if (joinAssignmentValueProbe() != 3) {
			throw 'Expected join to preserve caller writes inside its argument';
		}
		if (nestedAssignmentValueProbe() != 3) {
			throw 'Expected nested call arguments to retain caller writes';
		}
		if (assignmentValueProbe() != 133) {
			throw 'Expected an assignment argument to preserve its value and caller write';
		}
		if (probe() != 0) {
			throw 'Expected the call-argument assignment to remain visible after the call';
		}
		if (ordinaryCallProbe() != 0) {
			throw 'Expected ordinary call arguments to use the same assignment scope rule';
		}
		if (blockLocalProbe() != 5) {
			throw 'Expected a call-argument declaration to remain local to its block';
		}
		if (argumentOrderProbe() != 10) {
			throw 'Expected call arguments to retain their left-to-right value order';
		}
	}
}
