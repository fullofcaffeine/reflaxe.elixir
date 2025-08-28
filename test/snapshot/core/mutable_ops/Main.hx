package;

/**
 * Test for mutable operations like +=, -=, etc.
 */
class Main {
	public static function main() {
		testMutableOps();
		testVariableReassignment();
		testLoopCounters();
	}
	
	static function testMutableOps(): Void {
		// Test compound assignment operators
		var x = 10;
		x += 5;  // Should become: x = x + 5
		trace('After +=: $x');
		
		x -= 3;  // Should become: x = x - 3
		trace('After -=: $x');
		
		x *= 2;  // Should become: x = x * 2
		trace('After *=: $x');
		
		// Division creates Float, so skip /= for Int
		// x /= 4;  // Would create Float from Int
		// trace('After /=: $x');
		
		x %= 3;  // Should become: x = x % 3
		trace('After %=: $x');
		
		// Test with strings
		var str = "Hello";
		str += " World";  // Should become: str = str <> " World"
		trace('String concat: $str');
		
		// Test with arrays
		var arr = [1, 2, 3];
		// arr += [4, 5]; // This doesn't exist in Haxe
		arr = arr.concat([4, 5]); // Proper way
		trace('Array: $arr');
	}
	
	static function testVariableReassignment(): Void {
		// Test simple reassignment
		var count = 0;
		count = count + 1;
		count = count + 1;
		count = count + 1;
		trace('Count after reassignments: $count');
		
		// Test in conditional
		var value = 5;
		if (value > 0) {
			value = value * 2;
		} else {
			value = value * -1;
		}
		trace('Value after conditional: $value');
		
		// Test multiple reassignments
		var result = 1;
		result = result * 2;
		result = result + 10;
		result = result - 5;
		trace('Result: $result');
	}
	
	static function testLoopCounters(): Void {
		// Test increment in while loop
		var i = 0;
		while (i < 5) {
			trace('While loop i: $i');
			i++;  // Should become: i = i + 1
		}
		
		// Test decrement in while loop
		var j = 5;
		while (j > 0) {
			trace('While loop j: $j');
			j--;  // Should become: j = j - 1
		}
		
		// Test compound assignment in loop
		var sum = 0;
		var k = 1;
		while (k <= 5) {
			sum += k;  // Should become: sum = sum + k
			k++;
		}
		trace('Sum: $sum');
		
		// Test nested loops with counters
		var total = 0;
		var x = 0;
		while (x < 3) {
			var y = 0;
			while (y < 3) {
				total += 1;
				y++;
			}
			x++;
		}
		trace('Total from nested loops: $total');
	}
}