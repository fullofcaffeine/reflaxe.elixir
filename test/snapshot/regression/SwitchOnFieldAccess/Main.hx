package;

import haxe.ds.Option;
import haxe.functional.Result;

class Main {
	static function main() {
		var msg = {type: "test", value: 42};

		// Test 1: Simple switch on field access
		var result1 = parseMessage1(msg);
		trace('Result 1: $result1');

		// Test 2: Switch on field access with early return
		var result2 = parseMessage2(msg);
		trace('Result 2: $result2');

		// String conversion needs the enum's constructor metadata, even when
		// constructors themselves lower directly to tagged values.
		if (Std.string(result1) != "Some(found test)" || Std.string(result2) != "Some(found test)")
			throw "Field-switch results must preserve constructor names and payloads";
		if (Std.string(parseMessage2(null)) != "None")
			throw "The empty constructor must retain its metadata";
		var success:Result<Int, String> = Ok(42);
		var failure:Result<Int, String> = Error("missing");
		if (Std.string(success) != "Ok(42)" || Std.string(failure) != "Error(missing)")
			throw "Library enum metadata must not depend on the package or constructor name";
	}

	// Simple switch on field access
	static function parseMessage1(msg:Dynamic):Option<String> {
		return switch (msg.type) {
			case "test": Some("found test");
			case "other": Some("found other");
			case _: None;
		};
	}

	// Switch on field access with early return (like TodoPubSub)
	static function parseMessage2(msg:Dynamic):Option<String> {
		if (msg == null) {
			return None;
		}

		return switch (msg.type) {
			case "test": Some("found test");
			case "other": Some("found other");
			case _: None;
		};
	}
}
