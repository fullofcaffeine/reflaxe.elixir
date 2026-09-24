/**
 * Test case for enum extraction variable usage
 * 
 * This test verifies that the compiler correctly handles unused enum
 * extraction variables by prefixing them with underscore when they're
 * not used in the case body.
 * 
 * Expected behavior:
 * - When enum parameters are extracted but not used, the generated
 *   variables should have underscore prefixes (_g, _value, etc.)
 * - When enum parameters are used, they should not have underscores
 * - This prevents Elixir compilation warnings about unused variables
 * - Compiler-created switch_result_N names restart in each function. Their
 *   suffix must not depend on unrelated functions that a warm Haxe server may
 *   reuse instead of compiling again.
 */
enum Result<T, E> {
	Ok(value:T);
	Error(error:E);
}

enum Option<T> {
	Some(value:T);
	None;
}

enum TreeNode<T> {
	Leaf;
	Node(left:TreeNode<T>, value:T, right:TreeNode<T>);
}

class Main {
	static function main() {
		assertText(testUnusedExtraction(Ok("hello")), "success");
		assertText(testUnusedExtraction(Error("ignored")), "failure");
		assertText(testUsedExtraction(Ok("world")), "Got: world");
		assertText(testUsedExtraction(Error("offline")), "Error: offline");
		assertText(testMixedUsage(Ok(42)), "Number is 42");
		assertText(testMixedUsage(Error("ignored")), "Got an error");
		assertText(testNestedExtraction(Some(Ok(123))), "Nested value: 123");
		assertText(testNestedExtraction(Some(Error("ignored"))), "Nested error");
		assertText(testNestedExtraction(None), "Nothing");
		assertText(testMultipleExtractions(Node(Leaf, 42, Leaf)), "Value: 42");
		assertText(testMultipleExtractions(Leaf), "Empty");
		// Each nested node contributes its own value: 1 + 2 + 3.
		if (testTreeExtraction(Node(Node(Leaf, 1, Leaf), 2, Node(Leaf, 3, Leaf))) != 6)
			throw "Nested tree extraction must preserve all three independent bindings";
		if (testTreeExtraction(Node(Leaf, 7, Leaf)) != 7 || testTreeExtraction(Leaf) != 0)
			throw "Tree fallback branches must preserve their results";
		if (!testOptionExtraction(Some("test")) || testOptionExtraction(None))
			throw "Unused option payloads must not change constructor selection";
	}

	static function assertText(actual:String, expected:String):Void {
		if (actual != expected)
			throw 'Expected $expected, got $actual';
	}

	/**
	 * Test case where extracted values are not used
	 * Expected: Variables should be prefixed with underscore
	 */
	static function testUnusedExtraction(result:Result<String, String>):String {
		return switch (result) {
			case Ok(value):
				// value is extracted but not used
				"success";
			case Error(msg):
				// msg is extracted but not used
				"failure";
		}
	}

	/**
	 * Test case where extracted values are used
	 * Expected: Variables should NOT have underscore prefix
	 */
	static function testUsedExtraction(result:Result<String, String>):String {
		return switch (result) {
			case Ok(value):
				// value is used in the return
				"Got: " + value;
			case Error(msg):
				// msg is used in the return
				"Error: " + msg;
		}
	}

	/**
	 * Test case where some values are used and some are not
	 * Expected: Only unused variables should have underscore
	 */
	static function testMixedUsage(result:Result<Int, String>):String {
		return switch (result) {
			case Ok(num):
				// num is used
				"Number is " + Std.string(num);
			case Error(err):
				// err is not used
				"Got an error";
		}
	}

	/**
	 * Test nested enum extraction
	 * Expected: Proper handling of nested patterns
	 */
	static function testNestedExtraction(opt:Option<Result<Int, String>>):String {
		return switch (opt) {
			case Some(result):
				switch (result) {
					case Ok(value):
						// value is used
						"Nested value: " + Std.string(value);
					case Error(e):
						// e is not used
						"Nested error";
				}
			case None:
				"Nothing";
		}
	}

	/**
	 * Test multiple extractions in one pattern
	 * Expected: Each variable handled independently based on usage
	 */
	static function testMultipleExtractions(node:TreeNode<Int>):String {
		return switch (node) {
			case Node(left, value, right):
				// Only value is used, left and right should have underscores
				"Value: " + Std.string(value);
			case Leaf:
				"Empty";
		}
	}

	/**
	 * Test complex tree extraction patterns
	 * Expected: Correct underscore prefixing for unused extracted values
	 */
	static function testTreeExtraction(tree:TreeNode<Int>):Int {
		return switch (tree) {
			case Node(Node(_, leftVal, _), centerVal, Node(_, rightVal, _)):
				// Using all three values
				leftVal + centerVal + rightVal;
			case Node(left, value, right):
				// Only using value
				value;
			case Leaf:
				0;
		}
	}

	/**
	 * Test with Option type
	 * Expected: Unused Some values should have underscore
	 */
	static function testOptionExtraction(opt:Option<String>):Bool {
		return switch (opt) {
			case Some(val):
				// val is not used
				true;
			case None:
				false;
		}
	}
}
