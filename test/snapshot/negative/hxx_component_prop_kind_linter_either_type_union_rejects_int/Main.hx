import HXX;
import haxe.extern.EitherType;

typedef CardAssigns = {
	label:EitherType<String, Bool>,
	inner_content:String
}

@:component
@:hxx_mode("balanced")
class Components {
	@:component
	public static function card(assigns:CardAssigns):String {
		return HXX.hxx('<div>${assigns.label}${assigns.inner_content}</div>');
	}
}

@:component
class Main {
	public static function render(assigns:{}):String {
		// Should fail: EitherType<String, Bool> does not accept Int.
		return <div><.card label=${123}>Hi</.card></div>;
	}

	public static function main():Void {}
}
