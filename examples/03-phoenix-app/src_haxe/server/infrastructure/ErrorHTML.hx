package server.infrastructure;

import elixir.types.Term;

/**
 * Minimal error HTML renderer to satisfy Phoenix error pipeline.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("PhoenixHaxeExampleWeb.ErrorHTML")
// @:keep: Phoenix resolves ErrorHTML by module convention in the endpoint pipeline, so this module can be runtime-referenced without direct Haxe calls.
@:keep
class ErrorHTML {
	public static function render(template:String, _assigns:Term):String {
		return switch (baseTemplate(template)) {
			case "404": "Not Found";
			case "401": "Unauthorized";
			case "403": "Forbidden";
			case "422": "Unprocessable Entity";
			case "500": "Internal Server Error";
			case _: "Error";
		}
	}

	static function baseTemplate(template:String):String {
		var idx = template.indexOf(".");
		return idx >= 0 ? template.substr(0, idx) : template;
	}
}
