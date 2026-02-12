package;

import HXX;

typedef Assigns = {
	var ok:Bool;
}

@:hxx_strict_phx_events
class Main {
	public static function render(assigns:Assigns):String {
		return HXX.hxx('<button phx-click=${EventName.Save}>Save</button>');
	}

	public static function main() {}
}
