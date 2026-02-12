package;

import HXX;
import elixir.types.Term;

typedef Assigns = {
	var changeset:Term;
}

class Main {
	public static function render(assigns:Assigns):String {
		// `f` is intentionally unused; the compiler should rewrite it to `_f` in emitted ~H.
		return HXX.hxx('<.form :let={f} for={@changeset}><span>OK</span></.form>');
	}

	public static function main() {}
}
