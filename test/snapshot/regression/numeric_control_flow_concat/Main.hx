/** Numeric control-flow results need conversion at the string operand boundary. */
class Main {
	static function numeric(flag:Bool, value:Int):Void {
		Sys.println("case:" + (switch (value) {
			case 0: 7;
			default: 9;
		}));
		Sys.println("if:" + (if (flag) 3 else 4));
		Sys.println("float:" + (if (flag) 1.0 else 2.5));
		Sys.println("block:" + ({Sys.println("block-effect"); value + 10;}));
		Sys.println((if (flag) 5 else 6) + ":left");
		Sys.println("string:" + (if (flag) "yes" else "no"));
	}

	static function randomText(bound:Int):String {
		return "random:" + Std.random(bound);
	}

	static function prefix():String {
		Sys.println("left-effect");
		return "ordered:";
	}

	static function number():Int {
		Sys.println("right-effect");
		return 8;
	}

	static function fail(shouldThrow:Bool):Int {
		Sys.println("throw-effect");
		if (shouldThrow)
			throw "stop";
		return 12;
	}

	static function main():Void {
		numeric(true, 0);
		numeric(false, 1);
		Sys.println(randomText(0));
		Sys.println(randomText(1));
		Sys.println(prefix() + ({final value = number(); value;}));
		try {
			Sys.println(prefix() + ({final value = fail(Std.random(1) == 0); value;}));
			throw "unreachable";
		} catch (message:String) {
			if (message != "stop")
				throw message;
			Sys.println("caught:stop");
		}
	}
}
