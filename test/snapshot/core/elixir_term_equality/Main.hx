package;

import elixir.types.Term;

class Main {
	public static function same(left:Term, right:Term):Bool {
		return left == right;
	}

	public static function different(left:Term, right:Term):Bool {
		return left != right;
	}

	public static function nonNull(value:Term):Bool {
		return value != null;
	}
}
