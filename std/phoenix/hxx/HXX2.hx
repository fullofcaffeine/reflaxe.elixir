package phoenix.hxx;

/**
 * HXX2 entrypoint (AST-intercepted)
 *
 * WHAT
 * - Stub functions so build-macros can lower inline markup (`@:markup "<tag ...>"`) into a
 *   stable call shape (`phoenix.hxx.HXX2.root(...)`) that the compiler can intercept.
 *
 * WHY
 * - Inline markup strings can contain `{...}` blocks that we want to treat as **Haxe expressions**
 *   (syntax + type checked by the Haxe compiler), but the raw `@:markup` payload is just text.
 * - HXX2 provides a canonical, non-inline entrypoint so the AST builder can reliably emit
 *   Phoenix HEEx (`~H"""..."""`) without depending on nested macro forwarding.
 *
 * HOW
 * - `InlineMarkup` rewrites markup literals into `HXX2.root(<string+expr concat>)`.
 * - The AST builder detects `HXX2.root/1` calls and lowers them to `ESigil("H", ...)`.
 *
 * NOTE
 * - This module is compile-time only and is suppressed from emission in Elixir outputs.
 */
class HXX2 {
    // NOTE: Not `inline` on purpose.
    // The compiler detects HXX2.root calls in the typed AST and lowers them to ~H.
    public static function root(template: String): String {
        return template;
    }
}

