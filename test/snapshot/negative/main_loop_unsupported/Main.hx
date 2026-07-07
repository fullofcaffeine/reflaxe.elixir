package;

import haxe.MainLoop;

class Main {
	public static function main():Void {
		// Negative test: MainLoop owns Haxe's process-level pending event queue.
		// The Elixir target uses BEAM lifecycle/event-loop primitives instead.
		MainLoop.add(function() {
			trace("not reached");
		});
	}
}
