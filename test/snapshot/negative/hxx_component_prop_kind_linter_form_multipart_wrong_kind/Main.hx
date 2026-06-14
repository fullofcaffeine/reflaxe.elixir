package;

import HXX;

typedef Assigns = {
	var ok:Bool;
}

@:hxx_mode("balanced")
class Main {
	public static function render(assigns:Assigns):String {
		// Should fail: `multipart` expects Bool, not a string.
		return HXX.hxx('<.form for=${{foo: "bar"}} multipart="no">Hi</.form>');
	}

	public static function main() {}
}
