/** Verifies exact array lengths, nested bindings, and guard priority on real targets. */
class Main {
	/** A later authored local must not reuse the generated read's target name. */
	static function bindingCollision(values:Array<Int>):Int {
		var g = values[0];
		var array_read_node_0 = values[1];
		return g * 100 + array_read_node_0;
	}

	static function cardinality(values:Array<Int>):Int {
		return switch values {
			case []: 0;
			case [_]: 1;
			case [_, _]: 2;
			default: 3;
		};
	}

	static function matrix(values:Array<Array<Int>>):Int {
		return switch values {
			case [[a, b], [c, d]]: a * 1000 + b * 100 + c * 10 + d;
			default: -1;
		};
	}

	static function guarded(values:Array<Int>):Int {
		return switch values {
			case [a, b] if (a > b): a - b;
			case [a, b]: b - a;
			case rest if (rest.length > 2): rest.length;
			default: -1;
		};
	}

	static function expect(actual:Int, expected:Int):Void {
		if (actual != expected)
			throw "Array pattern contract failed";
	}

	public static function main():Void {
		expect(bindingCollision([10, 20]), 1020);
		expect(cardinality([]), 0);
		expect(cardinality([8]), 1);
		expect(cardinality([8, 9]), 2);
		expect(cardinality([8, 9, 10]), 3);
		expect(matrix([[1, 2], [3, 4]]), 1234);
		expect(matrix([[4, 3], [2, 1]]), 4321);
		expect(matrix([[1], [3, 4]]), -1);
		expect(matrix([[1, 2], [3]]), -1);
		expect(matrix([]), -1);
		expect(guarded([8, 3]), 5);
		expect(guarded([3, 8]), 5);
		expect(guarded([8, 8]), 0);
		expect(guarded([1, 2, 3]), 3);
		expect(guarded([1]), -1);
	}
}
