package phoenix.errors;

/**
 * DefaultErrorJSON
 *
 * WHAT
 * - Provides a reusable, Phoenix-conventional JSON error renderer implementation
 *   for apps to delegate to (e.g. `MyAppWeb.ErrorJSON.render/2`).
 *
 * WHY
 * - Phoenix requires app-namespaced `*Web.ErrorJSON` modules (referenced from endpoint config).
 * - The common payload shape is generic: `%{errors: %{detail: "..."}}`.
 * - Keeping the implementation in std avoids boilerplate across examples/apps.
 *
 * HOW
 * - Implement a `render/2` function returning a typed payload that compiles to an Elixir map.
 * - Derive a stable status code from template name (e.g. `"404.json"`).
 */
extern class DefaultErrorJSON {
    /**
     * Render a conventional JSON error payload for the given template.
     *
     * Implemented as an extern inline to avoid emitting a runtime module in user apps.
     */
    extern inline public static function render(template: String, _assigns: Dynamic): ErrorPayload {
        return cast untyped __elixir__('
          _ = {1}
          t = to_string({0})
          base =
            case String.split(t, ".", parts: 2) do
              [b | _] -> b
              _ -> t
            end

          msg =
            case base do
              "404" -> "Not Found"
              "401" -> "Unauthorized"
              "403" -> "Forbidden"
              "422" -> "Unprocessable Entity"
              "500" -> "Internal Server Error"
              _ -> "Error"
            end

          %{errors: %{detail: msg}}
        ', template, _assigns);
    }
}

typedef ErrorPayload = {
    var errors: ErrorDetail;
}

typedef ErrorDetail = {
    var detail: String;
}
