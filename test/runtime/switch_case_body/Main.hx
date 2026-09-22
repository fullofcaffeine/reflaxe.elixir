/** Checks that guard extraction preserves complete switch-case bodies. */
class Main {
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
