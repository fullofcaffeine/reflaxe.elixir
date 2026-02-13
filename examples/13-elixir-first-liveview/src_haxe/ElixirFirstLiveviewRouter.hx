package;

import reflaxe.elixir.macros.HttpMethod;

/**
 * Router for the Elixir-first LiveView example.
 */
@:native("ElixirFirstLiveviewWeb.Router")
@:router
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
@:routes([
	{
		name: "root",
		method: HttpMethod.LIVE,
		path: "/",
		controller: live.SearchLive,
		action: live.SearchLive.index
	}
])
class ElixirFirstLiveviewRouter {}
