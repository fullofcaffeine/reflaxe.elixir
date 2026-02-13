package server.infrastructure;

/**
 * ElixirFirstLiveviewWeb HTTP endpoint.
 */
@:native("ElixirFirstLiveviewWeb.Endpoint")
@:endpoint
@:appName("elixir_first_liveview")
class Endpoint {
	public static function static_paths():Array<String> {
		return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
	}
}
