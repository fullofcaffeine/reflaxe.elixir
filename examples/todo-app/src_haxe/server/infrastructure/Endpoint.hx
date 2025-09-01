package server.infrastructure;

/**
 * TodoAppWeb HTTP endpoint
 * Handles incoming HTTP requests and WebSocket connections
 * 
 * Now using proper @:endpoint annotation with AST transformation
 * This generates a complete Phoenix.Endpoint module structure
 */
@:native("TodoAppWeb.Endpoint")
@:endpoint
@:appName("todo_app")
class Endpoint {
    /**
     * Get static paths for asset serving
     * This function is referenced by the generated endpoint module
     */
    public static function static_paths(): Array<String> {
        return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
    }
}