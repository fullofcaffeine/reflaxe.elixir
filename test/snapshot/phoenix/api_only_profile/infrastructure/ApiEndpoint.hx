package infrastructure;

@:native("MyAppWeb.Endpoint")
@:endpoint
@:appName("my_app")
@:endpointSockets([
	{path: "/socket", socket: infrastructure.UserSocket},
	{path: "/socket-with-explicit-false", socket: infrastructure.UserSocket, session: false}
])
class ApiEndpoint {}
