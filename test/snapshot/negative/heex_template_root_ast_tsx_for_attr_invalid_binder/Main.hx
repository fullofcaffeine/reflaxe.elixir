package;

typedef Item = {
	var name:String;
}

typedef Assigns = {
	var items:Array<Item>;
}

@:liveview
@:hxx_mode("tsx")
class Main {
	public static function render(assigns:Assigns):String {
		// Should fail: binder must be a plain identifier under TSX :for.
		return <ul>
            <li :for ${item.name in assigns.items}>${item.name}</li>
        </ul>;
	}

	public static function main() {}
}
