package;

import HXX;

typedef Assigns = {
	var ok:Bool;
}

@:hxx_strict_html
class Main {
	public static function render(assigns:Assigns):String {
		// Should fail under @:hxx_strict_html: unknown/custom HTML tag.
		return HXX.hxx('<my-widget enabled=${assigns.ok}></my-widget>');
	}

	public static function main() {}
}
