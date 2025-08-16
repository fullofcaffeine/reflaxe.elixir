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
@:noRuntime
extern class HXX {
    /**
     * Process an HXX template string into Phoenix HEEx format.
     * 
     * This function is never actually called at runtime - it serves as a marker
     * for the Reflaxe.Elixir compiler to detect and transform template calls.
     * 
     * Features:
     * - JSX-like syntax with type-safe interpolation
     * - Automatic conversion from ${} to {} (HEEx format)  
     * - Compile-time template validation
     * - Phoenix LiveView integration
     * 
     * @param templateStr The template string containing JSX-like markup
     * @return String The processed template (at compile-time, becomes ~H sigil)
     */
    public static function hxx(templateStr: String): String;
}