package;

typedef Assigns = {
	var ok:Bool;
}

@:hxx_inline_markup
class Main {
	public static function render(assigns:Assigns):String {
		return <div id="hook" phx-hook=${HookName.Known}></div>;
	}

	public static function main() {}
}
