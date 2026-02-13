package server.infrastructure;

/**
 * PhoenixHaxeExampleWeb HTTP endpoint.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("PhoenixHaxeExampleWeb.Endpoint")
// @:endpoint: marks this module as Phoenix endpoint infrastructure.
@:endpoint
// @:appName: sets the OTP app identifier used for generated module/config wiring.
@:appName("phoenix_haxe_example")
class Endpoint {
	public static function static_paths():Array<String> {
		return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
	}
}
