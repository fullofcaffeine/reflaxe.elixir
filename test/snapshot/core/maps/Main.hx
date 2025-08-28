package;

/**
 * Map/Dictionary test case
 * Tests various map types and operations
 */
class Main {
	// String map operations
	public static function stringMap(): Void {
		var map = new Map<String, Int>();
		
		// Set values
		map.set("one", 1);
		map.set("two", 2);
		map.set("three", 3);
		
		// Get values
		trace('Value of "two": ${map.get("two")}');
		trace('Value of "four": ${map.get("four")}'); // null
		
		// Check existence
		trace('Has "one": ${map.exists("one")}');
		trace('Has "four": ${map.exists("four")}');
		
		// Remove
		map.remove("two");
		trace('After remove, has "two": ${map.exists("two")}');
		
		// Iterate
		trace("Iterating string map:");
		for (key in map.keys()) {
			trace('  $key => ${map.get(key)}');
		}
		
		// Clear
		map.clear();
		trace('After clear, keys: ${[for (k in map.keys()) k]}');
	}
	
	// Int map operations
	public static function intMap(): Void {
		var map = new Map<Int, String>();
		
		map.set(1, "first");
		map.set(2, "second");
		map.set(10, "tenth");
		map.set(100, "hundredth");
		
		trace("Int map values:");
		for (key in map.keys()) {
			trace('  $key => ${map.get(key)}');
		}
		
		// Array of keys and values
		var keys = [for (k in map.keys()) k];
		var values = [for (k in map.keys()) map.get(k)];
		trace('Keys: $keys');
		trace('Values: $values');
	}
	
	// Object map (using objects as keys)
	public static function objectMap(): Void {
		var map = new Map<{id: Int}, String>();
		
		var obj1 = {id: 1};
		var obj2 = {id: 2};
		
		map.set(obj1, "Object 1");
		map.set(obj2, "Object 2");
		
		trace('Object 1 value: ${map.get(obj1)}');
		trace('Object 2 value: ${map.get(obj2)}');
		
		// Note: new object with same structure won't match
		var obj3 = {id: 1};
		trace('New {id: 1} value: ${map.get(obj3)}'); // null - different object
	}
	
	// Map literal syntax
	public static function mapLiterals(): Void {
		// String map literal
		var colors = [
			"red" => 0xFF0000,
			"green" => 0x00FF00,
			"blue" => 0x0000FF
		];
		
		trace("Color values:");
		for (color in colors.keys()) {
			var hex = StringTools.hex(colors.get(color), 6);
			trace('  $color => #$hex');
		}
		
		// Int map literal
		var squares = [
			1 => 1,
			2 => 4,
			3 => 9,
			4 => 16,
			5 => 25
		];
		
		trace("Squares:");
		for (n in squares.keys()) {
			trace('  $n² = ${squares.get(n)}');
		}
	}
	
	// Nested maps
	public static function nestedMaps(): Void {
		var users = new Map<String, Map<String, Dynamic>>();
		
		// Create user data
		var alice = new Map<String, Dynamic>();
		alice.set("age", 30);
		alice.set("email", "alice@example.com");
		alice.set("active", true);
		
		var bob = new Map<String, Dynamic>();
		bob.set("age", 25);
		bob.set("email", "bob@example.com");
		bob.set("active", false);
		
		users.set("alice", alice);
		users.set("bob", bob);
		
		// Access nested data
		trace("User data:");
		for (username in users.keys()) {
			var userData = users.get(username);
			trace('  $username:');
			for (field in userData.keys()) {
				trace('    $field: ${userData.get(field)}');
			}
		}
	}
	
	// Map operations and transformations
	public static function mapTransformations(): Void {
		var original = [
			"a" => 1,
			"b" => 2,
			"c" => 3,
			"d" => 4
		];
		
		// Map to new map (transform values)
		var doubled = new Map<String, Int>();
		for (key in original.keys()) {
			doubled.set(key, original.get(key) * 2);
		}
		
		trace("Doubled values:");
		for (key in doubled.keys()) {
			trace('  $key => ${doubled.get(key)}');
		}
		
		// Filter map
		var filtered = new Map<String, Int>();
		for (key in original.keys()) {
			var value = original.get(key);
			if (value > 2) {
				filtered.set(key, value);
			}
		}
		
		trace("Filtered (value > 2):");
		for (key in filtered.keys()) {
			trace('  $key => ${filtered.get(key)}');
		}
		
		// Merge maps
		var map1 = ["a" => 1, "b" => 2];
		var map2 = ["c" => 3, "d" => 4, "a" => 10]; // "a" will override
		
		var merged = new Map<String, Int>();
		for (key in map1.keys()) {
			merged.set(key, map1.get(key));
		}
		for (key in map2.keys()) {
			merged.set(key, map2.get(key));
		}
		
		trace("Merged maps:");
		for (key in merged.keys()) {
			trace('  $key => ${merged.get(key)}');
		}
	}
	
	// Map with enum keys
	public static function enumMap(): Void {
		var map = new Map<Color, String>();
		
		map.set(Red, "FF0000");
		map.set(Green, "00FF00");
		map.set(Blue, "0000FF");
		
		trace("Enum map:");
		for (color in map.keys()) {
			trace('  $color => #${map.get(color)}');
		}
		
		// Check specific enum value
		if (map.exists(Red)) {
			trace('Red color code: #${map.get(Red)}');
		}
	}
	
	// Map as function parameter and return
	public static function processMap(input: Map<String, Int>): Map<String, String> {
		var result = new Map<String, String>();
		for (key in input.keys()) {
			var value = input.get(key);
			result.set(key, 'Value: $value');
		}
		return result;
	}
	
	public static function main() {
		trace("=== String Map ===");
		stringMap();
		
		trace("\n=== Int Map ===");
		intMap();
		
		trace("\n=== Object Map ===");
		objectMap();
		
		trace("\n=== Map Literals ===");
		mapLiterals();
		
		trace("\n=== Nested Maps ===");
		nestedMaps();
		
		trace("\n=== Map Transformations ===");
		mapTransformations();
		
		trace("\n=== Enum Map ===");
		enumMap();
		
		trace("\n=== Map Functions ===");
		var input = ["x" => 10, "y" => 20, "z" => 30];
		var output = processMap(input);
		for (key in output.keys()) {
			trace('$key: ${output.get(key)}');
		}
	}
}

// Simple enum for testing
enum Color {
	Red;
	Green;
	Blue;
}