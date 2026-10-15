package;

@:endpoint
class Main {
	@:endpointAdmission
	public static function admit(conn:plug.Conn<{}>):plug.Conn<{}>
		return conn;

	public static function call(conn:plug.Conn<{}>, opts:String, ?extra:String):plug.Conn<{}>
		return conn;
}
