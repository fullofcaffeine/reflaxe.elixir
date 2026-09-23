import HXX;
import phoenix.JS;

typedef CardAssigns = {
	js:JS,
	inner_content:String
}

@:component
@:hxx_mode("balanced")
class Components {
	@:component
	public static function card(assigns:CardAssigns):String {
		return HXX.hxx('<div>${assigns.inner_content}</div>');
	}
}

@:component
class Main {
	public static function render(assigns:{}):String {
		// Should fail: `js` expects a JS struct-like value (map), not a string.
		return <div><.card js="save">Hi</.card></div>;
	}

	public static function main():Void {}
}
