package;

import reflaxe.elixir.macros.HttpMethod;

/**
 * Router DSL example demonstrating Phoenix route generation from Haxe.
 */
@:native("PhoenixHaxeExampleWeb.Router")
@:router
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
@:routes([
    {
        name: "home",
        method: HttpMethod.GET,
        path: "/",
        controller: "controllers.PageController",
        action: "home"
    }
])
class PhoenixHaxeExampleRouter {}

