/**
 * Test case for enum pattern variable names
 * 
 * This test verifies that enum patterns preserve user-specified variable names
 * instead of using generic names (g, g1, g2)
 */
// Test regular enum with meaningful parameter names
enum Status {
	Loading;
	Success(data:String);
	Failure(error:String, code:Int);
}

// Test nested enum patterns
enum NestedResult {
	Ok(status:Status);
	Error(message:String);
}

class Main {
	public static function main() {
		assertText(describeStatus(Loading), "Loading...");
		assertText(describeStatus(Success("Hello World")), "Got data: Hello World");
		assertText(describeStatus(Failure("Network", 500)), "Error 500: Network");
		assertText(describeNested(Ok(Loading)), "Still loading");
		assertText(describeNested(Ok(Success("Nested"))), "Nested success: Nested");
		assertText(describeNested(Ok(Failure("Offline", 503))), "Nested failure 503: Offline");
		assertText(describeNested(Error("Missing")), "Top level error: Missing");
		assertText(describeMixed(Success("ignored")), "Success (data ignored)");
		assertText(describeMixed(Failure("Network error", 500)), "Error occurred: Network error");
		assertText(describeMixed(Loading), "Loading");
	}

	static function assertText(actual:String, expected:String):Void {
		if (actual != expected)
			throw 'Expected $expected, got $actual';
	}

	static function describeStatus(status:Status):String {
		// Test 1: Simple enum pattern with meaningful names
		return switch (status) {
			case Loading:
				"Loading...";
			case Success(data):
				// Should use 'data' not 'g'
				'Got data: $data';
			case Failure(error, code):
				// Should use 'error' and 'code' not 'g' and 'g1'
				'Error $code: $error';
		}
	}

	static function describeNested(nested:NestedResult):String {
		// Test 2: Nested enum patterns
		return switch (nested) {
			case Ok(Loading):
				"Still loading";
			case Ok(Success(data)):
				// Should preserve 'data' name
				'Nested success: $data';
			case Ok(Failure(error, code)):
				'Nested failure $code: $error';
			case Error(message):
				'Top level error: $message';
		}
	}

	static function describeMixed(mixed:Status):String {
		// Test 3: Pattern with unused parameters
		return switch (mixed) {
			case Success(_):
				"Success (data ignored)";
			case Failure(error, _):
				// Should use 'error' for first param, underscore for second
				'Error occurred: $error';
			case Loading:
				"Loading";
		}
	}
}
