package;

import reflaxe.elixir.macros.HttpMethod;
import reflaxe.elixir.macros.RouterDsl.*;

/**
 * WHAT
 * - Validates typed/nested `RouterDsl.*` route declarations under module-level `final routes`.
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

@:native("RouterDslTypedNested")
@:router
final routes = [
	pipeline(browser, [plug(accepts, {initArgs: ["html"]}), plug(fetch_session)]),
	pipeline(api, [plug(accepts, {initArgs: ["json"]})]),
	scope("/", [
		pipeThrough([browser]),
		liveSession("default", [
			live("/", DashboardLive, DashboardLive.index),
			get("/users/:id", UserController, UserController.show,
				{
					paramsContract: UserPathParams
				})
		],
			{session: liveSessionMfa(MyAppWeb, "live_session")}),
		resources("/users", UserController, {only: [resourceIndex, resourceShow]}),
		resources("/legacy-users", UserController, {except: ["delete"]}),
		forward("/admin", AdminRouter),
		liveDashboard("/dashboard"),
		mailbox("/mailbox")
	], {aliasModule: MyAppWeb}),
	scope("/api", [
		pipeThrough([api]),
		match(HttpMethod.GET, "/events", ApiController, ApiController.index),
		options("/events", ApiController, ApiController.options),
		head("/events", ApiController, ApiController.head),
		connect("/events", ApiController, ApiController.connect),
		trace("/events", ApiController, ApiController.trace)
	])
];
