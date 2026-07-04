package;

import haxe.ds.ListSort;

class Node {
	public var rank:Int;
	public var next:Node;
	public var prev:Node;

	public function new(rank:Int) {
		this.rank = rank;
	}
}

class Main {
	public static function main():Void {
		var first = new Node(2);
		var second = new Node(1);
		first.next = second;
		second.prev = first;

		// Negative test: ListSort mutates arbitrary linked-node fields in place.
		// The Elixir target must reject this instead of emitting broken immutable-struct updates.
		ListSort.sort(first, (left, right) -> left.rank - right.rank);
	}
}
