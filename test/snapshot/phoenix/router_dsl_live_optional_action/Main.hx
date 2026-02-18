package;

import reflaxe.elixir.macros.RouterDsl.*;

/**
 * WHAT
 * - Verifies typed router DSL supports `live(path, LiveModule)` without an explicit action.
 * - Verifies optional opts can be passed as the 3rd arg when action is omitted.
 *
 * WHY
 * - Phoenix allows live routes without `:action`.
 * - This avoids placeholder `index/show/edit` methods on LiveView modules.
 */
typedef TodoPathParams = {
	var id:Int;
}

class DashboardLive {}
class TodoLive {}

@:native("LiveOptionalActionRouter")
@:router
final routes = [
	pipeline("browser", [plug("accepts", {initArgs: ["html"]}), plug("fetch_session")]),
	scope("/", [
		pipeThrough(["browser"]),
		liveSession("default", [
			live("/", DashboardLive),
			live("/todos/:id", TodoLive, {
				paramsContract: TodoPathParams
			})
		])
	])
];
