package;

// Test case for enum pattern matching variable rebinding issue
// The compiler incorrectly generates "g = result" after pattern extraction
enum TestResult<T> {
	Ok(value: T);
	Error(message: String);
}

class Main {
	public static function main() {
		// Test with ignored parameter
		var result1 = testIgnoredParameter();
		trace(result1);
		
		// Test with used parameter
		var result2 = testUsedParameter();
		trace(result2);
	}
	
	// This should generate clean pattern matching without "g = result"
	static function testIgnoredParameter(): String {
		var result = getResult();
		
		return switch(result) {
			case Ok(_):
				"Success";
			case Error(_):
				"Failed";
		}
	}
	
	// This should also not have redundant assignment
	static function testUsedParameter(): String {
		var result = getResult();
		
		return switch(result) {
			case Ok(value):
				"Got: " + value;
			case Error(msg):
				"Error: " + msg;
		}
	}
	
	// Helper to simulate getting a result
	static function getResult(): TestResult<String> {
		return Ok("test value");
	}
	
	// Test the ChangesetUtils pattern
	static function unwrapOr<T>(result: TestResult<T>, defaultValue: T): T {
		return switch(result) {
			case Ok(value):
				value;
			case Error(_):
				// This is where the bug occurs - should NOT generate "g = result"
				defaultValue;
		}
	}
}