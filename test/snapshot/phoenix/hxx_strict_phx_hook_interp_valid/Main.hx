package;

import HXX;

typedef Assigns = {
	var ok:Bool;
}

@:hxx_mode("balanced")
class Main {
	public static function render(assigns:Assigns):String {
		return HXX.hxx('<div id="hook" phx-hook=${HookName.Known}></div>');
	}

	public static function main() {}
}
