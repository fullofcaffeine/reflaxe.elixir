package;

/**
 * Router compiler test case
 *
 * WHAT
 * - Validates metadata-driven router generation via `@:routes` on an `@:router` module.
 *
 * WHY
 * - Router generation is driven by explicit route metadata rather than hard-coded app heuristics.
 *
 * HOW
 * - `ElixirCompiler` extracts `@:routes` into `ElixirMetadata.routerRoutes`.
 * - `AnnotationTransforms.routerTransformPass` emits Phoenix.Router DSL from that metadata.
 */
class TodoLive {
	public static function index():String {
		return "index";
	}

	public static function show():String {
		return "show";
	}

	public static function edit():String {
		return "edit";
	}
}

class UserController {
	public static function index():String {
		return "index";
	}

	public static function create():String {
		return "create";
	}
}

@:router
@:routes([
	{
		name: "root",
		method: "LIVE",
		path: "/",
		controller: TodoLive,
		action: TodoLive.index
	},
	{
		name: "todosIndex",
		method: "LIVE",
		path: "/todos",
		controller: TodoLive,
		action: TodoLive.index
	},
	{
		name: "todosShow",
		method: "LIVE",
		path: "/todos/:id",
		controller: TodoLive,
		action: TodoLive.show
	},
	{
		name: "todosEdit",
		method: "LIVE",
		path: "/todos/:id/edit",
		controller: TodoLive,
		action: TodoLive.edit
	},
	{
		name: "apiUsersIndex",
		method: "GET",
		path: "/api/users",
		controller: UserController,
		action: UserController.index
	},
	{
		name: "apiUsersCreate",
		method: "POST",
		path: "/api/users",
		controller: UserController,
		action: UserController.create
	},
	{
		name: "dashboard",
		method: "LIVE_DASHBOARD",
		path: "/dev/dashboard"
	}
])
class MyAppRouter {}
