package;

import HXX;

typedef Assigns = {
	var ok:Bool;
}

@:hxx_strict_phx_hook
class Main {
	public static function render(assigns:Assigns):String {
		// Should fail under @:hxx_strict_phx_hook: literal phx-hook values are disallowed.
		return HXX.hxx('<div id="hook-root" phx-hook="UnknownHook">Connected</div>');
	}

	public static function main() {}
}
