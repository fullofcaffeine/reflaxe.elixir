package;

import HXX.*;

typedef Assigns = {
	var count:Int;
}

@:liveview
@:hxx_mode("tsx")
class Main {
	public static function render(assigns:Assigns):String {
		// TSX mode should reject string-based HXX templates.
		return hxx('<div>${assigns.count}</div>');
	}

	public static function main() {}
}
