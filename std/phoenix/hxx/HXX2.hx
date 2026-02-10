package phoenix.hxx;

/**
 * HXX2 entrypoint (AST-intercepted) (legacy)
 *
 * WHAT
 * - Stub functions so older generated code can call `phoenix.hxx.HXX2.root(...)`.
 *
 * WHY
 * - This type exists for backwards compatibility; new code should use `HeexTemplate.root/1`.
 *
 * HOW
 * - Delegate to `HeexTemplate.root/1`.
 *
 * NOTE
 * - This module is compile-time only and is suppressed from emission in Elixir outputs.
 */
class HXX2 {
    // NOTE: Not `inline` on purpose.
    // The compiler detects HXX2.root calls in the typed AST and lowers them to ~H.
    @:deprecated("Use phoenix.hxx.HeexTemplate.root(...)")
    public static function root(template: String): String {
        return HeexTemplate.root(template);
    }
}
