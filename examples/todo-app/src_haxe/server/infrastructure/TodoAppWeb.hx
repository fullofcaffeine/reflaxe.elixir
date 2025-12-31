package server.infrastructure;

import elixir.ElixirMap;
import elixir.types.Term;
import plug.Conn;

/**
 * TodoAppWeb module providing Phoenix framework helpers.
 * 
 * This module acts as the central hub for Phoenix web functionality,
 * providing `use` macros for router, controller, LiveView, and other
 * Phoenix components. It follows Phoenix conventions for web modules.
 * 
 * The @:phoenixWebModule annotation triggers generation of all necessary
 * Phoenix macros including router, controller, live_view, etc.
 */
@:phoenixWebModule
@:native("TodoAppWeb")
class TodoAppWeb {
    /**
     * Returns the static paths for the application.
     * This is used by Phoenix for serving static assets.
     */
    public static function static_paths(): Array<String> {
        return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
    }

    /**
     * live_session hook for LiveView routes.
     *
     * WHAT
     * - Supplies additional session data (string-keyed map) to all LiveViews declared
     *   inside the router-generated `live_session :default` block.
     *
     * WHY
     * - Phoenix.LiveView mount receives the "LiveView session" (a string-keyed map),
     *   not the Plug session. To make authentication state available in LiveViews,
     *   we derive a minimal session payload from `Plug.Conn.get_session/2`.
     *
     * HOW
     * - Read `:user_id` from the Plug session and return `%{"user_id" => user_id}` when present.
     */
    @:keep
    public static function live_session(conn: Conn<{}>): Term {
        var userId: Term = conn.getSession("user_id");
        var sessionMap: Term = {};
        return userId != null ? ElixirMap.put(sessionMap, "user_id", userId) : sessionMap;
    }
}
