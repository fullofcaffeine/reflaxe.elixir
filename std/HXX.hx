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
    public static inline function hxx(templateStr: String): String {
        return templateStr;
    }

    public static inline function block(content: String): String {
        return content;
    }
}
