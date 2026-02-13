package;

import reflaxe.elixir.macros.HttpMethod;

/**
 * Router DSL example demonstrating Phoenix route generation from Haxe.
 */
// @:native: pins emitted naming to a specific Elixir symbol/module.
@:native("PhoenixHaxeExampleWeb.Router")
// @:router: marks this module as a Phoenix router and enables route emission transforms.
@:router
// @:build: runs a compile-time macro to generate/augment declarations in this type.
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
// @:routes: declares typed route definitions consumed by router build/emit logic.
@:routes([
	{
		name: "home",
		method: HttpMethod.GET,
		path: "/",
		controller: controllers.PageController,
		action: controllers.PageController.home
	}
])
class PhoenixHaxeExampleRouter {}
