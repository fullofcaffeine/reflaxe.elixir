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
		return <ul data-testid="rows">
            <li :for ${item in assigns.items} class="row-sugar">${item.name}</li>
            <li :for=${item in assigns.items} class="row-equals">${item.name}</li>
        </ul>;
	}

	public static function main() {}
}
