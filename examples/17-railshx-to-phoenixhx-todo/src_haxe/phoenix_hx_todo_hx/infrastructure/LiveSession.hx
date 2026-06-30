package phoenix_hx_todo_hx.infrastructure;

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
// Exact interop escape hatch: this helper is a plain app web module, not a
// Phoenix behavior with a dedicated PhoenixHx derivation marker yet.
@:native("PhoenixHxTodoWeb.LiveSession")
class LiveSession {
	public static function live_session(conn:Conn<{}>):Term {
		return phoenix.LiveSession.fromConnKeys(conn, ["user_id"]);
	}
}
