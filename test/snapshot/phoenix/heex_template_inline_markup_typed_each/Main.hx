package;

import phoenix.hxx.H;

typedef Item = {
	var name:String;
}

typedef Assigns = {
	var items:Array<Item>;
}

@:liveview
class Main {
	public static function render(assigns:Assigns):String {
		return <ul data-testid="items">
            ${H.each(assigns.items, (item) -> <li>${item.name}</li>)}
        </ul>;
	}

	public static function main() {}
}
