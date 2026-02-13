package controllers;

import elixir.types.Term;

/**
 * Phoenix controller with @:route annotations
 * Demonstrates RESTful route generation and parameter handling
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("PhoenixRouterWeb.UserController")
// @:controller: marks this module as a Phoenix controller for HTTP actions.
@:controller
class UserController {
	// @:route: attaches route metadata to this action/function (legacy/manual route style).
	@:route({method: "GET", path: "/users"})
	public static function index():String {
		return "List all users";
	}

	@:route({method: "GET", path: "/users/:id"})
	public static function show(id:Int):String {
		return "Show user " + id;
	}

	@:route({method: "POST", path: "/users"})
	public static function create(user:Term):String {
		return "Create new user";
	}

	@:route({method: "PUT", path: "/users/:id"})
	public static function update(id:Int, user:Term):String {
		return "Update user " + id;
	}

	@:route({method: "DELETE", path: "/users/:id"})
	public static function delete(id:Int):String {
		return "Delete user " + id;
	}

	public static function main() {
		trace("Phoenix Router DSL Example - User Controller");
	}
}
