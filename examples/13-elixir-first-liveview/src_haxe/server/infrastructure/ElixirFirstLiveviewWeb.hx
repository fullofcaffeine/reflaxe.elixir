package server.infrastructure;

/**
 * ElixirFirstLiveviewWeb module providing Phoenix framework helpers.
 */
@:phoenixWebModule
@:native("ElixirFirstLiveviewWeb")
class ElixirFirstLiveviewWeb {
	public static function static_paths():Array<String> {
		return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
	}
}
