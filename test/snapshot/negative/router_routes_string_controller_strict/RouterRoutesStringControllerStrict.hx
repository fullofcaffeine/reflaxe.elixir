package;

/**
 * Negative test: strict router typed refs mode rejects string controller literals in @:routes.
 * The build macro is included so legacy helper generation uses the same strict diagnostic.
 */
class UserController {
	public static function index():String {
		return "ok";
	}
}

@:router
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
@:routes([
	{
		name: "legacyUsersIndex",
		method: "GET",
		path: "/users",
		controller: "UserController",
		action: "index"
	}
])
class RouterRoutesStringControllerStrict {}
