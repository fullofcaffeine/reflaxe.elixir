package phoenix_hx_todo_hx.data;

import ecto.Changeset;

typedef TodoParams = {
	?title:String,
	?notes:String,
	?completed:Bool,
	?userId:Int
}

/**
 * Todo schema for the PhoenixHx port.
 *
 * WHAT
 * - Ecto-backed task row scoped to the signed-in demo user.
 *
 * WHY
 * - The RailsHx app maps form params to ActiveRecord. In Phoenix, the idiomatic
 *   target boundary is Ecto schema + changeset + context function.
 */
@:native("PhoenixHxTodo.Todo")
@:schema("todos")
@:timestamps
@:changeset(["title", "notes", "completed", "userId"], ["title", "userId"])
class Todo {
	@:field @:primary_key public var id:Int;
	@:field public var title:String;
	@:field public var notes:String;
	@:field public var completed:Bool = false;
	@:field public var userId:Int;

	public function new() {
		this.completed = false;
	}

	public static function toggleCompleted(todo:Todo):Changeset<Todo, {completed:Bool}> {
		return ecto.Changeset.change(todo, {completed: !todo.completed});
	}
}
