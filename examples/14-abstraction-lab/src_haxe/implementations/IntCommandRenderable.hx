package implementations;

import protocols.CommandRenderable;

/**
 * Protocol implementation for Int values.
 */
@:impl
class IntCommandRenderable {
	public function new() {}

	public function renderCommand(value:Int):String {
		return "retry:" + value;
	}

	public function renderSummary(value:Int):String {
		return "retry attempt #" + value;
	}
}
