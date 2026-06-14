package;

import HXX;

typedef Assigns = {
	var ok:Bool;
}

@:hxx_mode("balanced")
class Main {
	public static function render(assigns:Assigns):String {
		// Should fail: slot tags must be direct children of a component tag.
		return HXX.hxx('<div><:header>Hi</:header></div>');
	}

	public static function main() {}
}
