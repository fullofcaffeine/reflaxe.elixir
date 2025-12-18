package phoenix.types;

import elixir.types.Term;

/**
 * Type-safe wrapper for Phoenix HTML components.
 * 
 * This abstract type provides compile-time safety for Phoenix component functions
 * while hiding the underlying term implementation. Components that return
 * HtmlComponent are guaranteed to be safe HTML output that Phoenix can render.
 * 
 * ## Usage
 * 
 * ```haxe
 * function myComponent(): HtmlComponent {
 *     return HtmlComponent.create("div", ["Hello World"]);
 * }
 * ```
 * 
 * ## Type Safety
 * 
 * The abstract prevents direct access to the underlying term value,
 * ensuring all component creation goes through type-safe factory methods.
 */
abstract HtmlComponent(Term) {
    /**
     * Creates a new HtmlComponent from component data.
     * This is an internal constructor - use factory methods instead.
     */
    inline function new(data: Term) {
        this = data;
    }
    
    /**
     * Creates an HTML component from a tag and content.
     * 
     * @param tag The HTML tag name
     * @param content The component content (text or nested components)
     * @return A type-safe HtmlComponent
     */
    public static function create(tag: String, content: Array<String>): HtmlComponent {
        return new HtmlComponent({
            tag: tag,
            content: content
        });
    }
    
    /**
     * Creates an HTML component with attributes.
     * 
     * @param tag The HTML tag name
     * @param attrs HTML attributes as key-value pairs
     * @param content The component content
     * @return A type-safe HtmlComponent
     */
    public static function createWithAttrs(tag: String, attrs: Map<String, String>, content: Array<String>): HtmlComponent {
        return new HtmlComponent({
            tag: tag,
            attrs: attrs,
            content: content
        });
    }
    
    /**
     * Creates a text node component.
     * 
     * @param text The text content
     * @return A type-safe HtmlComponent representing text
     */
    public static function text(text: String): HtmlComponent {
        return new HtmlComponent({
            type: "text",
            content: text
        });
    }
    
    /**
     * Creates an empty/nil component.
     * Used when a component should render nothing.
     * 
     * @return An empty HtmlComponent
     */
    public static function empty(): HtmlComponent {
        return new HtmlComponent(null);
    }
    
    /**
     * Wraps a Phoenix-generated component.
     * This allows interop with components created by Phoenix macros.
     * 
     * @param phoenixComponent The Phoenix-generated component
     * @return A type-safe HtmlComponent wrapper
     */
    @:noCompletion
    public static inline function fromPhoenix(phoenixComponent: Term): HtmlComponent {
        return new HtmlComponent(phoenixComponent);
    }
}
