package;

import HXX;

typedef Assigns = {
	var any:Bool;
}

@:hxx_mode("balanced")
class Main {
	public static function render(assigns:Assigns):String {
		// Should fail: `required` expects a boolean-ish value, not an arbitrary string.
		return HXX.hxx('<div><input required="yes" /></div>');
	}

	public static function main() {}
}
