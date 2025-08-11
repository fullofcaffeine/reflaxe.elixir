package;

/**
 * Arrays test case
 * Tests array operations and list comprehensions
 */
class Main {
	// Array creation and access
	public static function basicArrayOps(): Void {
		// Array literal
		var numbers = [1, 2, 3, 4, 5];
		trace(numbers[0]); // First element
		trace(numbers.length); // Length
		
		// Array modification
		numbers.push(6);
		numbers.unshift(0);
		var popped = numbers.pop();
		var shifted = numbers.shift();
		trace('Popped: $popped, Shifted: $shifted');
		
		// Array of different types
		var mixed: Array<Dynamic> = [1, "hello", true, 3.14];
		trace(mixed);
	}
	
	// Array iteration
	public static function arrayIteration(): Void {
		var fruits = ["apple", "banana", "orange", "grape"];
		
		// For loop
		for (fruit in fruits) {
			trace('Fruit: $fruit');
		}
		
		// For with index
		for (i in 0...fruits.length) {
			trace('$i: ${fruits[i]}');
		}
		
		// While iteration
		var i = 0;
		while (i < fruits.length) {
			trace('While: ${fruits[i]}');
			i++;
		}
	}
	
	// Array methods
	public static function arrayMethods(): Void {
		var numbers = [1, 2, 3, 4, 5];
		
		// Map
		var doubled = numbers.map(n -> n * 2);
		trace('Doubled: $doubled');
		
		// Filter
		var evens = numbers.filter(n -> n % 2 == 0);
		trace('Evens: $evens');
		
		// Concat
		var more = [6, 7, 8];
		var combined = numbers.concat(more);
		trace('Combined: $combined');
		
		// Join
		var words = ["Hello", "World", "from", "Haxe"];
		var sentence = words.join(" ");
		trace('Sentence: $sentence');
		
		// Reverse
		var reversed = numbers.copy();
		reversed.reverse();
		trace('Reversed: $reversed');
		
		// Sort
		var unsorted = [3, 1, 4, 1, 5, 9, 2, 6];
		unsorted.sort((a, b) -> a - b);
		trace('Sorted: $unsorted');
	}
	
	// Array comprehensions
	public static function arrayComprehensions(): Void {
		// Simple comprehension
		var squares = [for (i in 1...6) i * i];
		trace('Squares: $squares');
		
		// Comprehension with condition
		var evenSquares = [for (i in 1...10) if (i % 2 == 0) i * i];
		trace('Even squares: $evenSquares');
		
		// Nested comprehension
		var pairs = [for (x in 1...4) for (y in 1...4) if (x != y) {x: x, y: y}];
		trace('Pairs: $pairs');
	}
	
	// Multi-dimensional arrays
	public static function multiDimensional(): Void {
		// 2D array
		var matrix = [
			[1, 2, 3],
			[4, 5, 6],
			[7, 8, 9]
		];
		
		trace('Matrix element [1][2]: ${matrix[1][2]}');
		
		// Iterate 2D array
		for (row in matrix) {
			for (elem in row) {
				trace('Element: $elem');
			}
		}
		
		// Create dynamic 2D array
		var grid = [for (i in 0...3) [for (j in 0...3) i * 3 + j]];
		trace('Grid: $grid');
	}
	
	// Array as function parameter and return
	public static function processArray(arr: Array<Int>): Array<Int> {
		return arr.map(x -> x * x).filter(x -> x > 10);
	}
	
	// Generic array function
	public static function firstN<T>(arr: Array<T>, n: Int): Array<T> {
		return [for (i in 0...Std.int(Math.min(n, arr.length))) arr[i]];
	}
	
	public static function main() {
		trace("=== Basic Array Operations ===");
		basicArrayOps();
		
		trace("\n=== Array Iteration ===");
		arrayIteration();
		
		trace("\n=== Array Methods ===");
		arrayMethods();
		
		trace("\n=== Array Comprehensions ===");
		arrayComprehensions();
		
		trace("\n=== Multi-dimensional Arrays ===");
		multiDimensional();
		
		trace("\n=== Array Functions ===");
		var result = processArray([1, 2, 3, 4, 5]);
		trace('Processed: $result');
		
		var first3 = firstN(["a", "b", "c", "d", "e"], 3);
		trace('First 3: $first3');
	}
}