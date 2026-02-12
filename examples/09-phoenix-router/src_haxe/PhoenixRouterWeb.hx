package;

/**
 * PhoenixRouterWeb module for router/controller helpers in this example app.
 */
@:phoenixWebModule
@:native("PhoenixRouterWeb")
class PhoenixRouterWeb {
	public static function static_paths():Array<String> {
		return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
	}
}
