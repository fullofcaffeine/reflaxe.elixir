package;

typedef Assigns = {
	var count:Int;
}

@:liveview
@:allow_heex
@:hxx_mode("tsx")
class Main {
	public static function render(assigns:Assigns):String {
		// Even without raw `<% ... %>`, TSX mode should reject the allow_heex escape hatch.
		return <div>${assigns.count}</div>;
	}

	public static function main() {}
}
