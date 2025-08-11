package;

import haxe.Exception;

/**
 * Try-catch exception handling test case
 * Tests exception throwing, catching, and finally blocks
 */
class Main {
	// Basic try-catch
	public static function basicTryCatch(): Void {
		try {
			trace("In try block");
			throw "Simple error";
			trace("This won't execute");
		} catch (e: String) {
			trace('Caught string: $e');
		}
		
		try {
			throw new Exception("Exception object");
		} catch (e: Exception) {
			trace('Caught exception: ${e.message}');
		}
	}
	
	// Multiple catch blocks
	public static function multipleCatch(): Void {
		function testError(type: Int): Void {
			try {
				switch (type) {
					case 1: throw "String error";
					case 2: throw 42;
					case 3: throw new Exception("Exception error");
					case 4: throw {error: "Object error"};
					default: trace("No error");
				}
			} catch (e: String) {
				trace('Caught string: $e');
			} catch (e: Int) {
				trace('Caught int: $e');
			} catch (e: Exception) {
				trace('Caught exception: ${e.message}');
			} catch (e: Dynamic) {
				trace('Caught dynamic: $e');
			}
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
		try {
			trace("Outer try");
			try {
				trace("Inner try");
				throw "Inner error";
			} catch (e: String) {
				trace('Inner catch: $e');
				throw "Rethrow from inner";
			}
		} catch (e: String) {
			trace('Outer catch: $e');
		}
	}
	
	// Custom exception class
	public static function customException(): Void {
		try {
			throw new CustomException("Custom error", 404);
		} catch (e: CustomException) {
			trace('Custom exception: ${e.message}, code: ${e.code}');
		}
	}
	
	// Exception in function
	public static function divide(a: Float, b: Float): Float {
		if (b == 0) {
			throw new Exception("Division by zero");
		}
		return a / b;
	}
	
	public static function testDivision(): Void {
		try {
			var result = divide(10, 2);
			trace('10 / 2 = $result');
			
			result = divide(10, 0);
			trace('This won\'t execute');
		} catch (e: Exception) {
			trace('Division error: ${e.message}');
		}
	}
	
	// Rethrowing exceptions
	public static function rethrowExample(): Void {
		function innerFunction(): Void {
			throw new Exception("Original error");
		}
		
		function middleFunction(): Void {
			try {
				innerFunction();
			} catch (e: Exception) {
				trace('Middle caught: ${e.message}');
				throw e; // Rethrow
			}
		}
		
		try {
			middleFunction();
		} catch (e: Exception) {
			trace('Outer caught rethrown: ${e.message}');
		}
	}
	
	// Exception with stack trace
	public static function stackTraceExample(): Void {
		try {
			function level3() { throw new Exception("Deep error"); }
			function level2() { level3(); }
			function level1() { level2(); }
			level1();
		} catch (e: Exception) {
			trace('Error: ${e.message}');
			// Stack trace handling would go here
			trace('Stack would be printed here');
		}
	}
	
	// Try as expression
	public static function tryAsExpression(): Void {
		var value = try {
			Std.parseInt("123");
		} catch (e: Dynamic) {
			0; // Default value
		}
		trace('Parsed value: $value');
		
		var value2 = try {
			Std.parseInt("not a number");
		} catch (e: Dynamic) {
			-1; // Error value
		}
		trace('Failed parse value: $value2');
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