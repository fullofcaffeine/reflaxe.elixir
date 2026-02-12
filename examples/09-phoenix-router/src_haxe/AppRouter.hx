package;

import reflaxe.elixir.macros.HttpMethod;

/**
 * Main Phoenix router configuration
 * Demonstrates modern @:routes DSL with typed controller/action references.
 */
@:native("PhoenixRouterWeb.Router")
@:router
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
@:routes([
	{
		name: "usersIndex",
		method: HttpMethod.GET,
		path: "/users",
		controller: controllers.UserController,
		action: controllers.UserController.index
	},
	{
		name: "usersShow",
		method: HttpMethod.GET,
		path: "/users/:id",
		controller: controllers.UserController,
		action: controllers.UserController.show
	},
	{
		name: "usersCreate",
		method: HttpMethod.POST,
		path: "/users",
		controller: controllers.UserController,
		action: controllers.UserController.create
	},
	{
		name: "usersUpdate",
		method: HttpMethod.PUT,
		path: "/users/:id",
		controller: controllers.UserController,
		action: controllers.UserController.update
	},
	{
		name: "usersDelete",
		method: HttpMethod.DELETE,
		path: "/users/:id",
		controller: controllers.UserController,
		action: controllers.UserController.delete
	},
	{
		name: "productsIndex",
		method: HttpMethod.GET,
		path: "/products",
		controller: controllers.ProductController,
		action: controllers.ProductController.index
	},
	{
		name: "productsShow",
		method: HttpMethod.GET,
		path: "/products/:id",
		controller: controllers.ProductController,
		action: controllers.ProductController.show
	},
	{
		name: "productsCreate",
		method: HttpMethod.POST,
		path: "/products",
		controller: controllers.ProductController,
		action: controllers.ProductController.create
	},
	{
		name: "productsUpdate",
		method: HttpMethod.PUT,
		path: "/products/:id",
		controller: controllers.ProductController,
		action: controllers.ProductController.update
	},
	{
		name: "productsDelete",
		method: HttpMethod.DELETE,
		path: "/products/:id",
		controller: controllers.ProductController,
		action: controllers.ProductController.delete
	},
	{
		name: "productReviews",
		method: HttpMethod.GET,
		path: "/products/:product_id/reviews",
		controller: controllers.ProductController,
		action: controllers.ProductController.reviews
	},
	{
		name: "productReviewsCreate",
		method: HttpMethod.POST,
		path: "/products/:product_id/reviews",
		controller: controllers.ProductController,
		action: controllers.ProductController.create_review
	}
])
class AppRouter {
	public static function main():Void {
		trace("Phoenix Router DSL Example - App Router (typed @:routes)");
	}
}
