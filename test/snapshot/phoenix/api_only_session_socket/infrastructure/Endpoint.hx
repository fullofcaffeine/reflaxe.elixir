package infrastructure;

@:native("MyApp.Endpoint")
@:endpoint
@:endpointSockets([
	{path: "/session-socket", socket: infrastructure.UserSocket, session: true},
	{path: "/sessionless-socket", socket: infrastructure.UserSocket, session: false}
])
class Endpoint {}
