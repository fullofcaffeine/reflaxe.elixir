package probe;

import probe.Shared.value;
import elixir.types.Term;
import elixir.types.TermDecoder;

/** A shared typed reader calls both module-level code and a root stdlib helper. */
class Reader<T> {
	public function new() {}

	public function run(input:Term):Int {
		return switch TermDecoder.asString(input) {
			case Ok(_): value();
			case Error(_): -1;
		};
	}
}
