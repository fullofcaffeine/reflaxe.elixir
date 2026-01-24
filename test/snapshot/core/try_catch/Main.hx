package;

import haxe.Exception;

/**
 * Try-catch exception handling test case
 * Tests exception throwing, catching, and finally blocks
 */
class Main {
	static inline function assertTrue(value: Bool, message: String): Void {
		if (!value) {
			throw 'Assertion failed: $message';
		}
	}

	static inline function assertEqualsString(expected: String, actual: String, message: String): Void {
		if (expected != actual) {
			throw 'Assertion failed: $message (expected "$expected", got "$actual")';
		}
	}

	static inline function assertEqualsInt(expected: Int, actual: Int, message: String): Void {
		if (expected != actual) {
			throw 'Assertion failed: $message (expected $expected, got $actual)';
		}
	}

	// Basic try-catch
	public static function basicTryCatch(): Void {
		var caughtString: String = try {
			trace("In try block");
			throw "Simple error";
			""; // Unreachable, but required for expression typing.
		} catch (e: String) {
			trace('Caught string: $e');
			e;
		}
		assertEqualsString("Simple error", caughtString, "basicTryCatch string catch");
		
		var caughtExceptionMessage: String = try {
			throw new Exception("Exception object");
			""; // Unreachable.
		} catch (e: Exception) {
			trace('Caught exception: ${e.message}');
			e.message;
		}
		assertEqualsString("Exception object", caughtExceptionMessage, "basicTryCatch Exception catch");
	}
	
	// Multiple catch blocks
	public static function multipleCatch(): Void {
		function testError(type: Int): Void {
			var outcome: String = try {
				switch (type) {
					case 1: throw "String error";
					case 2: throw 42;
					case 3: throw new Exception("Exception error");
					case 4: throw {error: "Object error"};
					default: "none";
				}
			} catch (e: String) {
				trace('Caught string: $e');
				'string:$e';
			} catch (e: Int) {
				trace('Caught int: $e');
				'int:$e';
			} catch (e: Exception) {
				trace('Caught exception: ${e.message}');
				'exception:${e.message}';
			} catch (e: Dynamic) {
				trace('Caught dynamic: $e');
				"dynamic";
			}

			var expected =
				if (type == 1) {
					"string:String error";
				} else if (type == 2) {
					"int:42";
				} else if (type == 3) {
					"exception:Exception error";
				} else if (type == 4) {
					"dynamic";
				} else {
					"none";
				};
			assertEqualsString(expected, outcome, 'multipleCatch type=$type');
		}
		
		testError(1);
		testError(2);
		testError(3);
		testError(4);
		testError(0);
	}
	
	// Try-catch-finally
	public static function tryCatchFinally(): Void {
		var resource = "resource";
		
		try {
			trace("Acquiring resource");
			throw "Error during operation";
		} catch (e: String) {
			trace('Error: $e');
		} 
		// Finally not supported in older Haxe, commenting out
		// finally {
		//	trace("Releasing resource in finally");
		//	resource = null;
		// }
		
		// Finally executes even without error
		try {
			trace("Normal operation");
		} catch (e: Dynamic) {
			// No error expected
		}
		trace("After try-catch block");
	}
	
	// Nested try-catch
	public static function nestedTryCatch(): Void {
		var caughtOuter: String = try {
			trace("Outer try");
			try {
				trace("Inner try");
				throw "Inner error";
			} catch (e: String) {
				trace('Inner catch: $e');
				throw "Rethrow from inner";
			}
			"no_error"; // Unreachable.
		} catch (e: String) {
			trace('Outer catch: $e');
			e;
		}
		assertEqualsString("Rethrow from inner", caughtOuter, "nestedTryCatch outer catch");
	}
	
	// Custom exception class
	public static function customException(): Void {
		var outcome: String = try {
			throw new CustomException("Custom error", 404);
			"no_error"; // Unreachable.
		} catch (e: CustomException) {
			trace('Custom exception: ${e.message}, code: ${e.code}');
			'${e.message}:${e.code}';
		}
		assertEqualsString("Custom error:404", outcome, "customException");
	}
	
	// Exception in function
	public static function divide(a: Float, b: Float): Float {
		if (b == 0) {
			throw new Exception("Division by zero");
		}
		return a / b;
	}
	
	public static function testDivision(): Void {
		var ok = divide(10, 2);
		trace('10 / 2 = $ok');
		assertTrue(ok == 5, "divide(10, 2) == 5");

		var caughtDivisionMessage: String = try {
			divide(10, 0);
			"no_error"; // Unreachable.
		} catch (e: Exception) {
			trace('Division error: ${e.message}');
			e.message;
		}
		assertEqualsString("Division by zero", caughtDivisionMessage, "divide(10, 0) throws");
	}
	
	// Rethrowing exceptions
	public static function rethrowExample(): Void {
		var message: String = try {
			try {
				throw new Exception("Original error");
			} catch (e: Exception) {
				trace('Middle caught: ${e.message}');
				throw e; // Rethrow
			}
			"no_error"; // Unreachable.
		} catch (e: Exception) {
			trace('Outer caught rethrown: ${e.message}');
			e.message;
		}
		assertEqualsString("Original error", message, "rethrowExample rethrow preserves value");
	}
	
	// Exception with stack trace
	public static function stackTraceExample(): Void {
		var caughtMessage: String = try {
			function level3() { throw new Exception("Deep error"); }
			function level2() { level3(); }
			function level1() { level2(); }
			level1();
			"no_error"; // Unreachable.
		} catch (e: Exception) {
			trace('Error: ${e.message}');
			// Stack trace handling would go here
			trace('Stack would be printed here');
			e.message;
		}
		assertEqualsString("Deep error", caughtMessage, "stackTraceExample message");
	}
	
	// Try as expression
	public static function tryAsExpression(): Void {
		var value: Int = try {
			var parsed = Std.parseInt("123");
			if (parsed == null) {
				throw "parseInt failed";
			}
			parsed;
		} catch (e: Dynamic) {
			0; // Default value
		}
		assertEqualsInt(123, value, "tryAsExpression parseInt(123)");
		
		var value2: Int = try {
			var parsed = Std.parseInt("not a number");
			if (parsed == null) {
				throw "parseInt failed";
			}
			parsed;
		} catch (e: Dynamic) {
			-1; // Error value
		}
		assertEqualsInt(-1, value2, "tryAsExpression throws and returns fallback");
	}
	
	public static function main() {
		trace("=== Basic Try-Catch ===");
		basicTryCatch();
		
		trace("\n=== Multiple Catch ===");
		multipleCatch();
		
		trace("\n=== Try-Catch-Finally ===");
		tryCatchFinally();
		
		trace("\n=== Nested Try-Catch ===");
		nestedTryCatch();
		
		trace("\n=== Custom Exception ===");
		customException();
		
		trace("\n=== Division Test ===");
		testDivision();
		
		trace("\n=== Rethrow Example ===");
		rethrowExample();
		
		trace("\n=== Stack Trace Example ===");
		stackTraceExample();
		
		trace("\n=== Try as Expression ===");
		tryAsExpression();
	}
}

// Custom exception class
class CustomException extends Exception {
	public var code: Int;
	
	public function new(message: String, code: Int) {
		super(message);
		this.code = code;
	}
}
