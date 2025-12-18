package server.infrastructure;

import elixir.types.Term;

/**
 * Minimal error JSON renderer to satisfy Phoenix error pipeline.
 */
@:native("PhoenixHaxeExampleWeb.ErrorJSON")
@:keep
class ErrorJSON {
    public static function render(template: String, _assigns: Term): Term {
        return {errors: {detail: ErrorHTML.render(template, _assigns)}};
    }
}
