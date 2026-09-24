import haxe.extern.EitherType;
import phoenix.JS;

typedef CardAssigns = {
	final title:String;
	final label:EitherType<String, Bool>;
	final js:JS;
	final details:{final count:Int;};
}

typedef RenderAssigns = {
	final js:JS;
}

// A secondary type belongs to Main's module, not a separate Main.Components module.

@:component
@:native("MyAppWeb.Components")
class Components {
	@:component
	public static function card(assigns:CardAssigns):String {
		return <p>${assigns.title}</p>;
	}
}

@:component
class Main {
	public static function render(assigns:RenderAssigns):String {
		return <div><MyAppWeb.Components.card title="Hello" label=${true} js=${assigns.js} details=${{count: 2}} /></div>;
	}

	public static function main():Void {}
}
