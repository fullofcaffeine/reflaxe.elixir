package server.infrastructure;

import elixir.types.Term;

/**
 * TodoAppWeb.ErrorHTML
 *
 * WHAT
 * - App-level stub module required by Phoenix endpoint `render_errors` config.
 *
 * WHY
 * - Phoenix expects an app-namespaced module (TodoAppWeb.ErrorHTML).
 * - The implementation is generic and lives in the framework stdlib:
 *   `phoenix.errors.DefaultErrorHTML`.
 *
 * HOW
 * - Delegate `render/2` to the shared implementation.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("TodoAppWeb.ErrorHTML")
class ErrorHTML {
	public static function render(template:String, assigns:Term):String {
		return phoenix.errors.DefaultErrorHTML.render(template, assigns);
	}
}
