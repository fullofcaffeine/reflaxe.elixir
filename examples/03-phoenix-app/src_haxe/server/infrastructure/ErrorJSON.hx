package server.infrastructure;

import elixir.types.Term;

/**
 * Minimal error JSON renderer to satisfy Phoenix error pipeline.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("PhoenixHaxeExampleWeb.ErrorJSON")
// @:keep: Phoenix resolves ErrorJSON by module convention in fallback rendering, so this module can be runtime-referenced indirectly.
@:keep
class ErrorJSON {
	public static function render(template:String, _assigns:Term):Term {
		return {errors: {detail: ErrorHTML.render(template, _assigns)}};
	}
}
