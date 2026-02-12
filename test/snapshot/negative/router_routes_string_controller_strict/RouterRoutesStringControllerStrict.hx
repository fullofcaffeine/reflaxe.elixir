package;

/**
 * Negative test: strict router typed refs mode rejects string controller literals in @:routes.
 */
class UserController {
	public static function index():String {
		return "ok";
	}
}

@:router
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
