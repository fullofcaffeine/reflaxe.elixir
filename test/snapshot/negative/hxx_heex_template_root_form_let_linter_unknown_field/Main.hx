package;

import phoenix.hxx.HeexTemplate;

/**
 * The template linter must check a `<.form :let={f}>` value against
 * `phoenix.Phoenix.Form` for a `HeexTemplate.root(...)` template too, also when
 * nothing else in the program uses `phoenix.Phoenix`. Expected error:
 * HEEx :let type error ... "nope_field".
 */
typedef Assigns = {
	var form:elixir.types.Term;
}

@:hxx_mode("balanced")
class Main {
	public static function render(assigns:Assigns):String {
		return HeexTemplate.root('<.form for={@form} :let={f}><span>#{f.nope_field}</span></.form>');
	}

	public static function main() {}
}
