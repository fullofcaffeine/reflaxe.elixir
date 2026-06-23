package server.infrastructure;

import elixir.types.Term;
import phoenix.LiveSession;
import plug.Conn;
import server.types.Types.Session;

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
// @:phoenixWebModule: generates the `AppWeb` helper module used by Phoenix `use AppWeb, ...` calls.
@:phoenixWebModule
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("TodoAppWeb")
class TodoAppWeb {
	/**
	 * Returns the static paths for the application.
	 * This is used by Phoenix for serving static assets.
	 */
	public static function static_paths():Array<String> {
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
	 * - Copy the selected Plug session keys into the LiveView session map.
	 */
	public static function live_session(conn:Conn<{}>):Term {
		return LiveSession.fromConnKeys(conn, ["user_id"]);
	}

	/**
	 * Reads the authenticated user id from a LiveView session map.
	 *
	 * The canonical key is `"user_id"`, matching the Plug session key copied by
	 * `live_session/1` and Phoenix's string-keyed session shape.
	 */
	public static function sessionUserId(session:Session):Null<Int> {
		if (session == null)
			return null;
		return LiveSession.getInt(session, "user_id");
	}
}
