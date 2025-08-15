package layouts;

import reflaxe.elixir.HXX;

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
    public static function root(assigns: Dynamic): String {
        return RootLayout.render(assigns);
    }
    
    /**
     * Application layout function
     * Called by Phoenix for rendering the application wrapper
     */
    public static function app(assigns: Dynamic): String {
        return AppLayout.render(assigns);
    }
}