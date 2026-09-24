/** Temporary elimination must not repeat an effectful initializer. */
class Main {
	static var calls = 0;
	static var events = "";

	static function record(label:String):Int {
		events = events + label;
		return events.length;
	}

	static function checkOrder():Void {
		events = "";
		var g = record("a");
		record("b");
		if (g != 1 || events != "ab")
			throw "A saved call moved past a later effect.";
	}

	static function checkUnused():Void {
		events = "";
		var g = record("a");
		if (events != "a")
			throw "An unused result erased its effect.";
	}

	static function checkCapturedLocal():Void {
		var source = 3;
		var g = source;
		source = 9;
		if (g != 3 || source != 9)
			throw "A saved local became a later read.";
	}

	static function checkWrittenLocal():Void {
		var g = 1;
		g = 4;
		g += 2;
		g++;
		if (g != 7)
			throw "Literal substitution erased later writes.";
	}

	static function pair():{key:Int, value:Int} {
		calls = calls + 1;
		return {key: calls, value: calls * 10};
	}

	static function maybeFail(shouldFail:Bool):Int {
		record("a");
		if (shouldFail)
			throw "expected";
		return 0;
	}

	static function caughtAtOriginalPosition():Bool {
		try {
			var g = maybeFail(true);
			record("b");
			return g == 0;
		} catch (message:String) {
			return message == "expected" && events == "a";
		}
	}

	static function checkException():Void {
		events = "";
		if (!caughtAtOriginalPosition())
			throw "A saved call changed exception order.";
		events = "";
		var g = maybeFail(false);
		record("b");
		if (g != 0 || events != "ab")
			throw "A successful call changed effect order.";
	}

	static function checkLiteralSwitch():Void {
		var g = 2;
		final result = switch (g) {
			case 1: "one";
			case 2: "two";
			default: "other";
		};
		if (result != "two" || g != 2)
			throw "Stable literal substitution changed a switch.";
	}

	static function missingEntry(items:Array<String>):Bool {
		if (items.length != 3 || items.indexOf("first") < 0 || items.indexOf("second") < 0 || items.indexOf("last") < 0)
			return true;
		return false;
	}

	static function checkCompoundCondition():Void {
		if (!missingEntry(["first", "second", "wrong"]))
			throw "The final condition operand was lost.";
		if (missingEntry(["first", "second", "last"]))
			throw "A complete selection was rejected.";
	}

	static function main():Void {
		PatternBindingProbe.main();
		checkCompoundCondition();
		calls = 0;
		var g = pair();
		final key = g.key;
		final value = g.value;
		if (calls != 1 || key != 1 || value != 10)
			throw "A captured pair must be evaluated once.";
		checkOrder();
		checkUnused();
		checkCapturedLocal();
		checkWrittenLocal();
		checkException();
		checkLiteralSwitch();
	}
}
