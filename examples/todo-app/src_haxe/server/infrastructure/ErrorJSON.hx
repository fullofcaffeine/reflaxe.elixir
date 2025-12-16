package server.infrastructure;

/**
 * TodoAppWeb.ErrorJSON
 *
 * WHAT
 * - App-level stub module required by Phoenix endpoint `render_errors` config.
 *
 * WHY
 * - Phoenix expects an app-namespaced module (TodoAppWeb.ErrorJSON).
 * - The implementation is generic and lives in the framework stdlib:
 *   `phoenix.errors.DefaultErrorJSON`.
 *
 * HOW
 * - Delegate `render/2` to the shared implementation.
 */
@:native("TodoAppWeb.ErrorJSON")
@:keep
class ErrorJSON {
    public static function render(template: String, assigns: Dynamic): phoenix.errors.DefaultErrorJSON.ErrorPayload {
        return phoenix.errors.DefaultErrorJSON.render(template, assigns);
    }
}
