/** Checks that guard extraction preserves complete switch-case bodies. */
class Main {
	static var effects:Int = 0;

	static function recordEffect(value:Int):Void {
		effects = effects + value;
	}

	/** A false body condition does not reject an already matched case. */
	static function optionalEffect(mode:String, enabled:Bool):Void {
		switch (mode) {
			case "selected":
				if (enabled)
					recordEffect(1);
			default:
				recordEffect(10);
		}
	}

	static function returnedFields(data:{first:Int, second:Int, tag:Int}):Int {
		return switch ([data.first, data.second, data.tag]) {
			case [left, right, 1] if (left > 0): left + right;
			case [left, right, 2]: left * right;
			case [left, right, _]: left - right;
		};
	}

	static function returnedGuard(data:{value:Int}):Int {
		return switch (data.value) {
			case 0: 10;
			case 1: 20;
			case value if (value < 4): value + 1;
			case value: value + 2;
		};
	}

	static function classify(mode:String, input:Int):Int {
		return switch mode {
			case "convert":
				var adjusted = input + 1;
				if (adjusted == 0) 7 else adjusted;
			case "nested":
				if (input == 0) 9 else {
					var adjusted = input + 2;
					if (adjusted == 0)
						8
					else
						adjusted;
				}
			case "suffix":
				if (input < 0)
					rejectNegative(input);
				input + 3;
			case "checked":
				rejectNegative(input);
				if (input == 0) 6 else input;
			case "identity": input;
			default: -1;
		};
	}

	static function rejectNegative(input:Int):Void {
		if (input < 0)
			throw "negative input";
	}

	static function expect(actual:Int, expected:Int):Void {
		if (actual != expected)
			throw "Unexpected switch result";
	}

	static function expectRejected(mode:String):Void {
		final rejected = try {
			classify(mode, -1);
			false;
		} catch (error:String) {
			error == "negative input";
		};
		if (!rejected)
			throw "Case body effect was lost";
	}

	static function main():Void {
		effects = 0;
		optionalEffect("selected", false);
		expect(effects, 0);
		optionalEffect("selected", true);
		expect(effects, 1);
		optionalEffect("other", false);
		expect(effects, 11);
		expect(returnedFields({first: 11, second: 7, tag: 1}), 18);
		expect(returnedFields({first: 11, second: 7, tag: 2}), 77);
		expect(returnedFields({first: 11, second: 7, tag: 0}), 4);
		expect(returnedFields({first: -3, second: 7, tag: 1}), -10);
		expect(returnedGuard({value: 0}), 10);
		expect(returnedGuard({value: 1}), 20);
		expect(returnedGuard({value: 2}), 3);
		expect(returnedGuard({value: 9}), 11);
		expect(classify("convert", -1), 7);
		expect(classify("convert", 2), 3);
		expect(classify("nested", 0), 9);
		expect(classify("nested", -2), 8);
		expect(classify("nested", 2), 4);
		expect(classify("suffix", 2), 5);
		expect(classify("checked", 0), 6);
		expect(classify("checked", 2), 2);
		expect(classify("identity", 4), 4);
		expect(classify("other", 2), -1);
		expectRejected("checked");
		expectRejected("suffix");
	}
}
