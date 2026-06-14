package;

import HXX;

typedef Assigns = {
	var count:Int;
}

@:hxx_mode("balanced")
class Main {
	@:allow_heex
	public static function render(assigns:Assigns):String {
		// Allowed via explicit opt-in. This is an escape hatch and should be avoided for most code.
		return HXX.hxx('<div>count: <%= @count %></div>');
	}

	public static function main() {}
}
