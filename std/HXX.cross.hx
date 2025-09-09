/**
 * HXX Template Processor
 * 
 * Provides compile-time JSX-like template syntax for generating Phoenix HEEx templates.
 * This is a pure compile-time tool - all HXX.hxx() calls are transformed to ~H sigils
 * during Haxe→Elixir compilation.
 * 
 * Usage:
 * ```haxe
 * function render(assigns: Dynamic): String {
 *     return HXX.hxx('<div class="user">${assigns.name}</div>');
 * }
 * ```
 * 
 * Compiles to:
 * ```elixir
 * def render(assigns) do
 *   ~H"""
 *   <div class="user">{assigns.name}</div>
 *   """
 * end
 * ```
 * 
 * @see documentation/guides/HXX_GUIDE.md - Complete usage guide
 * @see documentation/HXX_ARCHITECTURE.md - Architecture and implementation details
 */
/**
 * HXX Template System
 * 
 * Temporary workaround: Since the macro transformation isn't working with
 * string interpolation, we provide a simple passthrough implementation that
 * returns the template string directly for now.
 * 
 * TODO: Implement proper compile-time transformation to ~H sigils
 */
@:extern
class HXX {
    /**
     * Process an HXX template string into Phoenix HEEx format.
     * 
     * Currently acts as a passthrough, returning the template string as-is.
     * The templates are already in valid HEEx format, so this works for now.
     * 
     * @param templateStr The template string containing HEEx markup
     * @return String The template string (unchanged)
     */
    extern inline public static function hxx(templateStr: String): String {
        // For now, just return the string as-is
        // We'll need to manually wrap in ~H sigil in the generated code
        return templateStr;
    }
}