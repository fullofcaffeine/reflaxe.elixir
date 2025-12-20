package;

/**
 * HXX entrypoint (AST-intercepted)
 *
 * WHAT
 * - Minimal functions so user code can call `HXX.hxx(...)` and `HXX.block(...)`.
 * - The AST builder detects calls to HXX.hxx()/block() and emits ~H directly
 *   (ESigil("H", ...)) via TemplateHelpers. This keeps compile stable across
 *   macro contexts and avoids nested macro forwarding errors.
 */
class HXX {
    // NOTE: Not `inline` on purpose.
    // The compiler detects HXX.hxx/block calls in the typed AST and lowers them to ~H.
    // If these are inlined away, the call site disappears and templates fall back to
    // plain string generation (breaking HEEx control tags, assigns interpolation, etc.).
    public static function hxx(templateStr: String): String {
        return templateStr;
    }

    public static function block(content: String): String {
        return content;
    }
}
