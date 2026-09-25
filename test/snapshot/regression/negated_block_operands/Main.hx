/** Unary operands retain their complete value and execute only when demanded. */
class Main {
	static function receiver(label:String):EReg {
		Sys.println(label + ":receiver");
		return ~/^[a-z]+$/;
	}

	static function argument(label:String, value:String):String {
		Sys.println(label + ":argument");
		return value;
	}

	static function left(label:String, value:Bool):Bool {
		Sys.println(label + ":left");
		return value;
	}

	static function rejects(value:String):Bool {
		return value.length != 3 || !~/^[a-z]+$/.match(value);
	}

	static function fail():String {
		Sys.println("throw:argument");
		throw "expected";
	}

	static function main():Void {
		if (rejects("abc") || !rejects("a!c") || !rejects("abcd"))
			throw "validation changed";
		Sys.println(left("or-skip", true) || !receiver("unexpected").match(argument("unexpected", "abc")));
		Sys.println(left("or-run", false) || !receiver("or-run").match(argument("or-run", "a!c")));
		Sys.println(left("and-skip", false) && !receiver("unexpected").match(argument("unexpected", "abc")));
		Sys.println(left("and-run", true) && !receiver("and-run").match(argument("and-run", "abc")));
		Sys.println(!receiver("standalone").match(argument("standalone", "a!c")));
		Sys.println(!(!receiver("double").match(argument("double", "abc"))));
		Sys.println(-({Sys.println("numeric:block"); 7;}));
		try {
			Sys.println(left("throw", false) || !receiver("throw").match(fail()));
			throw "unreachable";
		} catch (message:String) {
			if (message != "expected")
				throw message;
			Sys.println("throw:caught");
		}
	}
}
