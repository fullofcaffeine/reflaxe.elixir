package;

import haxe.ds.ArraySort;

class Holder {
	public var values:Array<Int>;

	public function new(values:Array<Int>) {
		this.values = values;
	}
}

class Main {
	public static function main():Void {
		var holder = new Holder([3, 1, 2]);

		// Negative test: the Elixir target can preserve ArraySort Void mutation
		// semantics only when the array expression is a local binding.
		ArraySort.sort(holder.values, (left, right) -> left - right);
	}
}
