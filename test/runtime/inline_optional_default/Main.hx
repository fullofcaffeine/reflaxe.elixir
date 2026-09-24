enum Outcome {
	Valid(value:String);
	Invalid(reason:String, context:String);
}

/** Inline defaults must preserve explicit null as well as omitted arguments. */
abstract Result(Outcome) from Outcome to Outcome {
	public inline function new(value:Outcome) {
		this = value;
	}

	public static inline function failure(reason:String, context:String = ""):Result {
		return new Result(Invalid(reason, context));
	}
}

class Main {
	static var fallbackCalls = 0;

	static function fallback():String {
		fallbackCalls = fallbackCalls + 1;
		return "default";
	}

	public static function stringFallback(value:Null<String>):String {
		return value == null ? fallback() : value;
	}

	public static function boolFallback(value:Null<Bool>):Bool {
		return value == null ? true : value;
	}

	static function validate(ok:Bool):Outcome {
		return ok ? Valid("ok") : Invalid("bad", "validation");
	}

	public static function chained(ok:Bool):Outcome {
		return switch (validate(ok)) {
			case Valid(value): Valid(value);
			case Invalid(reason, context): Result.failure(reason, context);
		};
	}

	public static function forwarded(context:Null<String>):Outcome {
		return Result.failure("bad", context);
	}

	static function check(actual:Outcome, expected:String):Void {
		var observed = switch (actual) {
			case Valid(value): "valid:" + value;
			case Invalid(reason, context): reason + ":" + context;
		};
		if (observed != expected)
			throw "Expected " + expected + ", got " + observed;
	}

	public static function main():Void {
		check(chained(true), "valid:ok");
		check(chained(false), "bad:validation");
		check(forwarded(null), "bad:");
		check(forwarded("source"), "bad:source");
		check(Result.failure("bad"), "bad:");
		if (boolFallback(false) != false || boolFallback(null) != true)
			throw "Null-only Boolean defaults must preserve false";
		if (stringFallback("") != "" || fallbackCalls != 0)
			throw "Empty strings must not evaluate their fallback";
		if (stringFallback(null) != "default" || fallbackCalls != 1)
			throw "Null must evaluate its fallback exactly once";
		// The runtime runner must retain calls inside trace arguments.
		trace(fallback());
		if (fallbackCalls != 2)
			throw "Runtime fixtures must evaluate trace arguments";
		Sys.println("Inline optional default: runtime assertions passed");
	}
}
