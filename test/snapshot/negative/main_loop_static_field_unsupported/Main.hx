package;

import haxe.MainLoop;

class Main {
	public static function main():Void {
		// Negative test: MainLoop.threadCount delegates to Haxe's target-owned EntryPoint bridge.
		// The Elixir target uses BEAM lifecycle/event-loop primitives instead.
		var count = MainLoop.threadCount;
		trace(count);
	}
}
