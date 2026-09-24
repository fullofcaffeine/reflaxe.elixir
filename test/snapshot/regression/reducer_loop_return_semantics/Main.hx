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
