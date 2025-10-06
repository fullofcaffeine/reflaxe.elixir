/**
 * Test for TEnumParameter with ignored parameters
 *
 * This test verifies that when enum pattern matching uses ignored parameters (underscore),
 * the generated Elixir code doesn't attempt to extract from the already-extracted value.
 *
 * Issue: When pattern `{:ok, g}` extracts nil into g, TEnumParameter tries elem(g, 1)
 * which fails because g is nil, not the original tuple.
 */

enum Result<T> {
	Ok(value: T);
	Error(msg: String);
}

enum DataResult {
	Data(id: Int, timestamp: Float, name: String, metadata: Dynamic);
	NoData;
}

class Main {
	// Function that returns Ok(nil) to simulate the TodoPubSub.subscribe scenario
	static function subscribe(): Result<String> {
		return Ok(null);
	}
	
	public static function main() {
		// Test 1: Ignored parameter - should NOT generate elem() extraction
		switch (subscribe()) {
			case Ok(_):
				trace("Subscription successful");
			case Error(msg):
				trace("Error: " + msg);
		}
		
		// Test 2: Used parameter - extraction is needed
		switch (subscribe()) {
			case Ok(value):
				if (value != null) {
					trace("Got value: " + value);
				} else {
					trace("Got null value");
				}
			case Error(msg):
				trace("Error: " + msg);
		}
		
		// Test 3: Multiple parameters with some ignored
		var result = processData();
		switch (result) {
			case Data(id, _, name, _):
				trace("ID: " + id + ", Name: " + name);
			case NoData:
				trace("No data");
		}
	}

	static function processData(): DataResult {
		return Data(42, Date.now().getTime(), "Test", null);
	}
}