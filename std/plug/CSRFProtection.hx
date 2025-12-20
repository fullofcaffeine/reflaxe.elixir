package plug;

/**
 * CSRFProtection
 *
 * WHAT
 * - Typed extern for `Plug.CSRFProtection`.
 *
 * WHY
 * - Phoenix layouts typically include a CSRF meta tag that the JS client reads to
 *   authenticate LiveView websocket connections.
 * - Exposing this as an extern keeps app code "Haxe-first" (no raw Elixir calls in templates).
 *
 * HOW
 * - Maps to `Plug.CSRFProtection.get_csrf_token/0`.
 */
@:native("Plug.CSRFProtection")
extern class CSRFProtection {
    @:native("get_csrf_token")
    static function get_csrf_token(): String;
}

