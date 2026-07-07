package;

import haxe.EntryPoint;

class Main {
	public static function main():Void {
		// Negative test: EntryPoint.threadCount belongs to Haxe's target-owned main-loop bridge.
		// The Elixir target uses BEAM lifecycle/event-loop primitives instead.
		var count = EntryPoint.threadCount;
		trace(count);
	}
}
