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
@:router
@:routes([
	{
		name: "root",
		method: "LIVE",
		path: "/",
		controller: "TodoLive",
		action: "index"
	},
	{
		name: "todosIndex",
		method: "LIVE",
		path: "/todos",
		controller: "TodoLive",
		action: "index"
	},
	{
		name: "todosShow",
		method: "LIVE",
		path: "/todos/:id",
		controller: "TodoLive",
		action: "show"
	},
	{
		name: "todosEdit",
		method: "LIVE",
		path: "/todos/:id/edit",
		controller: "TodoLive",
		action: "edit"
	},
	{
		name: "apiUsersIndex",
		method: "GET",
		path: "/api/users",
		controller: "UserController",
		action: "index"
	},
	{
		name: "apiUsersCreate",
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
class MyAppRouter {
}
