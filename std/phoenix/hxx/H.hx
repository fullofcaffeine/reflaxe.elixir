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
 * - Delegates to `HeexTemplate` entrypoints.
 *
 * NOTE
 * - Compile-time only; `HeexTemplate` itself is suppressed from emission.
 */
class H {
    public static inline function root(template: String): String {
        return HeexTemplate.root(template);
    }

    public static inline function root_ast(node: phoenix.hxx.ast.HeexNode): String {
        return HeexTemplate.root_ast(node);
    }

    public static inline function for_each<T>(items: Array<T>, render: T -> String): String {
        return HeexTemplate.for_each(items, render);
    }
}

