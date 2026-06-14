package;

import HXX;

typedef Assigns = {
	var ok:Bool;
}

@:native("AppWeb.SomeLive")
@:hxx_mode("balanced")
class Main {
	public static function render(assigns:Assigns):String {
		// Component assigns are wrapped in phoenix.types.Assigns<T>, but strict component
		// resolution + prop checks should still work.
		return HXX.hxx('<.card title="Hello">Hi</.card>');
	}

	public static function main() {}
}
