package;

import HXX;

typedef Assigns = {
	var count:Int;
}

@:hxx_mode("balanced")
class Main {
	public static function render(assigns:Assigns):String {
		// Should fail by default: raw HEEx markers bypass HXX typing.
		return HXX.hxx('<div>count: <%= @count %></div>');
	}

	public static function main() {}
}
