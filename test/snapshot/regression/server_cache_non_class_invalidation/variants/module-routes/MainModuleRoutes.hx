package;

import reflaxe.elixir.macros.RouterDsl.*;

class CacheController {
	public static function index():String {
		return "ok";
	}
}

/**
 * A module-level router declaration whose initializer is compile-time input.
 *
 * The warm-server regression edits a separately included enum. The router
 * module should remain cached while still emitting this complete declaration.
 */
@:native("ServerCacheWeb.Router")
@:router
final routes = [
	pipeline(api, [plug(accepts, {initArgs: ["json"]})]),
	scope("/api", [pipeThrough([api]), get("/status", CacheController, CacheController.index)])
];
