package;

import controllers.PageController;
import reflaxe.elixir.macros.RouterDsl.*;

/**
 * Router DSL example demonstrating Phoenix route generation from Haxe.
 */
// @:native: pins emitted naming to a specific Elixir symbol/module.
@:native("PhoenixHaxeExampleWeb.Router")
// @:router: marks this module as a Phoenix router and enables route emission transforms.
@:router
// @:routes: declares typed route definitions consumed by router build/emit logic.
@:routes([
	pipeline("browser", [plug("accepts", {initArgs: ["html"]}), plug("fetch_session")]),
	scope("/", [pipeThrough(["browser"]), get("/", PageController, PageController.home)])
])
extern function routerConfig():Void;
