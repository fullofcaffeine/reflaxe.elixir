package;

@:endpoint
class Main {
	@:endpointAdmission
	public static function first(conn:plug.Conn<{}>):plug.Conn<{}>
		return conn;

	@:endpointAdmission
	public static function second(conn:plug.Conn<{}>):plug.Conn<{}>
		return conn;
}
