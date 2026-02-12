package;

typedef Assigns = {
	var count:Int;
}

@:liveview
class Main {
	@:allow_heex
	public static function render(assigns:Assigns):String {
		return <div>count: <%= @count %></div>;
	}

	public static function main() {}
}
