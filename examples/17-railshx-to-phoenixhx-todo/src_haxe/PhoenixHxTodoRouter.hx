package;

import phoenix_hx_todo_hx.live.AppLive;
import reflaxe.elixir.macros.RouterDsl.*;

@:native("PhoenixHxTodoWeb.Router")
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
		liveSession("default", [live("/", AppLive), live("/todos", AppLive)])
	])
];
