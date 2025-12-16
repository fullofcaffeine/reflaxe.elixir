package phoenix.errors;

/**
 * DefaultErrorHTML
 *
 * WHAT
 * - Provides a reusable, Phoenix-conventional error HTML renderer implementation
 *   for apps to delegate to (e.g. `MyAppWeb.ErrorHTML.render/2`).
 *
 * WHY
 * - Phoenix requires app-namespaced `*Web.ErrorHTML` modules (referenced from endpoint config).
 * - The mapping from `"404.html"` → "Not Found" is generic and should not be duplicated in each app.
 * - Keeping the implementation in the framework std avoids app-specific `__elixir__()` and reduces boilerplate.
 *
 * HOW
 * - Implement a `render/2` function that matches Phoenix.Template expectations.
 * - Derive a stable status code from template name (e.g. `"500.html"`, `"404.json"`).
 *
 * EXAMPLES
 * Haxe (app stub):
 *   @:native("MyAppWeb.ErrorHTML")
 *   class ErrorHTML {
 *     public static function render(template:String, assigns:Dynamic):String
 *       return phoenix.errors.DefaultErrorHTML.render(template, assigns);
 *   }
 *
 * Elixir (generated app stub):
 *   defmodule MyAppWeb.ErrorHTML do
 *     def render(template, assigns), do: Phoenix.Errors.DefaultErrorHTML.render(template, assigns)
 *   end
 */
extern class DefaultErrorHTML {
    /**
     * Render an error message for the given template.
     *
     * Implemented as an extern inline to avoid emitting a runtime module in user apps.
     */
    extern inline public static function render(template: String, _assigns: Dynamic): String {
        return untyped __elixir__('
          _ = {1}
          t = to_string({0})
          base =
            case String.split(t, ".", parts: 2) do
              [b | _] -> b
              _ -> t
            end

          case base do
            "404" -> "Not Found"
            "401" -> "Unauthorized"
            "403" -> "Forbidden"
            "422" -> "Unprocessable Entity"
            "500" -> "Internal Server Error"
            _ -> "Error"
          end
        ', template, _assigns);
    }
}
