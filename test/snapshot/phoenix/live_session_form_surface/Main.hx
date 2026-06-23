package;

import elixir.types.Term;
import phoenix.LiveSession;
import phoenix.Phoenix.Form;
import plug.Conn;
import reflaxe.elixir.macros.RouterDsl.*;
import Types.AppAssigns;
import Types.SearchParams;
import Types.User;
import Types.UserParams;

@:native("TestAppWeb.LiveSessionBridge")
class LiveSessionBridge {
	public static function live_session(conn:Conn<{}>):Term {
		return LiveSession.fromConnKeys(conn, ["user_id", "organization_id"]);
	}
}

@:native("TestAppWeb.AuthHook")
class AuthHook {}

@:native("TestAppWeb.Router")
@:router
final routes = [
	scope("/", [
		liveSession("default", [live("/", AppLive)], {
			session: liveSessionMfa(LiveSessionBridge, "live_session"),
			onMount: [onMount(AuthHook), onMountArg(AuthHook, "admin")]
		})
	])
];

class Main {}
