import HXX;

typedef CardAssigns = {
	title:String,
	inner_content:String
}

@:component
@:hxx_mode("balanced")
class Components {
	@:component
	public static function card(assigns:CardAssigns):String {
		return HXX.hxx('<div>${assigns.title}${assigns.inner_content}</div>');
	}
}

@:component
class Main {
	public static function render(assigns:{}):String {
		// Inline markup preserves the map value instead of stringifying it in Haxe.
		return <div><.card title=${{foo: "bar"}}>Hi</.card></div>;
	}

	public static function main():Void {}
}
