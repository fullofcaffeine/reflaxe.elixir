package implementations;

import protocols.CommandRenderable;

/**
 * Protocol implementation for String values.
 */
@:impl
class StringCommandRenderable {
	public function new() {}

	public function renderCommand(value:String):String {
		return "run:" + value;
	}

	public function renderSummary(value:String):String {
		return "command(" + value.length + " chars)";
	}
}
