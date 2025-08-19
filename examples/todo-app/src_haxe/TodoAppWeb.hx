package;

/**
 * TodoAppWeb - Main web interface module for Phoenix
 * 
 * This module provides the core infrastructure for Phoenix web components,
 * including router, controller, live view, and HTML helpers.
 * 
 * Compiles to lib/todo_app_web.ex with proper Phoenix module structure.
 */
@:native("TodoAppWeb")
@:phoenixWeb
class TodoAppWeb {
    /**
     * Static paths for assets
     */
    public static function staticPaths(): Array<String> {
        return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
    }
    
    /**
     * Router macro for Phoenix routing
     * Returns a macro quote block (handled by compiler)
     */
    public static function router(): Void {
        // This will be handled by the compiler to generate proper quote block
    }
    
    /**
     * Channel macro for Phoenix channels
     * Returns a macro quote block (handled by compiler)
     */
    public static function channel(): Void {
        // This will be handled by the compiler to generate proper quote block
    }
    
    /**
     * Controller macro for Phoenix controllers
     * Returns a macro quote block (handled by compiler)
     */
    public static function controller(): Void {
        // This will be handled by the compiler to generate proper quote block
    }
    
    /**
     * LiveView macro for Phoenix LiveView components
     * Returns a macro quote block (handled by compiler)
     */
    public static function liveView(): Void {
        // This will be handled by the compiler to generate proper quote block
    }
    
    /**
     * LiveComponent macro for Phoenix LiveComponents  
     * Returns a macro quote block (handled by compiler)
     */
    public static function liveComponent(): Void {
        // This will be handled by the compiler to generate proper quote block
    }
    
    /**
     * HTML macro for Phoenix components
     * Returns a macro quote block (handled by compiler)
     */
    public static function html(): Void {
        // This will be handled by the compiler to generate proper quote block
    }
    
    /**
     * HTML helpers for Phoenix components
     * Returns a macro quote block (handled by compiler)
     */
    private static function htmlHelpers(): Void {
        // This will be handled by the compiler to generate proper quote block
    }
    
    /**
     * Verified routes for Phoenix
     * Returns a macro quote block (handled by compiler)
     */
    public static function verifiedRoutes(): Void {
        // This will be handled by the compiler to generate proper quote block
    }
}