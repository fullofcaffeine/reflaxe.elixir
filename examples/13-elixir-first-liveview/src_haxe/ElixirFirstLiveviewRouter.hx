package;

import reflaxe.elixir.macros.HttpMethod;

/**
 * Router for the Elixir-first LiveView example.
 */
// @:native: pins emitted naming to a specific Elixir symbol/module.
@:native("ElixirFirstLiveviewWeb.Router")
// @:router: marks this module as a Phoenix router and enables route emission transforms.
@:router
// @:build: runs a compile-time macro to generate/augment declarations in this type.
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
// @:routes: declares typed route definitions consumed by router build/emit logic.
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
