enum Branch {
	Empty;
	Node(left:Branch, value:Int, right:Branch);
}

/** Nested uses of the same constructor must keep distinct receiver identities. */
class Main {
	static var reads:Int = 0;

	static function observe(tree:Branch):Branch {
		reads = reads + 1;
		return tree;
	}

	static function observedSum(tree:Branch):Int {
		return switch (observe(tree)) {
			case Node(Node(_, leftValue, _), centerValue, Node(_, rightValue, _)):
				leftValue + centerValue + rightValue;
			case Node(_, value, _): value;
			case Empty: 0;
		};
	}

	static function selectedSum(tree:Branch):Int {
		return switch (tree) {
			case Node(Node(_, leftValue, _), centerValue, Node(_, rightValue, _)):
				leftValue + centerValue + rightValue;
			case Node(_, value, _): value;
			case Empty: 0;
		};
	}

	static function expect(tree:Branch, expected:Int):Void {
		if (selectedSum(tree) != expected)
			throw "Nested constructor bindings or fallback value changed";
	}

	static function main():Void {
		EnumSubjectProbe.main();
		EnumDecoderSubjectProbe.main();
		EnumPayloadProbe.main();
		expect(Node(Node(Empty, 11, Empty), 21, Node(Empty, 31, Empty)), 63);
		expect(Node(Empty, 21, Node(Empty, 31, Empty)), 21);
		expect(Node(Node(Empty, 11, Empty), 21, Empty), 21);
		expect(Node(Empty, -7, Empty), -7);
		expect(Empty, 0);
		reads = 0;
		if (observedSum(Node(Node(Empty, 11, Empty), 21, Node(Empty, 31, Empty))) != 63 || reads != 1)
			throw "Nested enum matching must evaluate its receiver once";
		if (observedSum(Node(Empty, 9, Empty)) != 9 || reads != 2)
			throw "Separate enum receiver calls must remain separate evaluations";
		if (observedSum(Empty) != 0 || reads != 3)
			throw "Enum fallback must evaluate its receiver once";
	}
}
