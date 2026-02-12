package;

import HXX;

@:hxxHtmlTags
class CustomTags {
	@:hxxTagAttrs(["enabled"])
	@:hxxTagAttrKinds({enabled: "bool"})
	public static final MyWidget = "my-widget";
}

typedef Assigns = {
	var ok:Bool;
}

class Main {
	public static function render(assigns:Assigns):String {
		// Should fail: enabled is declared as bool, but passed as a string literal.
		return HXX.hxx('<my-widget enabled="yes"></my-widget>');
	}

	public static function main() {}
}
