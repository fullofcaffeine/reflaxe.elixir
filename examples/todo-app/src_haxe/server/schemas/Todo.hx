package server.schemas;

import ecto.Changeset;
import haxe.ds.Option;

/**
 * Parameters for Todo changeset operations.
 * Strongly typed to avoid Dynamic usage.
 */
typedef TodoParams = {
	?title: String,
	?description: String,
	?completed: Bool,
	?priority: String,
	?due_date: Date,
	?tags: Array<String>,
	?user_id: Int
}

/**
 * Todo schema for managing tasks
 */
@:schema
@:timestamps
class Todo {
	@:field public var id: Int;
	@:field public var title: String;
	@:field public var description: String;
	@:field public var completed: Bool = false;
	@:field public var priority: String = "medium"; // low, medium, high
	@:field public var due_date: Null<Date>; // Type-safe nullable Date
	@:field public var tags: Array<String> = [];
	@:field public var user_id: Int;
	
	public function new() {
		this.tags = [];
		this.completed = false;
		this.priority = "medium";
	}
	
	@:changeset
	public static function changeset(todo: Todo, params: TodoParams): Changeset<Todo, TodoParams> {
		// Create a fully typed changeset - no Dynamic!
		var cs = new Changeset(todo, params);
		return cs.validateRequired(["title", "user_id"])
			.validateLength("title", {min: 3, max: 200})
			.validateLength("description", {max: 1000});
			// Further validations will be added once macros are implemented
	}
	
	
	// Helper functions for business logic with proper types
	public static function toggle_completed(todo: Todo): Changeset<Todo, TodoParams> {
		var params: TodoParams = {
			completed: !todo.completed
		};
		return changeset(todo, params);
	}
	
	public static function update_priority(todo: Todo, priority: String): Changeset<Todo, TodoParams> {
		var params: TodoParams = {
			priority: priority
		};
		return changeset(todo, params);
	}
	
	public static function add_tag(todo: Todo, tag: String): Changeset<Todo, TodoParams> {
		var tags: Array<String> = todo.tags != null ? todo.tags.copy() : [];
		tags.push(tag);
		var params: TodoParams = {
			tags: tags
		};
		return changeset(todo, params);
	}
}