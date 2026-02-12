package;

import HXX.*;

typedef Assigns = {
	var count:Int;
}

@:liveview
@:hxx_mode("metal")
class Main {
	public static function render(assigns:Assigns):String {
		// Metal mode: allow raw HEEx markers without needing @:allow_heex.
		return hxx('<div>count: <%= @count %></div>');
	}

	public static function main() {}
}
