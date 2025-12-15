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
    public static function home(conn: Conn<EmptyParams>, _params: EmptyParams): Conn<EmptyParams> {
        var _ = _params;
        return conn.json({message: "Hello from Haxe → Elixir!"});
    }
}

