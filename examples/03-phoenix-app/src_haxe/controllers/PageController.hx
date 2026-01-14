package controllers;

import plug.Conn;

typedef EmptyParams = {};

/**
 * Minimal Phoenix controller implemented in Haxe.
 */
@:native("PhoenixHaxeExampleWeb.PageController")
@:controller
class PageController {
    /**
     * GET /
     */
    public static function home(conn: Conn<EmptyParams>, params: EmptyParams): Conn<EmptyParams> {
        return conn.json({message: "Hello from Haxe → Elixir!"});
    }
}
