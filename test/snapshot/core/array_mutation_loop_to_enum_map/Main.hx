class Main {
	public static function doubleInPlace(values:Array<Int>):Array<Int> {
		var i = 0;
		while (i < values.length) {
			values[i] = values[i] * 2;
			i++;
		}
		return values;
	}

	public static function addIndexInPlace(values:Array<Int>):Array<Int> {
		var i = 0;
		while (i < values.length) {
			values[i] = values[i] + i;
			i++;
		}
		return values;
	}

	public static function keepStatefulWhenCounterObserved(values:Array<Int>):Int {
		var i = 0;
		while (i < values.length) {
			values[i] = values[i] * 2;
			i++;
		}
		return i;
	}

	static function main():Void {
		doubleInPlace([1, 2, 3]);
		addIndexInPlace([1, 2, 3]);
		keepStatefulWhenCounterObserved([1, 2, 3]);
	}
}
