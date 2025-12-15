package server.infrastructure;

/**
 * Minimal error HTML renderer to satisfy Phoenix error pipeline.
 */
@:native("PhoenixHaxeExampleWeb.ErrorHTML")
@:keep
class ErrorHTML {
    public static function render(template: String, _assigns: Dynamic): String {
        return switch (baseTemplate(template)) {
            case "404": "Not Found";
            case "401": "Unauthorized";
            case "403": "Forbidden";
            case "422": "Unprocessable Entity";
            case "500": "Internal Server Error";
            case _: "Error";
        }
    }

    static function baseTemplate(template: String): String {
        var idx = template.indexOf(".");
        return idx >= 0 ? template.substr(0, idx) : template;
    }
}

