package;

import phoenix_chat_hx.live.AppLive;
import reflaxe.elixir.macros.RouterDsl.*;

/**
 * Phoenix router authored in Haxe using the typed module-level router DSL.
 *
 * WHY
 * - Keeps route structure close to Phoenix while preserving Haxe compile-time checks.
 */
@:native("PhoenixChatWeb.Router")
@:router
final routes = [
	pipeline(browser, [
		plug(accepts, {initArgs: ["html"]}),
		plug(fetch_session),
		plug(fetch_live_flash),
		plug(protect_from_forgery),
		plug(put_secure_browser_headers)
	]),
	scope("/", [pipeThrough([browser]), liveSession("default", [live("/", AppLive)])])
];
