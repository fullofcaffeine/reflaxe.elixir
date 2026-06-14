package;

import HXX;

typedef Assigns = {
	var ok:Bool;
}

@:hxx_mode("balanced")
class Main {
	public static function render(assigns:Assigns):String {
		return HXX.hxx('<.card title="Hello"><:header label="Hello">Hi</:header></.card>');
	}

	public static function main() {}
}
