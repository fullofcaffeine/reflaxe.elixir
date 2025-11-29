package server.infrastructure;

/**
 * Minimal error HTML renderer to satisfy Phoenix error pipeline.
 *
 * WHAT
 * - Provides TodoAppWeb.ErrorHTML with a render/2 function so Phoenix
 *   can render error pages without missing template failures.
 *
 * WHY
 * - Phoenix expects this module to exist when errors bubble up. A missing
 *   module causes 500s during readiness probes.
 *
 * HOW
 * - Derives a human-readable message from the template name
 *   (e.g., "500.html" -> "Internal Server Error").
 */
@:native("TodoAppWeb.ErrorHTML")
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
