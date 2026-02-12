package infrastructure;

@:native("MyAppWeb.Endpoint")
@:endpoint
@:appName("my_app")
@:endpointSockets([{path: "/socket", socket: infrastructure.UserSocket, session: true}])
class Endpoint {
	public static function static_paths():Array<String> {
		return ["assets"];
	}
}
