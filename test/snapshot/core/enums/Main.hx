package;

/**
 * Enum test case
 * Tests enum compilation and pattern matching
 */

// Simple enum
enum Color {
	Red;
	Green;
	Blue;
	RGB(r: Int, g: Int, b: Int);
}

// Enum with type parameters
enum Option<T> {
	Some(value: T);
	None;
}

// Recursive enum
enum Tree<T> {
	Leaf(value: T);
	Node(left: Tree<T>, right: Tree<T>);
}

class Main {
	// Pattern matching on simple enum
	public static function colorToString(color: Color): String {
		return switch (color) {
			case Red: "red";
			case Green: "green";
			case Blue: "blue";
			case RGB(r, g, b): 'rgb($r, $g, $b)';
		}
	}
	
	// Pattern matching with Option
	public static function getValue<T>(opt: Option<T>, defaultValue: T): T {
		return switch (opt) {
			case Some(v): v;
			case None: defaultValue;
		}
	}
	
	// Nested pattern matching
	public static function treeSum(tree: Tree<Int>): Int {
		return switch (tree) {
			case Leaf(value): value;
			case Node(left, right): treeSum(left) + treeSum(right);
		}
	}
	
	// Guard conditions in pattern matching
	public static function describeRGB(color: Color): String {
		return switch (color) {
			case RGB(r, g, b) if (r > 200 && g < 50 && b < 50): "mostly red";
			case RGB(r, g, b) if (g > 200 && r < 50 && b < 50): "mostly green";
			case RGB(r, g, b) if (b > 200 && r < 50 && g < 50): "mostly blue";
			case RGB(r, g, b): "mixed color";
			case _: "not RGB";
		}
	}
	
	// Multiple pattern matching
	public static function compareTrees<T>(t1: Tree<T>, t2: Tree<T>): Bool {
		return switch ([t1, t2]) {
			case [Leaf(v1), Leaf(v2)]: v1 == v2;
			case [Node(l1, r1), Node(l2, r2)]: 
				compareTrees(l1, l2) && compareTrees(r1, r2);
			case _: false;
		}
	}
	
	public static function main() {
		// Test simple enum
		var color = RGB(255, 128, 0);
		trace(colorToString(color));
		
		// Test Option
		var some = Some("Hello");
		var none = None;
		trace(getValue(some, "default"));
		trace(getValue(none, "default"));
		
		// Test Tree
		var tree = Node(
			Leaf(1),
			Node(Leaf(2), Leaf(3))
		);
		trace(treeSum(tree));
		
		// Test guards
		trace(describeRGB(RGB(250, 10, 10)));
		
		// Test comparison
		var tree2 = Node(Leaf(1), Node(Leaf(2), Leaf(3)));
		trace(compareTrees(tree, tree2));
	}
}