package;

import phoenix.hxx.HeexTemplate;

typedef Assigns = {
	var name:String;
}

@:liveview
@:hxx_mode("tsx")
class Main {
	public static function render(assigns:Assigns):String {
		// TSX mode should reject `#{...}` markers because they bypass Haxe typing.
		return HeexTemplate.root('<div>#{assigns.name}</div>');
	}

	public static function main() {}
}
