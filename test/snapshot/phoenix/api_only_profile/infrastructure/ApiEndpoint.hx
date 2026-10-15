package infrastructure;

import plug.Conn;

@:native("MyAppWeb.Endpoint")
@:endpoint
@:appName("my_app")
@:endpointSockets([
	{path: "/socket", socket: infrastructure.UserSocket},
	{path: "/socket-with-explicit-false", socket: infrastructure.UserSocket, session: false}
])
class ApiEndpoint {
	/** Runs before redirects and sockets; retained through ordinary Haxe calls. */
	@:endpointAdmission
	public static function admitRequest(conn:Conn<{}>):Conn<{}> {
		if (NativeConn.getReqHeader(conn, "x-fail").length > 0)
			throw new haxe.Exception("Admission failure fixture");
		if (NativeConn.getReqHeader(conn, "x-deny").length > 0)
			return conn.sendResp(400, "Rejected before dispatch").halt();
		return markRequest(conn);
	}

	static function markRequest(conn:Conn<{}>):Conn<{}> {
		return NativeConn.putRespHeader(conn, "x-admission", "checked");
	}
}

/** Direct library binding; the fixture does not replace the Plug implementation. */
@:native("Plug.Conn")
extern class NativeConn {
	@:native("get_req_header")
	public static function getReqHeader(conn:Conn<{}>, name:String):Array<String>;

	@:native("put_resp_header")
	public static function putRespHeader(conn:Conn<{}>, name:String, value:String):Conn<{}>;
}
