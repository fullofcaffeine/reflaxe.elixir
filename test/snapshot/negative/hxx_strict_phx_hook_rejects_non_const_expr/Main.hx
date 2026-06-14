package;

import HXX;

typedef Assigns = {
	var hook:String;
}

@:hxx_mode("balanced")
class Main {
	public static function render(assigns:Assigns):String {
		// Should fail under -D hxx_strict_phx_hook: values must come from a hook registry constant.
		return HXX.hxx('<div id="hook" phx-hook={@hook}></div>');
	}

	public static function main() {}
}
