package phoenix;

/**
 * Extern definition for TodoAppWeb module - Phoenix framework helpers
 * 
 * This extern provides type-safe access to Phoenix's web interface macros
 * which define common functionality for controllers, views, channels, etc.
 * 
 * The TodoAppWeb module is Phoenix infrastructure that sets up the proper
 * imports, aliases, and helper functions for all web-facing modules.
 * 
 * This is an example of acceptable manual Elixir files that remain as
 * framework plumbing while application logic is written in Haxe.
 */
@:native("TodoAppWeb")
extern class TodoAppWeb {
    /**
     * Sets up a module to be a Phoenix controller
     * Provides access to conn, params, and controller helpers
     */
    static function controller(): Dynamic;
    
    /**
     * Sets up a module to be a Phoenix view
     * Provides HTML helpers and template rendering
     */
    static function view(): Dynamic;
    
    /**
     * Sets up a module to be a Phoenix LiveView
     * Provides LiveView lifecycle callbacks and helpers
     */
    static function live_view(): Dynamic;
    
    /**
     * Sets up a module to be a Phoenix LiveComponent
     * Provides component lifecycle and state management
     */
    static function live_component(): Dynamic;
    
    /**
     * Sets up a module to be a Phoenix Component
     * Provides functional component helpers
     */
    static function component(): Dynamic;
    
    /**
     * Sets up a module to be a Phoenix router
     * Provides routing DSL and pipeline helpers
     */
    static function router(): Dynamic;
    
    /**
     * Sets up a module to be a Phoenix channel
     * Provides real-time messaging callbacks
     */
    static function channel(): Dynamic;
    
    /**
     * Verified routes helper module
     * Provides compile-time verified route generation
     */
    @:native("TodoAppWeb.Router.Helpers")
    static var Routes: Dynamic;
}