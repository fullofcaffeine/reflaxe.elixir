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
