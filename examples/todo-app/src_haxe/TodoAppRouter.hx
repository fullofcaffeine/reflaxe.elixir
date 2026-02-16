package;

import controllers.GithubOAuthController;
import controllers.MockOAuthController;
import controllers.SessionController;
import controllers.UserController;
import reflaxe.elixir.macros.RouterDsl.*;
import server.live.AdminLive;
import server.live.AuditLogLive;
import server.live.AuthLive;
import server.live.InlineMarkupLive;
import server.live.OrganizationLive;
import server.live.ProfileLive;
import server.live.TodoLive;
import server.live.UsersLive;

typedef TodoIdPathParams = {
	var id:Int;
}

typedef UserIdPathParams = {
	var id:Int;
}

/**
 * Type-safe Router DSL example demonstrating module-level typed route declarations.
 */
// @:native: pins emitted naming to a specific Elixir symbol/module.

@:native("TodoAppWeb.Router")
// @:router: marks this module as a Phoenix router and enables route emission transforms.
@:router
final routes = [
	pipeline("browser", [
		plug("accepts", {initArgs: ["html"]}),
		plug("fetch_session"),
		plug("fetch_live_flash"),
		plug("protect_from_forgery"),
		plug("put_secure_browser_headers")
	]),
	pipeline("api", [plug("accepts", {initArgs: ["json"]})]),
	scope("/", [
		pipeThrough(["browser"]),
		// Live routes
		liveSession("default", [
			live("/", TodoLive, TodoLive.index),
			live("/login", AuthLive, AuthLive.index),
			live("/profile", ProfileLive, ProfileLive.show),
			live("/org", OrganizationLive, OrganizationLive.index),
			live("/users", UsersLive, UsersLive.index),
			live("/admin", AdminLive, AdminLive.index),
			live("/admin/audit", AuditLogLive, AuditLogLive.index),
			live("/todos", TodoLive, TodoLive.index),
			live("/todos/:id", TodoLive, TodoLive.show,
				{
					paramsContract: TodoIdPathParams
				}),
			live("/todos/:id/edit", TodoLive, TodoLive.edit, {paramsContract: TodoIdPathParams}),
			live("/dev/inline-markup", InlineMarkupLive, InlineMarkupLive.index)
		]),
		// Session/OAuth endpoints
		post("/auth/login", SessionController, SessionController.create),
		get("/auth/github", GithubOAuthController, GithubOAuthController.github),
		get("/auth/github/callback", GithubOAuthController, GithubOAuthController.github_callback),
		get("/auth/mock", MockOAuthController, MockOAuthController.mock),
		get("/auth/mock/callback", MockOAuthController, MockOAuthController.mock_callback),
		post("/auth/logout", SessionController, SessionController.delete),
		// Dev-only helpers
		liveDashboard("/dev/dashboard"),
		mailbox("/dev/mailbox")
	]),
	// JSON API endpoints (admin-only; scoped by session org)
	scope("/api", [
		pipeThrough(["api"]),
		get("/users", UserController, UserController.index),
		get("/users/:id", UserController, UserController.show, {paramsContract: UserIdPathParams}),
		post("/users", UserController, UserController.create),
		put("/users/:id", UserController, UserController.update, {paramsContract: UserIdPathParams}),
		delete("/users/:id", UserController, UserController.delete, {paramsContract: UserIdPathParams})
	])
];
