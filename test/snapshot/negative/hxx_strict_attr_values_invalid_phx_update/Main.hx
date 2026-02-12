package;

import HXX;

typedef Assigns = {
	var ok:Bool;
}

@:hxx_strict_attr_values
class Main {
	public static function render(assigns:Assigns):String {
		// Should fail under @:hxx_strict_attr_values: invalid phx-update literal.
		return HXX.hxx('<div phx-update="merge"></div>');
	}

	public static function main() {}
}
