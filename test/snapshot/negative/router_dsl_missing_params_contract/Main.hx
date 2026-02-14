package;

import reflaxe.elixir.macros.RouterDsl.*;

/**
 * Negative test: typed RouterDsl routes with path params must declare paramsContract.
 */
class UserController {
	public static function show():String {
		return "show";
	}
}

@:router
@:routes([scope("/", [get("/users/:id", Main.UserController, Main.UserController.show)])])
class RouterDslMissingParamsContract {}
