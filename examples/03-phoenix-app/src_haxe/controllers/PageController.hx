package controllers;

import plug.Conn;

typedef EmptyParams = {};

/**
 * Minimal Phoenix controller implemented in Haxe.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.

@:native("PhoenixHaxeExampleWeb.PageController")
// @:controller: marks this module as a Phoenix controller for HTTP actions.
@:controller
class PageController {
	/**
	 * GET /
	 */
	public static function home(conn:Conn<EmptyParams>, params:EmptyParams):Conn<EmptyParams> {
		return conn.json({message: "Hello from Haxe → Elixir!"});
	}
}
