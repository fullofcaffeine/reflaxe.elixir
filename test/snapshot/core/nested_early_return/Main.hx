enum Item {
	Value(text:String);
	Missing(reason:String);
}

class Main {
	/** A nested function exit must bypass the later mutable-state result. */
	public static function nested(value:Int, absent:Bool, denied:Bool):Int {
		var current = value + 1;
		if (absent) {
			if (denied)
				return -1;
		} else {
			if (denied)
				return -2;
			current = current + 2;
		}
		return current;
	}

	public static function statementCase(item:Item):Int {
		var count = 0;
		switch item {
			case Value(text):
				if (text == "")
					return -2;
				count = text.length;
			case Missing(_):
				return -1;
		}
		Sys.println("switch fallthrough");
		return count + 1;
	}

	public static function main():Void {
		if (statementCase(Missing("absent")) != -1)
			throw "Statement switch return continued.";
		if (statementCase(Value("")) != -2)
			throw "Nested switch return continued.";
		if (statementCase(Value("body")) != 5)
			throw "Statement switch fallthrough value changed.";
		if (nested(10, true, true) != -1)
			throw "Nested absent return lost.";
		if (nested(10, false, true) != -2)
			throw "Nested present return lost.";
		if (nested(10, true, false) != 11)
			throw "Absent continuation changed.";
		if (nested(10, false, false) != 13)
			throw "Present continuation changed.";
		if (classify(true, true) != "inner" || classify(true, false) != "outer" || classify(false, true) != "fallback")
			throw "Existing nested return changed.";
		if (elseOnly(false, true) != -1 || elseOnly(false, false) != 3 || elseOnly(true, true) != 2)
			throw "Else-only return changed.";
		if (closure(true) != 6 || closure(false) != 4)
			throw "Nested function return escaped its scope.";
		if (effects(true, true) != -1 || effects(false, true) != -2 || effects(true, false) != 11 || effects(false, false) != 13)
			throw "Effectful continuation changed.";
		if (rangeBytes([10, 0, 0, 1])
			|| rangeBytes([127, 0, -1, 1])
			|| rangeBytes([127, 0, 0, 256])
			|| rangeBytes([0, 0, 0, 0, 1, 0, 0, 1])
			|| rangeBytes([]))
			throw "Nested range return lost.";
		if (!rangeBytes([127, 0, 0, 1]) || !rangeBytes([0, 0, 0, 0, 0, 0, 0, 1]))
			throw "Valid range rejected.";
		if (collectionValid([-1, 1]) || collectionValid([1, -1, 2]) || collectionValid([1, 21]))
			throw "Nested collection return lost.";
		if (!collectionValid([]) || !collectionValid([0, 10, 20]))
			throw "Valid collection rejected.";
		if (!decodedItems([Value("ok")])
			|| !decodedItems([])
			|| decodedItems([Missing("bad")])
			|| decodedItems([Value("ok"), Missing("bad")])
			|| decodedItems([Value("bad")]))
			throw "Assigned branch return or local binding changed inside a loop.";
		if (nestedLoops([1], [-1]) || nestedLoops([1, 2], [1, -1]) || !nestedLoops([1], [1]) || !nestedLoops([], [-1]))
			throw "Inner loop return did not exit the enclosing function.";
		if (!loopClosure([1]) || loopClosure([-1]))
			throw "Loop-local closure return changed its enclosing scope.";
	}

	public static function loopClosure(values:Array<Int>):Bool {
		for (value in values) {
			final local = () -> {
				return value + 1;
			};
			if (local() < 1)
				return false;
		}
		return true;
	}

	public static function nestedLoops(outer:Array<Int>, inner:Array<Int>):Bool {
		for (first in outer) {
			for (second in inner) {
				if (first + second < 1)
					return false;
			}
		}
		return true;
	}

	/** The normal result must remain available after a returning initializer. */
	public static function decodedItems(items:Array<Item>):Bool {
		for (item in items) {
			final text = switch item {
				case Value(value): value;
				case Missing(_): return false;
			};
			if (["ok"].indexOf(text) < 0)
				return false;
		}
		return true;
	}

	/** Nested rejection must leave the enclosing function, not only the callback. */
	public static function rangeBytes(values:Array<Int>):Bool {
		final length = values.length;
		if (length != 4 && length != 8)
			return false;
		for (index in 0...length) {
			final value = values[index];
			if (length == 4) {
				if (index == 0 ? value != 127 : value < 0 || value > 255)
					return false;
			} else if (value != (index == 7 ? 1 : 0))
				return false;
		}
		return true;
	}

	public static function collectionValid(values:Array<Int>):Bool {
		for (value in values) {
			if (value < 10) {
				if (value < 0)
					return false;
			} else {
				if (value > 20)
					return false;
			}
		}
		return true;
	}

	static function elseOnly(first:Bool, denied:Bool):Int {
		var value = 1;
		if (first)
			value = 2;
		else {
			if (denied)
				return -1;
			value = 3;
		}
		return value;
	}

	static function closure(selected:Bool):Int {
		var value = 1;
		if (selected) {
			final local = () -> {
				return 3;
			};
			value = local();
		} else
			value = 1;
		return value + 3;
	}

	/** Stdout independently witnesses which paths reach the final effect. */
	static function effects(absent:Bool, denied:Bool):Int {
		Sys.println("enter");
		var current = 11;
		if (absent) {
			Sys.println("absent");
			if (denied)
				return -1;
		} else {
			Sys.println("present");
			if (denied)
				return -2;
			current = current + 2;
		}
		Sys.println("continue");
		return current;
	}

	public static function classify(outer:Bool, inner:Bool):String {
		if (outer) {
			if (inner)
				return "inner";
			return "outer";
		}
		return "fallback";
	}
}
