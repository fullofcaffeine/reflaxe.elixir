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
}

