/**
 * Infrastructure Variable Naming Test
 * 
 * Tests that infrastructure variables (_g, _g1) used in loop desugaring
 * are properly tracked and initialized in reduce_while calls.
 * 
 * Bug: Variables are tracked with underscore prefix ("_g") but looked up
 * without it ("g") due to ElixirNaming.toVarName stripping the underscore.
 */
class Main {
	static function main() {
		testSimpleLoop();
		testStringIteration();
		testDistinctComprehensionState();
	}

	/** The output list and range length are distinct compiler-generated locals. */
	static function reorder(value:{items:Array<Int>}, first:Int, second:Int):Array<Int> {
		if (first < 0 || second < 0 || first >= value.items.length || second >= value.items.length)
			return value.items;
		final next = [
			for (position in 0...value.items.length) value.items[position == first ? second : position == second ? first : position]
		];
		return next;
	}

	static function testDistinctComprehensionState():Void {
		final values = [10, 20, 30, 40];
		final moved = reorder({items: values}, 1, 2);
		if (moved.join(",") != "10,30,20,40" || values.join(",") != "10,20,30,40")
			throw "Comprehension merged its output list with its range length.";
		if (reorder({items: []}, 0, 0).length != 0 || reorder({items: [7]}, 0, 0).join(",") != "7")
			throw "Comprehension changed its empty or singleton result.";
	}

	// Test 1: Simple counting loop with infrastructure var _g
	static function testSimpleLoop():Void {
		for (i in 0...3) {
			trace(i);
		}
	}

	// Test 2: String iteration with infrastructure vars _g and _g1
	static function testStringIteration():String {
		var input = "ABC";
		var result = "";

		for (i in 0...input.length) {
			var c = input.charAt(i);
			result += c;
		}

		return result;
	}
}
