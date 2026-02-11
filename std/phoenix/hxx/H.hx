package phoenix.hxx;

/**
 * H (short alias for typed HEEx helpers)
 *
 * WHAT
 * - Convenience alias to reduce verbosity in templates.
 *
 * WHY
 * - `phoenix.hxx.HeexTemplate.*` is descriptive but long.
 *
 * HOW
 * - Exposes compile-time-only entrypoints that are intercepted directly by the
 *   template lowering pipeline (same behavior as `HeexTemplate`).
 *
 * NOTE
 * - Compile-time only; this module is suppressed from runtime emission.
 */
class H {
    public static function root(template: String): String {
        return template;
    }

    public static function root_ast(node: phoenix.hxx.ast.HeexNode): String {
        throw "H.root_ast is compile-time only and must be lowered by the compiler pipeline";
    }

    public static function for_each<T>(items: Array<T>, render: T -> String): String {
        throw "H.for_each is compile-time only and must be lowered inside template collection";
    }

    public static function each<T>(items: Array<T>, render: T -> String): String {
        throw "H.each is compile-time only and must be lowered inside template collection";
    }
}
