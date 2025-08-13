package schemas;

import phoenix.Ecto;

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
	
	public function new() {
		this.tags = [];
		this.completed = false;
		this.priority = "medium";
	}
	
	@:changeset
	public static function changeset(todo: Dynamic, params: Dynamic): Dynamic {
		// Validation pipeline using Haxe syntax (avoiding 'cast' keyword)
		var changeset = phoenix.Ecto.EctoChangeset.changeset_cast(todo, params, ["title", "description", "completed", "priority", "due_date", "tags", "user_id"]);
		changeset = phoenix.Ecto.EctoChangeset.validate_required(changeset, ["title", "user_id"]);
		changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "title", {min: 3, max: 200});
		changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "description", {max: 1000});
		changeset = phoenix.Ecto.EctoChangeset.validate_inclusion(changeset, "priority", ["low", "medium", "high"]);
		changeset = phoenix.Ecto.EctoChangeset.foreign_key_constraint(changeset, "user_id");
		return changeset;
	}
	
	// Helper functions for business logic
	public static function toggle_completed(todo: Dynamic): Dynamic {
		return changeset(todo, {completed: !todo.completed});
	}
	
	public static function update_priority(todo: Dynamic, priority: String): Dynamic {
		return changeset(todo, {priority: priority});
	}
	
	public static function add_tag(todo: Dynamic, tag: String): Dynamic {
		var tags: Array<String> = todo.tags != null ? todo.tags : [];
		tags.push(tag);
		return changeset(todo, {tags: tags});
	}
}