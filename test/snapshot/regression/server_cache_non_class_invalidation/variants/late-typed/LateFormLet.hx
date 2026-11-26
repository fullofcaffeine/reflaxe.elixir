package;

import HXX;

/**
 * Uses `<.form :let={f}>` and nothing else of `phoenix.Phoenix`. Before the
 * fix, the template linter asked Haxe for `phoenix.Phoenix.Form` during
 * generation, and each later warm request typed more `phoenix` and `ecto`
 * modules as part of the program.
 */
@:hxx_mode("balanced")
class LateForm {
	public static function render(assigns:{form:elixir.types.Term}):String {
		return HXX.hxx('<.form for={@form} :let={f}><span>#{f.id}</span></.form>');
	}
}
