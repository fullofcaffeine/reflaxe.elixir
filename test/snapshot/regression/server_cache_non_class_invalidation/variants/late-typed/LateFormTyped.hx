package;

import HXX;

/**
 * Names `phoenix.Phoenix.Form` in its assigns and renders a plain template.
 * A fresh build has no use for `StringTools` beyond the helpers that the
 * generated code calls. Before the fix, Reflaxe asked Haxe for `StringTools`
 * during generation, and the next warm request typed it and its iterator
 * modules as part of the program.
 */
@:hxx_mode("balanced")
class LateForm {
	public static function render(assigns:{form:phoenix.Phoenix.Form<elixir.types.Term>}):String {
		return HXX.hxx('<span>plain</span>');
	}
}
