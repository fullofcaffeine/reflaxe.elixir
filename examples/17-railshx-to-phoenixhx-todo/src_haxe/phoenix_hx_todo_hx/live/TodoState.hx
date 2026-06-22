package phoenix_hx_todo_hx.live;

import StringTools;
import phoenix_hx_todo_hx.live.AppLiveTypes.TodoItem;
import phoenix_hx_todo_hx.live.AppLiveTypes.TodoStats;

@:native("PhoenixHxTodoHx.Live.TodoState")
class TodoState {
	public static function seed(owner:String):Array<TodoItem> {
		return [
			item(1, "Ship typed Rails templates", "Port the HHX partial shape to inline HXX components.", owner, false),
			item(2, "Map strong params to changesets", "Document where Phoenix validates data differently.", owner, false),
			item(3, "Compare Turbo Streams and LiveView", "Keep DOM ownership on the server in both versions.", owner, true)
		];
	}

	public static function create(todos:Array<TodoItem>, id:Int, title:String, notes:String, owner:String):Array<TodoItem> {
		var trimmedTitle = StringTools.trim(title);
		if (trimmedTitle == "")
			return todos;
		var trimmedNotes = StringTools.trim(notes);
		return [item(id, trimmedTitle, trimmedNotes, owner, false)].concat(todos);
	}

	public static function toggle(todos:Array<TodoItem>, id:Int):Array<TodoItem> {
		return todos.map(todo -> {
			if (todo.id != id)
				return todo;
			return item(todo.id, todo.title, todo.notes, todo.owner, !todo.completed);
		});
	}

	public static function deleteById(todos:Array<TodoItem>, id:Int):Array<TodoItem> {
		return todos.filter(todo -> todo.id != id);
	}

	public static function stats(todos:Array<TodoItem>):TodoStats {
		var open = 0;
		var completed = 0;
		for (todo in todos) {
			if (todo.completed)
				completed++;
			else
				open++;
		}
		return {
			open_count: open,
			completed_count: completed,
			typed_column_count: 5
		};
	}

	public static function item(id:Int, title:String, notes:String, owner:String, completed:Bool):TodoItem {
		return {
			id: id,
			title: title,
			notes: notes,
			owner: owner,
			completed: completed,
			row_class: completed ? "todo-item is-complete" : "todo-item"
		};
	}
}
