package server.layouts;

// HXX is handled at compile-time by the Reflaxe.Elixir compiler - no imports needed

/**
 * Main layouts module for Phoenix application
 * Provides the layout functions that Phoenix expects
 */
@:native("TodoAppWeb.Layouts")
class Layouts {
    
    /**
     * Root layout function
     * Called by Phoenix for rendering the main HTML document
     */
    @:keep public static function root(assigns: Dynamic): Dynamic {
        // Minimal root that simply yields inner content, avoiding cross-module calls
        // Return inner_content as safe HTML without requiring ~H
        return untyped __elixir__('Map.get({0}, :inner_content)', assigns);
    }
    
    /**
     * Application layout function
     * Called by Phoenix for rendering the application wrapper
     */
    @:keep public static function app(assigns: Dynamic): Dynamic {
        // Minimal app layout that simply yields inner content
        return untyped __elixir__('Map.get({0}, :inner_content)', assigns);
    }
}
