package abstractions;

import elixir.Kernel;
import elixir.types.Term;

/**
 * Typed wrapper around low-level process primitives in Kernel.
 *
 * This keeps call sites explicit and typed while still compiling to direct
 * Elixir runtime primitives.
 */
class ProcessBoundary {
	public static function currentProcessId():Term {
		return Kernel.self();
	}

	public static function currentNodeName():String {
		return Kernel.toString(Kernel.nodeOf(currentProcessId()));
	}

	public static function sendIfPid(destination:Term, message:Term):Bool {
		if (!Kernel.isPid(destination))
			return false;

		Kernel.send(destination, message);
		return true;
	}

	public static function sendToSelf(message:Term):Term {
		return Kernel.send(currentProcessId(), message);
	}

	public static function termType(term:Term):String {
		return Kernel.typeOf(term);
	}
}
