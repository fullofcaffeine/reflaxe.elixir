package;

/**
 * Basic syntax test case
 * Tests fundamental Haxe→Elixir compilation
 */
class Main {
	// Constants and variables
	static final CONSTANT = 42;
	static var staticVar = "hello";
	var instanceVar: Int;
	
	// Constructor
	public function new(value: Int) {
		this.instanceVar = value;
	}
	
	// Static function
	public static function greet(name: String): String {
		return 'Hello, $name!';
	}
	
	// Instance method
	public function calculate(x: Int, y: Int): Int {
		return x + y * instanceVar;
	}
	
	// Control flow
	public function checkValue(n: Int): String {
		if (n < 0) {
			return "negative";
		} else if (n == 0) {
			return "zero";
		} else {
			return "positive";
		}
	}
	
	// Loops
	public function sumRange(start: Int, end: Int): Int {
		var sum = 0;
		for (i in start...end) {
			sum += i;
		}
		return sum;
	}
	
	// While loop
	public function factorial(n: Int): Int {
		var result = 1;
		var i = n;
		while (i > 1) {
			result *= i;
			i--;
		}
		return result;
	}
	
	// Switch statement
	public function dayName(day: Int): String {
		return switch (day) {
			case 1: "Monday";
			case 2: "Tuesday";
			case 3: "Wednesday";
			case 4: "Thursday";
			case 5: "Friday";
			case 6: "Saturday";
			case 7: "Sunday";
			default: "Invalid";
		}
	}
	
	// Main entry point
	public static function main() {
		var instance = new Main(10);
		trace(greet("World"));
		trace(instance.calculate(5, 3));
		trace(instance.checkValue(-5));
		trace(instance.sumRange(1, 10));
		trace(instance.factorial(5));
		trace(instance.dayName(3));
	}
}