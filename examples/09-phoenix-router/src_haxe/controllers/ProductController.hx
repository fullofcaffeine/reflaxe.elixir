package controllers;

import elixir.types.Term;

/**
 * Product controller with nested review routes.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("PhoenixRouterWeb.ProductController")
// @:controller: marks this module as a Phoenix controller for HTTP actions.
@:controller
class ProductController {
	public static function index():String {
		return "List all products";
	}

	public static function show(id:Int):String {
		return "Show product " + id;
	}

	// @:route: attaches route metadata to this action/function (legacy/manual route style).
	@:route({method: "GET", path: "/products/:product_id/reviews", as: "product_reviews"})
	public static function reviews(product_id:Int):String {
		return "Reviews for product " + product_id;
	}

	@:route({method: "POST", path: "/products/:product_id/reviews"})
	public static function create_review(product_id:Int, review:Term):String {
		return "Create review for product " + product_id;
	}

	public static function create(product:Term):String {
		return "Create new product";
	}

	public static function update(id:Int, product:Term):String {
		return "Update product " + id;
	}

	public static function delete(id:Int):String {
		return "Delete product " + id;
	}
}
