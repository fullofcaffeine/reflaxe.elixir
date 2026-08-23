package controllers;

import plug.Conn;

@:native("MyAppWeb.ApiController")
@:controller
class ApiController {
	public static function status(conn:Conn<{}>, params:{}):Conn<{}>
		return conn.json({status: "ok"});
}
