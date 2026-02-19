package;

import live.InteropLive;
import live.SearchLive;
import reflaxe.elixir.macros.RouterDsl.*;

/**
 * Router for the Elixir-first LiveView example.
 */
// @:native: pins emitted naming to a specific Elixir symbol/module.
@:native("ElixirFirstLiveviewWeb.Router")
// @:router: marks this module as a Phoenix router and enables route emission transforms.
@:router
final routes = [
	pipeline(browser, [plug(accepts, {initArgs: ["html"]}), plug(fetch_session)]),
	scope("/", [
		pipeThrough([browser]),
		liveSession("default", [live("/", SearchLive), live("/interop", InteropLive)])
	])
];
