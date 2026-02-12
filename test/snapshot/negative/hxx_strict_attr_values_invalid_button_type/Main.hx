package;

import HXX;

typedef Assigns = {
	var ok:Bool;
}

@:hxx_strict_attr_values
class Main {
	public static function render(assigns:Assigns):String {
		// Should fail under @:hxx_strict_attr_values: invalid button type literal.
		return HXX.hxx('<button type="launch">Launch</button>');
	}

	public static function main() {}
}
