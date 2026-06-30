package server.infrastructure;

/**
 * TodoAppWeb HTTP endpoint
 * Handles incoming HTTP requests and WebSocket connections
 * 
 * Now using proper @:endpoint annotation with AST transformation
 * This generates a complete Phoenix.Endpoint module structure
 */
// @:endpoint: marks this module as Phoenix endpoint infrastructure.
@:endpoint
// @:appName: sets the OTP app identifier used for generated module/config wiring.
@:appName("todo_app")
// @:endpointSockets: declares socket mounts to emit in the endpoint.
@:endpointSockets([{path: "/socket", socket: server.infrastructure.UserSocket, session: true}])
class Endpoint {
	/**
	 * Get static paths for asset serving
	 * This function is referenced by the generated endpoint module
	 */
	public static function static_paths():Array<String> {
		return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
	}
}
