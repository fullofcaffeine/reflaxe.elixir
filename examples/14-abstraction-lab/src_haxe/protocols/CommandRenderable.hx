package protocols;

import elixir.types.Term;

/**
 * Protocol contract for values that can render command text.
 */
@:protocol
class CommandRenderable {
	public function renderCommand(value:Term):String {
		throw "Protocol method should be implemented";
	}

	public function renderSummary(value:Term):String {
		throw "Protocol method should be implemented";
	}
}
