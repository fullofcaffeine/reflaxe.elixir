package;

import haxe.EntryPoint;

class Main {
	public static function main():Void {
		// Negative test: EntryPoint is Haxe's process main-loop bridge.
		// The Elixir target uses BEAM lifecycle/event-loop primitives instead.
		EntryPoint.runInMainThread(function() {
			trace("not reached");
		});
	}
}
