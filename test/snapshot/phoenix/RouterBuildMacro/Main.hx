package;

/**
 * Test RouterBuildMacro legacy declarative router syntax.
 * 
 * This intentionally keeps string controller/action metadata to cover the
 * compatibility path. New router code should use module-level `final routes`
 * with `RouterDsl.*`, or typed flat @:routes refs while migrating.
 */
@:router
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
@:routes([
	{
		name: "home",
		method: "LIVE",
		path: "/",
		controller: "PageLive",
		action: "index"
	},
	{
		name: "users",
		method: "LIVE",
		path: "/users",
		controller: "UserLive",
		action: "index"
	},
	{
		name: "userShow",
		method: "LIVE",
		path: "/users/:id",
		controller: "UserLive",
		action: "show"
	},
	{
		name: "apiUsers",
		method: "GET",
		path: "/api/users",
		controller: "UserController",
		action: "index"
	},
	{
		name: "createUser",
		method: "POST",
		path: "/api/users",
		controller: "UserController",
		action: "create"
	},
	{
		name: "dashboard",
		method: "LIVE_DASHBOARD",
		path: "/dev/dashboard"
	}
])
class AppRouter {
	// Auto-generated functions will be created here by RouterBuildMacro:
	//
	// @:route({method: "LIVE", path: "/", controller: "PageLive", action: "index"})
	// public static function home(): String { return "/"; }
	//
	// @:route({method: "LIVE", path: "/users", controller: "UserLive", action: "index"})
	// public static function users(): String { return "/users"; }
	//
	// ... etc for all 6 routes
}
