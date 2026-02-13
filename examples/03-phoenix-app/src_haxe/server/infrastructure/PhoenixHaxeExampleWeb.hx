package server.infrastructure;

/**
 * PhoenixHaxeExampleWeb module providing Phoenix framework helpers.
 *
 * This module acts as the central hub for Phoenix web functionality, providing
 * `use` macros for router, controller, and other Phoenix components.
 */
// @:phoenixWebModule: generates the `AppWeb` helper module used by Phoenix `use AppWeb, ...` calls.
@:phoenixWebModule
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("PhoenixHaxeExampleWeb")
class PhoenixHaxeExampleWeb {
	public static function static_paths():Array<String> {
		return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
	}
}
