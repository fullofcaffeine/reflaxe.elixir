package phoenix;

import phoenix.types.Assigns;
import phoenix.types.Flash;
import phoenix.types.Flash.FlashType;
import phoenix.types.Flash.FlashMap;

/**
 * Phoenix.Component extern definitions for template helpers
 * 
 * This extern provides type-safe access to Phoenix's template helper functions
 * that are commonly used in HEEx templates and layouts.
 * 
 * These functions are Phoenix framework built-ins and should be compiled
 * directly to Phoenix helper calls in templates, not implemented in Haxe.
 * 
 * Usage in templates:
 * - In HXX: ${Component.get_csrf_token()}
 * - Compiles to: <%= get_csrf_token() %>
 * 
 * Type Safety Improvements:
 * - Uses Assigns<T> for type-safe template variable access
 * - Uses FlashMessage and FlashType for structured flash messages
 * - Maintains Phoenix compatibility while providing compile-time checking
 */
@:native("Phoenix.Component")
extern class Component {
    /**
     * Get CSRF token for forms and meta tags
     * Used in root layouts to provide CSRF protection
     * 
     * @return String CSRF token for the current session
     */
    @:templateHelper
    static function get_csrf_token(): String;
    
    /**
     * Get the current assigns map
     * Provides access to template assigns in a type-safe way
     * 
     * Usage: Component.assigns<MyAssignsType>() for full type safety
     * 
     * @return Assigns<T> Type-safe assigns wrapper
     */
    static function assigns<T>(): Assigns<T>;
    
    /**
     * Assign values to the assigns map
     * 
     * Supports both single assignment: assign(assigns, key, value)
     * And bulk assignment: assign(assigns, new_assigns)
     * 
     * @param assigns Current type-safe assigns map
     * @param key Assignment key or map of new assigns
     * @param value Assignment value (for single assignment)
     * @return Assigns<T> Updated type-safe assigns map
     */
    @:overload(function<T>(assigns: Assigns<T>, new_assigns: T): Assigns<T> {})
    static function assign<T, V>(assigns: Assigns<T>, key: String, value: V): Assigns<T>;
    
    /**
     * Get flash messages from the session
     * 
     * Supports both single message: get_flash(type)
     * And all messages: get_flash()
     * 
     * @param type Flash message type (optional, use FlashType for type safety)
     * @return String|FlashMap Flash message content or complete flash map
     */
    @:overload(function(): FlashMap {})
    static function get_flash(type: FlashType): String;
    
    /**
     * Generate a URL for a static asset
     * Used for referencing CSS, JS, images, etc.
     * 
     * @param path Asset path (e.g., "/images/logo.png")
     * @return String Full URL to the static asset
     */
    @:templateHelper
    static function static_path(path: String): String;
    
    /**
     * Generate a verified route path
     * Type-safe route generation with compile-time verification
     * 
     * @param route Route name or helper
     * @param params Optional route parameters
     * @return String Generated route path
     */
    static function route_path(route: String, ?params: Dynamic): String;
    
    /**
     * Generate a verified route URL  
     * Type-safe URL generation with compile-time verification
     * 
     * @param route Route name or helper
     * @param params Optional route parameters
     * @return String Generated route URL
     */
    static function route_url(route: String, ?params: Dynamic): String;
    
    /**
     * Render raw HTML (marked as safe)
     * Use with caution - content is not escaped
     * 
     * @param html HTML string to render as-is
     * @return String Raw HTML content
     */
    @:templateHelper
    static function raw(html: String): String;
    
    /**
     * Live title helper for dynamic page titles
     * Updates the page title during LiveView navigation
     * 
     * @param title New page title
     * @param opts Options like prefix, suffix, separator
     * @return String Formatted title HTML
     */
    static function live_title(title: String, ?opts: Dynamic): String;
    
    /**
     * Generate a link element
     * Convenience helper for creating HTML links
     * 
     * @param text Link text content
     * @param to Destination URL or path
     * @param opts Link options (class, id, target, etc.)
     * @return String Generated link HTML
     */
    static function link(text: String, to: String, ?opts: Dynamic): String;
}