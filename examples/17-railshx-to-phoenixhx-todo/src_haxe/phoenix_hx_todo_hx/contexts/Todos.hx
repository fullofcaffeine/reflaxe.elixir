package phoenix_hx_todo_hx.contexts;

import StringTools;
import ecto.Changeset;
import ecto.SchemaStruct;
import ecto.TypedQuery;
import elixir.Enum;
import elixir.types.Term;
import haxe.functional.Result;
import phoenix_hx_todo_hx.data.Todo;
import phoenix_hx_todo_hx.data.User;
import phoenix_hx_todo_hx.infrastructure.Repo;
import phoenix_hx_todo_hx.live.AppLiveTypes.TodoItem;
import phoenix_hx_todo_hx.live.AppLiveTypes.TodoStats;
import phoenix_hx_todo_hx.live.TodoState;

using reflaxe.elixir.macros.TypedQueryLambda;

/**
 * Todos context.
 *
 * WHAT
 * - Owns all Ecto-backed todo mutations for the example.
 *
 * WHY
 * - RailsHx can place most CRUD close to an ActiveRecord model/controller pair.
 *   Phoenix code is clearer when LiveView delegates persistence to a context.
 */
@:native("PhoenixHxTodo.Todos")
class Todos {
	public static function listForUser(userId:Int):Array<Todo> {
		var query = TypedQuery.from(Todo).where(todo -> todo.userId == userId);
		var todos:Array<Todo> = Repo.all(query);
		todos.sort((left, right) -> right.id - left.id);
		return todos;
	}

	static function getForUser(userId:Int, id:Int):Null<Todo> {
		var query = TypedQuery.from(Todo).where(todo -> todo.userId == userId && todo.id == id);
		var todos:Array<Todo> = Repo.all(query);
		return Enum.at(todos, 0);
	}

	public static function createForUser(user:User, title:String, notes:String):Result<Todo, Changeset<Todo, Term>> {
		var trimmedTitle = StringTools.trim(title);
		var trimmedNotes = StringTools.trim(notes);
		var data = SchemaStruct.empty(Todo);
		var params:Term = {
			title: trimmedTitle,
			notes: trimmedNotes,
			completed: false,
			userId: user.id
		};
		return Repo.insert(Todo.changeset(data, params));
	}

	public static function toggleForUser(userId:Int, id:Int):Bool {
		var todo = getForUser(userId, id);
		if (todo == null)
			return false;
		return switch (Repo.update(Todo.toggleCompleted(todo))) {
			case Ok(_): true;
			case Error(_): false;
		};
	}

	public static function deleteForUser(userId:Int, id:Int):Bool {
		var todo = getForUser(userId, id);
		if (todo == null)
			return false;
		return switch (Repo.delete(todo)) {
			case Ok(_): true;
			case Error(_): false;
		};
	}

	public static function seedDefaultsForUser(user:User):Void {
		if (listForUser(user.id).length > 0)
			return;

		var defaults = TodoState.seed(User.displayName(user));
		for (item in defaults) {
			switch (createForUser(user, item.title, item.notes)) {
				case Ok(created):
					if (item.completed) {
						Repo.update(Todo.toggleCompleted(created));
					}
				case Error(_):
			}
		}
	}

	public static function viewItemsForUser(user:User):Array<TodoItem> {
		return listForUser(user.id).map(todo -> TodoState.item(todo.id, todo.title, todo.notes, User.displayName(user), todo.completed));
	}

	public static function statsForUser(user:User):TodoStats {
		return TodoState.stats(viewItemsForUser(user));
	}
}
