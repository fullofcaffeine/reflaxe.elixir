package server.infrastructure;

/**
 * Minimal error JSON renderer to satisfy Phoenix error pipeline.
 */
@:native("PhoenixHaxeExampleWeb.ErrorJSON")
@:keep
class ErrorJSON {
    public static function render(template: String, _assigns: Dynamic): Dynamic {
        return {errors: {detail: ErrorHTML.render(template, _assigns)}};
    }
}

