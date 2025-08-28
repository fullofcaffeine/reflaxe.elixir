package;

/**
 * Router compiler test case
 * Tests Phoenix router compilation
 */
@:router
class MyAppRouter {
	// Basic routes
	public static function routes(): Array<Route> {
		return [
			// HTTP routes
			get("/", PageController, "index"),
			get("/about", PageController, "about"),
			get("/contact", PageController, "contact"),
			post("/contact", PageController, "submit_contact"),
			
			// RESTful resource
			resources("/users", UserController),
			resources("/posts", PostController, ["only" => ["index", "show"]]),
			resources("/comments", CommentController, ["except" => ["delete"]]),
			
			// Nested resources
			resources("/users", UserController, null, function() {
				resources("/posts", PostController);
				resources("/settings", SettingsController, ["singleton" => true]);
			}),
			
			// API scope
			scope("/api", ["alias" => "Api"], function() {
				pipe_through("api");
				
				get("/status", StatusController, "index");
				resources("/users", UserController, ["as" => "api_user"]);
				
				scope("/v1", ["alias" => "V1"], function() {
					resources("/products", ProductController);
					resources("/orders", OrderController);
				});
			}),
			
			// LiveView routes
			live("/dashboard", DashboardLive, "index"),
			live("/users/:id", UserLive.Show, "show"),
			live("/users/:id/edit", UserLive.Edit, "edit"),
			
			// Live session with authentication
			live_session(["on_mount" => "authenticated"], function() {
				live("/profile", ProfileLive, "index");
				live("/settings", SettingsLive, "index");
			}),
			
			// Pipelines
			pipeline("browser", [
				accepts(["html"]),
				fetch_session(),
				fetch_live_flash(),
				put_root_layout([MyAppWeb.LayoutView, "root.html"]),
				protect_from_forgery(),
				put_secure_browser_headers()
			]),
			
			pipeline("api", [
				accepts(["json"]),
				plug(MyAppWeb.APIAuthPlug)
			]),
			
			// Forward to another router
			forward("/admin", AdminRouter),
			
			// Catch-all route
			match("*path", ErrorController, "not_found")
		];
	}
	
	// Helper types (would be provided by router compiler)
	private static function get(path: String, controller: Dynamic, action: String): Route { return null; }
	private static function post(path: String, controller: Dynamic, action: String): Route { return null; }
	private static function put(path: String, controller: Dynamic, action: String): Route { return null; }
	private static function patch(path: String, controller: Dynamic, action: String): Route { return null; }
	private static function delete(path: String, controller: Dynamic, action: String): Route { return null; }
	private static function resources(path: String, controller: Dynamic, ?opts: Dynamic, ?callback: Dynamic): Route { return null; }
	private static function scope(path: String, opts: Dynamic, callback: Dynamic): Route { return null; }
	private static function live(path: String, module: Dynamic, action: String): Route { return null; }
	private static function live_session(opts: Dynamic, callback: Dynamic): Route { return null; }
	private static function pipeline(name: String, plugs: Array<Dynamic>): Route { return null; }
	private static function pipe_through(pipeline: String): Route { return null; }
	private static function forward(path: String, router: Dynamic): Route { return null; }
	private static function match(path: String, controller: Dynamic, action: String): Route { return null; }
	private static function accepts(types: Array<String>): Dynamic { return null; }
	private static function fetch_session(): Dynamic { return null; }
	private static function fetch_live_flash(): Dynamic { return null; }
	private static function put_root_layout(layout: Dynamic): Dynamic { return null; }
	private static function protect_from_forgery(): Dynamic { return null; }
	private static function put_secure_browser_headers(): Dynamic { return null; }
	private static function plug(module: Dynamic): Dynamic { return null; }
}

// Mock types
typedef Route = Dynamic;
class PageController {}
class UserController {}
class PostController {}
class CommentController {}
class SettingsController {}
class StatusController {}
class ProductController {}
class OrderController {}
class DashboardLive {}
class UserLive {
	public static var Show: Dynamic;
	public static var Edit: Dynamic;
}
class ProfileLive {}
class SettingsLive {}
class AdminRouter {}
class ErrorController {}
class MyAppWeb {
	public static var LayoutView: Dynamic;
	public static var APIAuthPlug: Dynamic;
}