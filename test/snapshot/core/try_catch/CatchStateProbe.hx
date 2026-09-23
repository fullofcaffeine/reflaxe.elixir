/** A completed handler exports outer writes without leaking its local bindings. */
class CatchStateProbe {
	static function fail(mode:Int):Void {
		if (mode == 1)
			throw "rejected";
		if (mode == 2)
			throw 7;
		if (mode == 3)
			throw 1.5;
	}

	static function caughtFlag(mode:Int):Bool {
		var rejected = false;
		try {
			fail(mode);
		} catch (error:String) {
			rejected = error == "rejected";
		}
		return rejected;
	}

	static function handlerShadow(mode:Int):Int {
		var result = 10;
		try {
			fail(mode);
		} catch (error:String) {
			result = error == "rejected" ? 20 : 30;
		} catch (result:Int) {
			if (result != 7)
				throw "Wrong handler value";
		}
		return result;
	}

	public static function main():Void {
		if (caughtFlag(0) || !caughtFlag(1))
			throw "Handler lost its outer flag or changed the normal path";
		if (handlerShadow(0) != 10 || handlerShadow(1) != 20 || handlerShadow(2) != 10)
			throw "Handler-local binding changed the outer value";
		final propagated = try {
			caughtFlag(2);
			false;
		} catch (value:Int) {
			value == 7;
		};
		if (!propagated)
			throw "Unmatched exception did not propagate";
		final floatPropagated = try {
			handlerShadow(3);
			false;
		} catch (value:Float) {
			value == 1.5;
		};
		if (!floatPropagated)
			throw "Integer handler caught an unmatched floating-point error";
	}
}
