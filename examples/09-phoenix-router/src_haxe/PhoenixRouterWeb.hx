package;

/**
 * PhoenixRouterWeb module for router/controller helpers in this example app.
 */
// @:phoenixWebModule: generates the `AppWeb` helper module used by Phoenix `use AppWeb, ...` calls.
@:phoenixWebModule
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("PhoenixRouterWeb")
class PhoenixRouterWeb {
	public static function static_paths():Array<String> {
		return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
	}
}
