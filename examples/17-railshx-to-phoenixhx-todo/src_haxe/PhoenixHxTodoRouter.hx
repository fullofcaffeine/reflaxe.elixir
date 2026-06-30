package;

import phoenix_hx_todo_hx.controllers.SessionController;
import phoenix_hx_todo_hx.infrastructure.LiveSession;
import phoenix_hx_todo_hx.live.AppLive;
import reflaxe.elixir.macros.RouterDsl.*;

@:router
final routes = [
	pipeline(browser, [
		plug(accepts, {initArgs: ["html"]}),
		plug(fetch_session),
		plug(fetch_live_flash),
		plug(protect_from_forgery),
		plug(put_secure_browser_headers)
	]),
	scope("/", [
		pipeThrough([browser]),
		liveSession("default", [live("/", AppLive), live("/todos", AppLive)], {
			session: liveSessionMfa(LiveSession, "live_session")
		}),
		post("/auth/demo", SessionController, SessionController.create),
		post("/auth/logout", SessionController, SessionController.delete)
	])
];
