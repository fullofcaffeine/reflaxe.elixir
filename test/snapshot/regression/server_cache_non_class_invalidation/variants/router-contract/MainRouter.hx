import reflaxe.elixir.macros.RouterDsl.*;

/**
 * A controller for the route below. It shares this file with the router.
 */
class CacheController {
	public static function index():String
		return "ok";
}

/**
 * A router that names its params contract by full path, without an import.
 * The routes are never typed, so only the compiler reads the contract.
 */
@:native("ServerCacheWeb.Router")
@:router
final routes = [
	pipeline(api, [plug(accepts, {initArgs: ["json"]})]),
	scope("/api", [
		pipeThrough([api]),
		get("/users/:id", CacheController, CacheController.index, {paramsContract: Contracts.UserIdPathParams})
	])
];
