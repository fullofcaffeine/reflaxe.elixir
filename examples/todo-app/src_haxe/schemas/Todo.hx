package schemas;

/**
 * Todo schema for managing tasks
 */
@:schema
class Todo {
	@:field public var id: Int;
	@:field public var title: String;
	@:field public var description: String;
	@:field public var completed: Bool = false;
	@:field public var priority: String = "medium"; // low, medium, high
	@:field public var due_date: Dynamic; // Date type
	@:field public var tags: Array<String> = [];
	@:field public var user_id: Int;
	
	@:timestamps public var inserted_at: Dynamic;
	@:timestamps public var updated_at: Dynamic;
	
	@:belongs_to("schemas.User") 
	public var user: Dynamic;
	
	@:changeset
	public static function changeset(todo: Dynamic, params: Dynamic): Dynamic {
		// Validation pipeline
		return todo
			.cast(params, ["title", "description", "completed", "priority", "due_date", "tags", "user_id"])
			.validate_required(["title", "user_id"])
			.validate_length("title", {min: 3, max: 200})
			.validate_length("description", {max: 1000})
			.validate_inclusion("priority", ["low", "medium", "high"])
			.foreign_key_constraint("user_id");
	}
	
	// Helper functions for business logic
	public static function toggle_completed(todo: Dynamic): Dynamic {
		return changeset(todo, {completed: !todo.completed});
	}
	
	public static function update_priority(todo: Dynamic, priority: String): Dynamic {
		return changeset(todo, {priority: priority});
	}
	
	public static function add_tag(todo: Dynamic, tag: String): Dynamic {
		var tags = todo.tags || [];
		tags.push(tag);
		return changeset(todo, {tags: tags});
	}
}