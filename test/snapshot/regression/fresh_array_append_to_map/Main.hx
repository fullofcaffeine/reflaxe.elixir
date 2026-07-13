class ProjectionBox {
	var offset:Int;

	public function new(offset:Int) {
		this.offset = offset;
	}

	public function project(value:Int):Int {
		offset++;
		return value + offset;
	}
}

class Main {
	static function twice(value:Int):Int {
		return value * 2;
	}

	public static function directProjection(values:Array<Int>):Array<Int> {
		var output = [];
		for (value in values) {
			output.push(value * 2);
		}
		return output;
	}

	public static function staticProjection(values:Array<Int>):Array<Int> {
		var output = [];
		for (value in values) {
			output.push(twice(value));
		}
		return output;
	}

	public static function conditionalAppend(values:Array<Int>):Array<Int> {
		var output = [];
		for (value in values) {
			if (value > 0) {
				output.push(value);
			}
		}
		return output;
	}

	public static function multipleAppend(values:Array<Int>):Array<Int> {
		var output = [];
		for (value in values) {
			output.push(value);
			output.push(value * 2);
		}
		return output;
	}

	public static function partialAccumulatorRead(values:Array<Int>):Array<Int> {
		var output = [];
		for (value in values) {
			output.push(output.length + value);
		}
		return output;
	}

	public static function breakFallback(values:Array<Int>):Array<Int> {
		var output = [];
		for (value in values) {
			if (value < 0) {
				break;
			}
			output.push(value);
		}
		return output;
	}

	public static function continueFallback(values:Array<Int>):Array<Int> {
		var output = [];
		for (value in values) {
			if (value < 0) {
				continue;
			}
			output.push(value);
		}
		return output;
	}

	public static function returnFallback(values:Array<Int>):Array<Int> {
		var output = [];
		for (value in values) {
			if (value < 0) {
				return output;
			}
			output.push(value);
		}
		return output;
	}

	public static function throwFallback(values:Array<Int>):Array<Int> {
		var output = [];
		for (value in values) {
			if (value < 0) {
				throw "negative value";
			}
			output.push(value);
		}
		return output;
	}

	public static function statefulReceiverFallback(values:Array<Int>):Array<Int> {
		var box = new ProjectionBox(1);
		var output = [];
		for (value in values) {
			output.push(box.project(value));
		}
		return output;
	}

	public static function persistentIteratorFallback(limit:Int):Array<Int> {
		var iterator = new IntIterator(0, limit);
		var output = [];
		for (value in iterator) {
			output.push(value * 2);
		}
		return output;
	}

	public static function selfIteratorFallback():Array<Int> {
		var output = [];
		for (value in output) {
			output.push(value);
		}
		return output;
	}

	public static function nonFreshAccumulator(values:Array<Int>, prefix:Array<Int>):Array<Int> {
		var output = prefix.copy();
		for (value in values) {
			output.push(value);
		}
		return output;
	}

	static function main():Void {
		directProjection([1, 2, 3]);
		staticProjection([1, 2, 3]);
		conditionalAppend([-1, 1]);
		multipleAppend([1, 2]);
		partialAccumulatorRead([1, 2]);
		breakFallback([1, -1, 2]);
		continueFallback([1, -1, 2]);
		returnFallback([1, -1, 2]);
		throwFallback([1, 2]);
		statefulReceiverFallback([1, 2]);
		persistentIteratorFallback(3);
		selfIteratorFallback();
		nonFreshAccumulator([1, 2], [0]);
	}
}
