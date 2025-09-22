package;

// Regression test for enum pattern matching variable rebinding issue
// The compiler incorrectly generates "g = result" after pattern extraction
// This causes Elixir warnings about variable rebinding
enum TestResult<T> {
	Ok(value: T);
	Error(message: String);
}

class Main {
	public static function main() {
		// Test the ChangesetUtils pattern that's causing warnings
		var result = getResult();
		var value = unwrapOr(result, "default");
		trace(value);
	}
	
	// This pattern is exactly like ChangesetUtils.unwrap_or
	// Should NOT generate "g = result" in the Error case
	static function unwrapOr<T>(result: TestResult<T>, defaultValue: T): T {
		return switch(result) {
			case Ok(value):
				value;
			case Error(_):  // Ignored parameter causes the issue
				defaultValue;
		}
	}
	
	static function getResult(): TestResult<String> {
		return Error("test error");
	}
}