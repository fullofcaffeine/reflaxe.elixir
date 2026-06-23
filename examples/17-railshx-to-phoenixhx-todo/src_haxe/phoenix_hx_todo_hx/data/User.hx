package phoenix_hx_todo_hx.data;

import ecto.Changeset;
import elixir.types.Term;

typedef UserParams = {
	?name:String,
	?email:String
}

/**
 * Demo user schema.
 *
 * WHAT
 * - Small user table for the example's Phoenix session flow.
 *
 * WHY
 * - RailsHx reaches for Devise in the Rails sample. This example demonstrates the
 *   Phoenix shape without copying Rails auth APIs or adding a full password stack.
 */
@:native("PhoenixHxTodo.User")
@:schema("users")
@:timestamps
@:changeset(["name", "email"], ["name", "email"])
class User {
	@:field @:primary_key public var id:Int;
	@:field public var name:String;
	@:field public var email:String;

	public function new() {}

	public static function displayName(user:User):String {
		return user.name != null && user.name != "" ? user.name : user.email;
	}
}
