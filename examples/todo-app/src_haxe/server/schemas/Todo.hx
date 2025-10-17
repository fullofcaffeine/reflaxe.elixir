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
	?dueDate: Date,
	?tags: Array<String>,
	?userId: Int
}

/**
 * Todo schema for managing tasks
 */
@:native("TodoApp.Todo")
@:schema("todos")
@:timestamps
class Todo {
	@:field public var id: Int;
	@:field public var title: String;
	@:field public var description: String;
	@:field public var completed: Bool = false;
	@:field public var priority: String = "medium"; // low, medium, high
	@:field public var dueDate: Null<Date>; // Type-safe nullable Date
	@:field public var tags: Array<String> = [];
	@:field public var userId: Int;
	
	public function new() {
		this.tags = [];
		this.completed = false;
		this.priority = "medium";
	}
	
    @:changeset
    public static function changeset(todo: Todo, params: TodoParams): Changeset<Todo, TodoParams> {
        // Build and return changeset without local binding to avoid hygiene drops
        return new Changeset(todo, params)
            .validateRequired(["title", "userId"]) 
            .validateLength("title", {min: 3, max: 200})
            .validateLength("description", {max: 1000});
    }
	
	
	// Helper functions for business logic with proper types
	public static function toggleCompleted(todo: Todo): Changeset<Todo, TodoParams> {
		var params: TodoParams = {
			completed: !todo.completed
		};
		return changeset(todo, params);
	}
	
	public static function updatePriority(todo: Todo, priority: String): Changeset<Todo, TodoParams> {
		var params: TodoParams = {
			priority: priority
		};
		return changeset(todo, params);
	}
	
	public static function addTag(todo: Todo, tag: String): Changeset<Todo, TodoParams> {
		var tags: Array<String> = todo.tags != null ? todo.tags.copy() : [];
		tags.push(tag);
		var params: TodoParams = {
			tags: tags
		};
		return changeset(todo, params);
	}
}
