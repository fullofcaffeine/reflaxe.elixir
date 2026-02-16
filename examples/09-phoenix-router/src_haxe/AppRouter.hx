package;

import controllers.ProductController;
import controllers.UserController;
import reflaxe.elixir.macros.RouterDsl.*;

typedef UserIdPathParams = {
	var id:Int;
}

typedef ProductIdPathParams = {
	var id:Int;
}

typedef ProductReviewPathParams = {
	var product_id:Int;
}

/**
 * Main Phoenix router configuration
 * Demonstrates module-level typed router DSL with typed controller/action references.
 */
// @:native: pins emitted naming to a specific Elixir symbol/module.

@:native("PhoenixRouterWeb.Router")
// @:router: marks this module as a Phoenix router and enables route emission transforms.
@:router
final routes = [
	pipeline("browser", [plug("accepts", {initArgs: ["html"]}), plug("fetch_session")]),
	scope("/", [
		pipeThrough(["browser"]),
		get("/users", UserController, UserController.index),
		get("/users/:id", UserController, UserController.show,
			{
				paramsContract: UserIdPathParams
			}),
		post("/users", UserController, UserController.create),
		put("/users/:id", UserController, UserController.update, {paramsContract: UserIdPathParams}),
		delete("/users/:id", UserController, UserController.delete, {paramsContract: UserIdPathParams}),
		get("/products", ProductController, ProductController.index),
		get("/products/:id", ProductController, ProductController.show, {paramsContract: ProductIdPathParams}),
		post("/products", ProductController, ProductController.create),
		put("/products/:id", ProductController, ProductController.update, {paramsContract: ProductIdPathParams}),
		delete("/products/:id", ProductController, ProductController.delete, {paramsContract: ProductIdPathParams}),
		get("/products/:product_id/reviews", ProductController, ProductController.reviews, {
			paramsContract: ProductReviewPathParams
		}),
		post("/products/:product_id/reviews", ProductController, ProductController.create_review, {
			paramsContract: ProductReviewPathParams
		})
	])
];

class AppRouter {
	public static function main():Void {
		trace("Phoenix Router DSL Example - App Router (typed routes)");
	}
}
