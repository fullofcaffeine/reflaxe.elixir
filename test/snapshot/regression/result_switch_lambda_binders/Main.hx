package;

import haxe.functional.Result;

typedef Payload = {
	final amount:Int;
}

/**
 * Regression coverage for lambda scope inside enum switch branches.
 *
 * Each callback is ordinary Haxe. The generated Elixir must keep the callback's
 * own parameter distinct from `payload`, while still allowing intentional
 * closure capture of that outer pattern value.
 */
class Main {
	static function applyTo(input:Int, callback:Int->Int):Int {
		return callback(input);
	}

	static function applyResultTo(input:Int, callback:Int->Result<Int, String>):Result<Int, String> {
		return callback(input);
	}

	static function assertEquals(label:String, expected:Int, actual:Int):Void {
		if (expected != actual) {
			throw '$label: expected $expected, got $actual';
		}
	}

	static function verify(result:Result<Int, String>):Void {
		switch (result) {
			case Ok(payload):
				assertEquals("identity callback", 7, applyTo(7, (value:Int) -> value));
				assertEquals("arithmetic callback", 12, applyTo(7, (value:Int) -> value + 5));
				assertEquals("outer capture", 10, applyTo(7, (_ignored:Int) -> payload));
				assertEquals("mixed local and outer capture", 17, applyTo(7, (value:Int) -> value + payload));
				assertEquals("parameter shadows outer payload", 8, applyTo(7, (payload:Int) -> payload + 1));
				assertEquals("nested parameter shadowing", 9, applyTo(7, (value:Int) -> applyTo(value, (value:Int) -> value + 2)));
				switch (applyResultTo(7, (value:Int) -> Ok(value))) {
					case Ok(callbackValue):
						assertEquals("tuple-returning callback", 7, callbackValue);
					case Error(callbackError):
						throw 'unexpected callback error: $callbackError';
				}
			case Error(message):
				throw 'unexpected error: $message';
		}
	}

	static function verifyObjectCapture(result:Result<Payload, String>):Void {
		switch (result) {
			case Ok(payload):
				assertEquals("outer object capture", 10, applyTo(7, (_ignored:Int) -> payload.amount));
			case Error(message):
				throw 'unexpected object error: $message';
		}
	}

	public static function main():Void {
		verify(Ok(10));
		verifyObjectCapture(Ok({amount: 10}));
	}
}
