package phoenix.hxx;

/**
 * HeexTemplate entrypoint (AST-intercepted)
 *
 * WHAT
 * - Compile-time only stub that provides a stable call shape
 *   (`phoenix.hxx.HeexTemplate.root(...)`) for inline markup lowering.
 *
 * WHY
 * - Inline markup strings can contain `${ ... }` blocks that we want the Haxe compiler to
 *   parse and type-check as Haxe expressions. The `@:markup` payload itself is just text.
 * - A non-inline, non-macro entrypoint gives the AST builder a deterministic hook to emit
 *   Phoenix HEEx (`~H"""..."""`) without relying on macro forwarding.
 *
 * HOW
 * - `InlineMarkup` rewrites markup literals into `HeexTemplate.root(<string+expr concat>)`.
 * - The AST builder detects `HeexTemplate.root/1` calls and lowers them to `ESigil("H", ...)`.
 *
 * NOTE
 * - This module is compile-time only and is suppressed from emission in Elixir outputs.
 */
class HeexTemplate {
    // NOTE: Not `inline` on purpose.
    // The compiler detects HeexTemplate.root calls in the typed AST and lowers them to ~H.
    public static function root(template: String): String {
        return template;
    }

    /**
     * root_ast/1 (TSX template entrypoint)
     *
     * WHAT
     * - Stable call shape for fully-typed TSX-mode templates (macro-parsed template AST).
     *
     * WHY
     * - Lets the backend emit HEEx directly from a structured AST, avoiding string-level heuristics.
     *
     * HOW
     * - TSX template macros emit `HeexTemplate.root_ast(<HeexNode>)`.
     * - The AST builder detects this call and lowers it to `~H"""..."""`.
     *
     * NOTE
     * - Compile-time only; suppressed from runtime emission.
     */
    public static function root_ast(node: phoenix.hxx.ast.HeexNode): String {
        throw "HeexTemplate.root_ast is compile-time only and must be lowered by the compiler pipeline";
    }

    /**
     * for_each/2 (template helper)
     *
     * WHAT
     * - Typed helper for rendering repeating template content.
     *
     * WHY
     * - Building HTML by concatenating strings inside `<%= ... %>` escapes tags in HEEx.
     * - We want a TSX-like workflow where the loop binder is a real Haxe variable (typed),
     *   but the output becomes a proper HEEx `<%= for ... do %> ... <% end %>` block.
     *
     * HOW
     * - This is compile-time only: `TemplateHelpers.collectTemplateContent` recognizes calls
     *   to `HeexTemplate.for_each(items, fn item -> ... end)` when they occur inside a template
     *   producer (`HeexTemplate.root(...)` / inline markup) and lowers them into a HEEx `for` block.
     *
     * NOTE
     * - This function is only valid inside templates. It is not emitted into runtime Elixir output.
     */
    public static function for_each<T>(items: Array<T>, render: T -> String): String {
        throw "HeexTemplate.for_each is compile-time only and must be lowered inside template collection";
    }

    /**
     * each/2 (short alias)
     *
     * WHAT
     * - Short alias for `for_each/2`.
     *
     * WHY
     * - Reduces verbosity for expression-level template composition while preserving the same
     *   compile-time lowering semantics.
     *
     * HOW
     * - Recognized by `TemplateHelpers.collectTemplateContent` exactly like `for_each/2`.
     *
     * NOTE
     * - Compile-time only; suppressed from runtime emission.
     */
    public static function each<T>(items: Array<T>, render: T -> String): String {
        throw "HeexTemplate.each is compile-time only and must be lowered inside template collection";
    }
}
