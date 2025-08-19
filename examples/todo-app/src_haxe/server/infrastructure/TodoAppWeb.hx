package server.infrastructure;

/**
 * TodoAppWeb module providing Phoenix framework helpers.
 * 
 * This module acts as the central hub for Phoenix web functionality,
 * providing `use` macros for router, controller, LiveView, and other
 * Phoenix components. It follows Phoenix conventions for web modules.
 * 
 * The @:phoenixWebModule annotation triggers generation of all necessary
 * Phoenix macros including router, controller, live_view, etc.
 */
@:phoenixWebModule
@:native("TodoAppWeb")
class TodoAppWeb {
    /**
     * Returns the static paths for the application.
     * This is used by Phoenix for serving static assets.
     */
    public static function static_paths(): Array<String> {
        return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
    }
}