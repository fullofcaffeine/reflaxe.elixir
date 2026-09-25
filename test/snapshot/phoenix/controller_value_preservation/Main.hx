/** Haxe expectations are independent of the controller cleanup passes (yeu). */
class Main {
	static function main() {
		if (ValueController.rebind(3) != 10)
			throw "controller preparation was lost";
		if (ValueController.nested(40, Accepted(5)) != 52)
			throw "outer value was replaced";
		if (ValueController.nested(40, Denied) != -1)
			throw "denial changed";
		if (ValueController.nested(-1, Accepted(5)) != -2)
			throw "nested denial changed";
		if (ValueController.nested(40, Accepted(-1)) != -3)
			throw "caught exception changed";
		if (ValueController.ignored(Accepted(9), 70) != 70)
			throw "ignored payload shadowed outer value";
		if (ValueController.nestedIgnored(Accepted(70), Accepted(9)) != 70)
			throw "nested ignored payload shadowed outer binder";
		if (PlainValues.nestedIgnored(Accepted(70), Accepted(9)) != 70)
			throw "plain nested ignored payload shadowed outer binder";
		if (ValueController.aliases(3, 4, 10) != 27)
			throw "adjacent aliases were deleted";
		if (ValueController.nestedOk(Ok(70), Ok(9)) != 70)
			throw "ignored Ok payload shadowed outer value";
		if (ValueController.nestedError(Error(70), Error(9)) != 70)
			throw "ignored Error payload shadowed outer reason";
		if (ValueController.crossReceiver(Ok(5), Ok(9)) != 79)
			throw "nested receiver made an ignored outer payload live";
	}
}

/** Closed input domain shared with the stock-Haxe reference run. */
@:elixirIdiomatic
enum Input {
	Accepted(value:Int);
	Denied;
}

/** Conventional constructor names must preserve the same typed scope rules. */
@:elixirIdiomatic
enum Result {
	Ok(value:Int);
	Error(reason:Int);
}

/** Annotation activates the same passes as a real Phoenix controller. */
@:controller
@:native("ProbeWeb.ValueController")
class ValueController {
	public static function crossReceiver(ignored:Result, inner:Result):Int {
		var value = 70;
		return switch ignored {
			case Ok(_): switch inner {
					case Ok(number): value + number;
					case Error(_): -2;
				};
			case Error(_): -1;
		};
	}

	public static function aliases(conn:Int, data:Int, original:Int):Int {
		var initial = conn + data;
		conn = original;
		data = original;
		return conn + data + initial;
	}

	public static function nestedOk(input:Result, outcome:Result):Int {
		return switch input {
			case Ok(value): switch outcome {
					case Ok(_): value;
					case Error(_): -2;
				};
			case Error(_): -1;
		};
	}

	public static function nestedError(input:Result, outcome:Result):Int {
		return switch input {
			case Error(reason): switch outcome {
					case Error(_): reason;
					case Ok(_): -2;
				};
			case Ok(_): -1;
		};
	}

	public static function rebind(conn:Int):Int {
		conn = prepare(conn);
		return conn;
	}

	public static function nested(credential:Int, input:Input):Int {
		return switch input {
			case Accepted(value):
				try {
					switch transform(credential, value) {
						case Accepted(result): result;
						case Denied: -2;
					}
				} catch (error:String) {
					error == "expected" ? -3 : -4;
				}
			case Denied: -1;
		};
	}

	public static function ignored(input:Input, request:Int):Int {
		return switch input {
			case Accepted(_): request;
			case Denied: -1;
		};
	}

	public static function nestedIgnored(input:Input, outcome:Input):Int {
		return switch input {
			case Accepted(request):
				switch outcome {
					case Accepted(_): request;
					case Denied: -2;
				}
			case Denied: -1;
		};
	}

	private static function transform(credential:Int, value:Int):Input {
		if (value < 0)
			throw "expected";
		return credential < 0 ? Denied : Accepted(credential + value + 7);
	}

	private static function prepare(value:Int):Int {
		Sys.println("prepared");
		return value + 7;
	}
}

/** The same binding contract also applies outside framework modules. */
class PlainValues {
	public static function nestedIgnored(input:Input, outcome:Input):Int {
		return switch input {
			case Accepted(request):
				switch outcome {
					case Accepted(_): request;
					case Denied: -2;
				}
			case Denied: -1;
		};
	}
}
