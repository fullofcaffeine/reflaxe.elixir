package;

/**
 * Dynamic type test case
 * Tests dynamic typing and runtime type checking
 */
class Main {
	// Dynamic variables
	public static function dynamicVars(): Void {
		var dyn: Dynamic = 42;
		trace(dyn);
		
		dyn = "Hello";
		trace(dyn);
		
		dyn = [1, 2, 3];
		trace(dyn);
		
		dyn = {name: "John", age: 30};
		trace(dyn);
		
		dyn = function(x) return x * 2;
		trace(dyn(5));
	}
	
	// Dynamic field access
	public static function dynamicFieldAccess(): Void {
		var obj: Dynamic = {
			name: "Alice",
			age: 25,
			greet: function() return "Hello!"
		};
		
		trace(obj.name);
		trace(obj.age);
		trace(obj.greet());
		
		// Add field dynamically
		obj.city = "New York";
		trace(obj.city);
		
		// Access non-existent field
		trace(obj.nonExistent); // Should be null/undefined
	}
	
	// Dynamic function calls
	public static function dynamicFunctions(): Void {
		var fn: Dynamic = function(a, b) return a + b;
		trace(fn(10, 20));
		
		fn = function(s: String) return s.toUpperCase();
		trace(fn("hello"));
		
		// Function with variable arguments
		var varArgs: Dynamic = function(args: Array<Dynamic>) {
			var sum = 0;
			for (arg in args) {
				sum += arg;
			}
			return sum;
		};
		trace(varArgs([1, 2, 3, 4, 5]));
	}
	
	// Type checking with Dynamic
	public static function typeChecking(): Void {
		var value: Dynamic = 42;
		
		// Check type at runtime
		if (Std.isOfType(value, Int)) {
			trace("It's an Int: " + value);
		}
		
		value = "Hello";
		if (Std.isOfType(value, String)) {
			trace("It's a String: " + value);
		}
		
		value = [1, 2, 3];
		if (Std.isOfType(value, Array)) {
			trace("It's an Array with length: " + value.length);
		}
		
		// Type casting
		var num: Dynamic = "123";
		var intValue = Std.parseInt(num);
		trace("Parsed int: " + intValue);
		
		var floatValue = Std.parseFloat("3.14");
		trace("Parsed float: " + floatValue);
	}
	
	// Dynamic with generics
	public static function dynamicGenerics<T>(value: Dynamic): T {
		return cast value;
	}
	
	// Dynamic arrays and objects
	public static function dynamicCollections(): Void {
		// Dynamic array
		var dynArray: Array<Dynamic> = [1, "two", 3.0, true, {x: 10}];
		for (item in dynArray) {
			trace("Item: " + item);
		}
		
		// Dynamic object/map
		var dynObj: Dynamic = {};
		dynObj.field1 = "value1";
		dynObj.field2 = 42;
		dynObj.field3 = [1, 2, 3];
		
		// Iterate dynamic object (if supported)
		trace(dynObj);
	}
	
	// Function accepting Dynamic
	public static function processDynamic(value: Dynamic): String {
		if (value == null) {
			return "null";
		} else if (Std.isOfType(value, Bool)) {
			return "Bool: " + value;
		} else if (Std.isOfType(value, Int)) {
			return "Int: " + value;
		} else if (Std.isOfType(value, Float)) {
			return "Float: " + value;
		} else if (Std.isOfType(value, String)) {
			return "String: " + value;
		} else if (Std.isOfType(value, Array)) {
			return "Array of length: " + value.length;
		} else {
			return "Unknown type";
		}
	}
	
	// Dynamic method calls
	public static function dynamicMethodCalls(): Void {
		var obj: Dynamic = {};
		obj.value = 10;
		obj.increment = function() {
			obj.value++;
		};
		obj.getValue = function() {
			return obj.value;
		};
		
		trace("Initial value: " + obj.getValue());
		obj.increment();
		trace("After increment: " + obj.getValue());
		
		// Call method by name (reflection-like)
		var methodName = "increment";
		Reflect.callMethod(obj, Reflect.field(obj, methodName), []);
		trace("After reflect call: " + obj.getValue());
	}
	
	public static function main() {
		trace("=== Dynamic Variables ===");
		dynamicVars();
		
		trace("\n=== Dynamic Field Access ===");
		dynamicFieldAccess();
		
		trace("\n=== Dynamic Functions ===");
		dynamicFunctions();
		
		trace("\n=== Type Checking ===");
		typeChecking();
		
		trace("\n=== Dynamic Collections ===");
		dynamicCollections();
		
		trace("\n=== Process Dynamic ===");
		trace(processDynamic(null));
		trace(processDynamic(true));
		trace(processDynamic(42));
		trace(processDynamic(3.14));
		trace(processDynamic("Hello"));
		trace(processDynamic([1, 2, 3]));
		trace(processDynamic({x: 1, y: 2}));
		
		trace("\n=== Dynamic Method Calls ===");
		dynamicMethodCalls();
		
		trace("\n=== Dynamic Generics ===");
		var str: String = dynamicGenerics("Hello from dynamic");
		trace(str);
	}
}