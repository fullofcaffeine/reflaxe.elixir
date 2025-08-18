package server.schemas;

import phoenix.Ecto;

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
	@:field public var due_date: Dynamic; // Date type
	@:field public var tags: Array<String> = [];
	@:field public var user_id: Int;
	
	public function new() {
		this.tags = [];
		this.completed = false;
		this.priority = "medium";
	}
	
	@:changeset
	public static function changeset(todo: Todo, params: phoenix.Ecto.ChangesetParams): phoenix.Ecto.Changeset<Todo> {
		// Validation pipeline using correct Ecto method names
		var changeset = phoenix.Ecto.EctoChangeset.castChangeset(todo, params, ["title", "description", "completed", "priority", "due_date", "tags", "user_id"]);
		changeset = phoenix.Ecto.EctoChangeset.validate_required(changeset, ["title", "user_id"]);
		changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "title", {min: 3, max: 200});
		changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "description", {max: 1000});
		// Fix: Use proper ChangesetValue array instead of string array
		var priorityValues = [phoenix.Ecto.ChangesetValue.StringValue("low"), phoenix.Ecto.ChangesetValue.StringValue("medium"), phoenix.Ecto.ChangesetValue.StringValue("high")];
		changeset = phoenix.Ecto.EctoChangeset.validate_inclusion(changeset, "priority", priorityValues);
		changeset = phoenix.Ecto.EctoChangeset.foreign_key_constraint(changeset, "user_id");
		return changeset;
	}
	
	// Helper functions for business logic with proper types
	public static function toggle_completed(todo: Todo): phoenix.Ecto.Changeset<Todo> {
		var params = new Map<String, phoenix.Ecto.ChangesetValue>();
		params.set("completed", phoenix.Ecto.ChangesetValue.BoolValue(!todo.completed));
		return changeset(todo, params);
	}
	
	public static function update_priority(todo: Todo, priority: String): phoenix.Ecto.Changeset<Todo> {
		var params = new Map<String, phoenix.Ecto.ChangesetValue>();
		params.set("priority", phoenix.Ecto.ChangesetValue.StringValue(priority));
		return changeset(todo, params);
	}
	
	public static function add_tag(todo: Todo, tag: String): phoenix.Ecto.Changeset<Todo> {
		var tags: Array<String> = todo.tags != null ? todo.tags : [];
		tags.push(tag);
		var params = new Map<String, phoenix.Ecto.ChangesetValue>();
		params.set("tags", phoenix.Ecto.ChangesetValue.ArrayValue(tags.map(t -> phoenix.Ecto.ChangesetValue.StringValue(t))));
		return changeset(todo, params);
	}
}