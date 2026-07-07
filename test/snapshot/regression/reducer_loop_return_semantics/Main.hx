class Main {
	static function main() {
		var ok = sumUntilNegative([1, 2, 3]);
		var stopped = sumUntilNegative([1, -2, 3]);
		trace(ok);
		trace(stopped);
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
