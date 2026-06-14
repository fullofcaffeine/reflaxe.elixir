package;

import HXX;

@:hxxHtmlTags
@:hxx_mode("balanced")
class CustomTags {
	@:hxxTagAttrs(["enabled", "variant"])
	@:hxxTagAttrKinds({enabled: "bool", variant: "string"})
	public static final MyWidget = "my-widget";
}

typedef Assigns = {
	var enabled:Bool;
}

@:hxx_mode("balanced")
class Main {
	public static function render(assigns:Assigns):String {
		// Should compile under -D hxx_strict_html because my-widget is registered via @:hxxHtmlTags.
		return HXX.hxx('<my-widget enabled=${assigns.enabled} variant="primary"></my-widget>');
	}

	public static function main() {}
}
