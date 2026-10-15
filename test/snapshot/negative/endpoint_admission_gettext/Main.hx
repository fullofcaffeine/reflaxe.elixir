package;

@:keep
@:gettext
@:endpoint
class Main {
	@:endpointAdmission
	public static function admit(conn:plug.Conn<{}>):plug.Conn<{}>
		return conn;
}
