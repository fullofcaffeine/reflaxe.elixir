package;

import reflaxe.elixir.macros.HttpMethod;
import reflaxe.elixir.macros.RouterDsl.*;

/**
 * WHAT
 * - Validates typed/nested `RouterDsl.*` route declarations under `@:routes`.
 *
 * WHY
 * - Phoenix router structure is tree-shaped; this test proves tree-shaped Haxe input
 *   emits matching nested Phoenix router macros.
 */
typedef UserPathParams = {
	var id:Int;
}

class MyAppWeb {}

class DashboardLive {
	public static function index():String {
		return "index";
	}
}

class UserController {
	public static function index():String {
		return "index";
	}

	public static function show():String {
		return "show";
	}
}

class ApiController {
	public static function index():String {
		return "index";
	}

	public static function options():String {
		return "options";
	}

	public static function head():String {
		return "head";
	}

	public static function connect():String {
		return "connect";
	}

	public static function trace():String {
		return "trace";
	}
}

class AdminRouter {}

@:router
@:routes([
	pipeline("browser", [plug("accepts", {initArgs: ["html"]}), plug("fetch_session")]),
	pipeline("api", [plug("accepts", {initArgs: ["json"]})]),
	scope("/", [
		pipeThrough(["browser"]),
		liveSession("default",
			[
				live("/", Main.DashboardLive, Main.DashboardLive.index),
				get("/users/:id", Main.UserController, Main.UserController.show,
					{
						paramsContract: Main.UserPathParams
					})
			]),
		resources("/users", Main.UserController, {only: ["index", "show"]}),
		forward("/admin", Main.AdminRouter),
		liveDashboard("/dashboard"),
		mailbox("/mailbox")
	], {aliasModule: Main.MyAppWeb}),
	scope("/api", [
		pipeThrough(["api"]),
		match(HttpMethod.GET, "/events", Main.ApiController, Main.ApiController.index),
		options("/events", Main.ApiController, Main.ApiController.options),
		head("/events", Main.ApiController, Main.ApiController.head),
		connect("/events", Main.ApiController, Main.ApiController.connect),
		trace("/events", Main.ApiController, Main.ApiController.trace)
	])
])
class RouterDslTypedNested {}
