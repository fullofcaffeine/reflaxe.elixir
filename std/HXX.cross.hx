/**
 * HXX Template System (transitional stub)
 *
 * WHAT
 * - Provides a compile-time authoring API: `HXX.hxx(string)` and `HXX.block(string)`.
 * - At runtime this class is extern-only; all calls are meant to be eliminated by
 *   the AST pipeline which converts returned strings into ~H sigils.
 *
 * WHY
 * - Until all call-sites migrate to the macro-based HXX, we keep a minimal extern
 *   to avoid runtime codegen. The compiler’s transformer pass
 *   HeexRenderStringToSigilTransforms will convert the final returned strings
 *   into ESigil("H", ...) and normalize control tags.
 */
extern class HXX {
    /**
     * Author HXX/HEEx as a string. The compiler will convert the final returned
     * string to a ~H sigil and normalize control tags and interpolations.
     */
    public static function hxx(templateStr: String): String;

    /** Inline a nested block fragment authored as a string. */
    public static function block(templateStr: String): String;
}
