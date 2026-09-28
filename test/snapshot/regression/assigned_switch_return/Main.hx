enum Operation {
	Put(id:String);
	Remove;
}

class Main {
	static function decide(operation:Operation, exists:Bool):String {
		final value = switch operation {
			case Put(id):
				if (id != "ok")
					return "rejected";
				"payload";
			case Remove:
				if (!exists)
					return "missing";
				"deleted";
		};
		return "saved:" + value;
	}

	/** Chained conditions must distinguish a function return from a branch value. */
	public static function conditionalValue(kind:Int):Int {
		final value = if (kind == 0) {
			return 90;
		} else if (kind == 1) {
			10;
		} else return 80;
		return value + 1;
	}

	public static function protectedConditional(kind:Int):Int {
		try {
			final value = if (kind == 0) {
				return 90;
			} else if (kind == 1) {
				10;
			} else return 80;
			return value + 1;
		} catch (error:haxe.Exception) {
			return -1;
		}
	}

	/** Conditions run once, in order; only a normal branch runs the continuation. */
	public static function conditionalEffects(kind:Int, observe:Int->Int):Int {
		if (observe(kind) == 0) {
			return 90;
		} else if (observe(kind + 10) == 11) {
			observe(20);
		} else
			return 80;
		return observe(30);
	}

	public static function implicitElse(kind:Int, observe:Int->Int):Int {
		if (kind == 0) {
			return 90;
		} else if (kind == 1) {
			observe(20);
		}
		return observe(30);
	}

	public static function conditionalClosure(kind:Int):Int {
		final value = if (kind == 0) {
			final callback = function():Int {
				return 40;
			};
			callback();
		} else if (kind == 1) {
			return 90;
		} else 10;
		return value + 1;
	}

	public static function protectedThrow(kind:Int):Int {
		try {
			final value = if (kind == 0) {
				return 90;
			} else if (kind == 1) {
				mayFail(kind);
			} else 10;
			if (kind == 2)
				throw new haxe.Exception("continuation");
			return value + 1;
		} catch (error:haxe.Exception) {
			return -1;
		}
	}

	/** A called operation can fail while a conditional value is evaluated. */
	static function mayFail(kind:Int):Int {
		if (kind == 1)
			throw new haxe.Exception("branch");
		return 10;
	}

	static function main():Void {
		for (kind in 0...3) {
			final expected = kind == 0 ? 90 : kind == 1 ? 11 : 80;
			if (conditionalValue(kind) != expected || protectedConditional(kind) != expected)
				throw "Conditional return did not exit its function.";
		}

		if (conditionalClosure(0) != 41 || conditionalClosure(1) != 90 || conditionalClosure(2) != 11)
			throw "Conditional closure changed return ownership.";
		if (protectedThrow(0) != 90 || protectedThrow(1) != -1 || protectedThrow(2) != -1 || protectedThrow(3) != 11)
			throw "Conditional continuation changed its catch scope.";

		if (decide(Put("bad"), true) != "rejected")
			throw "Switch return did not exit the function.";
		if (decide(Remove, false) != "missing")
			throw "Missing-document return did not exit the function.";
		if (decide(Put("ok"), true) != "saved:payload")
			throw "Valid write changed.";
		if (decide(Remove, true) != "saved:deleted")
			throw "Valid delete changed.";
		if (nested(Put("bad"), true) != "outer")
			throw "Outer switch exit changed.";
		if (nested(Put("ok"), false) != "inner")
			throw "Nested switch exit changed.";
		if (nested(Put("ok"), true) != "saved:inside")
			throw "Nested normal continuation changed.";
		if (closureValue(true) != "saved:closure")
			throw "Closure return escaped its function.";
		if (closureValue(false) != "saved:other")
			throw "Normal alternate branch changed.";
	}

	static function nested(operation:Operation, exists:Bool):String {
		final value = switch operation {
			case Put(id):
				if (id != "ok")
					return "outer";
				final inner = switch operation {
					case Put(_):
						if (!exists)
							return "inner";
						"inside";
					case Remove: "unused";
				};
				inner;
			case Remove: "removed";
		};
		return "saved:" + value;
	}

	static function closureValue(selected:Bool):String {
		final value = if (selected) {
			final callback = function():String {
				return "closure";
			};
			callback();
		} else "other";
		return "saved:" + value;
	}
}
