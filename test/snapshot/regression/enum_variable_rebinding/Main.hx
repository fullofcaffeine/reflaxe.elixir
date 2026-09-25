// Test for redundant variable rebinding in enum pattern matching
// This should NOT generate assignments like "g = result" in case bodies

@:elixirIdiomatic
enum Result<T, E> {
	Ok(value:T);
	Error(error:E);
}

@:elixirIdiomatic
enum Option<T> {
	Some(value:T);
	None;
}

class Main {
	static function main() {
		// Test Result with ignored parameter
		var result:Result<String, String> = Error("failed");
		var msg1 = switch (result) {
			case Ok(_):
				"Success";
			case Error(g):
				// Should NOT generate: g = result
				"Error: " + g;
		};
		trace(msg1);

		// Test Result with used parameter
		var result2:Result<Int, String> = Ok(42);
		var msg2 = switch (result2) {
			case Ok(value):
				"Got: " + value;
			case Error(_):
				// Should NOT generate: g = result2
				"Failed";
		};
		trace(msg2);

		// Test Option with pattern
		var opt:Option<String> = Some("hello");
		var msg3 = switch (opt) {
			case Some(value):
				"Value: " + value;
			case None:
				"Empty";
		};
		trace(msg3);

		// Test unwrap_or pattern (like in ChangesetUtils)
		var unwrapped = unwrapOr(Error("oops"), "default");
		trace(unwrapped);
		if (msg1 != "Error: failed" || msg2 != "Got: 42" || msg3 != "Value: hello" || unwrapped != "default")
			throw "Enum branches must preserve their payload values";
		if (independentAlias(Ok(42)) != 4243 || independentAlias(Error("failed")) != -1)
			throw "Payload and alias must remain independent";
	}

	/** An alias copies a value; changing it must not change the pattern payload. */
	@:keep
	public static function independentAlias(result:Result<Int, String>):Int {
		return switch (result) {
			case Ok(g):
				var value = g;
				value = value + 1;
				g * 100 + value;
			case Error(_): -1;
		};
	}

	static function unwrapOr<T>(result:Result<T, String>, defaultValue:T):T {
		return switch (result) {
			case Ok(g):
				// Should generate: value = g (or just use g directly)
				var value = g;
				value;
			case Error(g):
				// Should NOT generate: g = result
				// Just use defaultValue directly
				defaultValue;
		};
	}

	// Test the to_option pattern
	static function toOption<T>(result:Result<T, String>):Option<T> {
		return switch (result) {
			case Ok(g):
				var value = g;
				Some(value);
			case Error(g):
				// Should NOT generate: g = result
				None;
		};
	}
}
