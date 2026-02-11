package phoenix.hxx.ast;

/**
 * HeexAttr (TSX template AST)
 *
 * WHAT
 * - Compile-time-only attribute nodes for typed HEEx templates.
 *
 * WHY
 * - TSX-mode templates need to preserve the difference between:
 *   - static attributes:  class="btn"
 *   - expression attrs:   class={expr}
 *   - boolean attrs:      disabled
 * - This structure is consumed by the compiler backend to print idiomatic HEEx.
 *
 * HOW
 * - `InlineMarkup` / TSX template parsing macros construct these nodes.
 * - The AST builder detects `HeexTemplate.root_ast(...)` and prints HEEx from this AST.
 *
 * NOTE
 * - This module is compile-time only and is suppressed from emission in Elixir outputs.
 */
enum HeexAttr {
    Static(name: String, value: String);
    Bool(name: String);
    Expr<T>(name: String, value: T);
    Spread<T>(attrs: T);
}
