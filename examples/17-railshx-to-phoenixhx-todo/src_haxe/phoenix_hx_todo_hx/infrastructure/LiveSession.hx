package phoenix_hx_todo_hx.infrastructure;

import elixir.ElixirMap;
import elixir.types.Term;
import plug.Conn;

/**
 * LiveView session bridge.
 *
 * WHAT
 * - Converts the Plug session into the string-keyed LiveView session map.
 *
 * WHY
 * - Phoenix.LiveView `mount/3` receives the session declared by the router,
 *   not the whole Plug connection. Keeping this as a small Haxe module shows the
 *   Phoenix pattern without replacing the scaffolded `PhoenixHxTodoWeb` helper.
 */
@:native("PhoenixHxTodoWeb.LiveSession")
class LiveSession {
	public static function live_session(conn:Conn<{}>):Term {
		var userId:Term = conn.getSession("user_id");
		var sessionMap:Term = {};
		return userId != null ? ElixirMap.put(sessionMap, "user_id", userId) : sessionMap;
	}
}
