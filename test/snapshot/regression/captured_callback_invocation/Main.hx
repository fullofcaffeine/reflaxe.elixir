/** Captured and inline comparison functions must both remain callable. */
class Main {
	static function order(a:Int, b:Int):Int {
		return a - b;
	}

	static function main():Void {
		var captured = [3, 1, 2];
		captured.sort(order);
		if (captured.join(",") != "1,2,3") {
			throw "captured comparator returned the wrong order";
		}

		var closure = [3, 1, 2];
		closure.sort(function(a:Int, b:Int):Int return b - a);
		if (closure.join(",") != "3,2,1") {
			throw "inline comparator returned the wrong order";
		}
	}
}
