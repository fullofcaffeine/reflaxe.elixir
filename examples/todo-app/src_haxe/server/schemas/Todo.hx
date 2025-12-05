package server.schemas;

import phoenix.Ecto;

/**
 * Todo schema for task management
 *
 * Provides the core todo model with priority, due dates, and tags.
 * Supports user association for multi-user todo lists.
 */
typedef TodoParams = {
    ?title: String,
    ?description: String,
    ?completed: Bool,
    ?priority: String,
    ?dueDate: Dynamic,  // Can be Date, String, or null
    ?tags: Dynamic,     // Can be Array<String>, String, or null
    ?userId: Int
}

@:native("TodoApp.Todo")
@:schema("todos")
@:timestamps
@:keep
class Todo {
    @:field @:primary_key public var id: Int;
    @:field public var title: String;
    @:field public var description: String;
    @:field public var completed: Bool = false;
    @:field public var priority: String = "medium";
    @:field public var dueDate: Dynamic;
    @:field public var tags: Dynamic;
    @:field public var userId: Int;

    public function new() {
        this.completed = false;
        this.priority = "medium";
    }

    /**
     * Standard changeset for creating and updating todos
     * Uses native Elixir to ensure proper Ecto.Changeset.cast/3 call
     * NOTE: @:changeset removed to use custom __elixir__ implementation
     */
    @:keep
    public static function changeset(todo: Dynamic, params: Dynamic): Dynamic {
        return untyped __elixir__('
            {0}
            |> Ecto.Changeset.cast({1}, [:title, :description, :completed, :priority, :due_date, :tags, :user_id])
            |> Ecto.Changeset.validate_required([:title])
            |> Ecto.Changeset.validate_length(:title, min: 1, max: 200)
        ', todo, params);
    }

    /**
     * Toggle the completed status of a todo
     * Uses native Elixir API for simple change without validation
     */
    @:changeset
    public static function toggleCompleted(todo: Dynamic): Dynamic {
        var currentCompleted: Bool = todo.completed;
        return untyped __elixir__('Ecto.Changeset.change({0}, %{completed: {1}})', todo, !currentCompleted);
    }

    /**
     * Update the priority of a todo
     */
    @:changeset
    public static function updatePriority(todo: Dynamic, priority: String): Dynamic {
        return untyped __elixir__('Ecto.Changeset.change({0}, %{priority: {1}})', todo, priority);
    }

    /**
     * Add a tag to a todo's tags array
     */
    public static function addTag(todo: Dynamic, tag: String): Dynamic {
        return untyped __elixir__('
            current_tags = {0}.tags || []
            new_tags = if {1} in current_tags, do: current_tags, else: current_tags ++ [{1}]
            Ecto.Changeset.change({0}, %{tags: new_tags})
        ', todo, tag);
    }

    /**
     * Remove a tag from a todo's tags array
     */
    public static function removeTag(todo: Dynamic, tag: String): Dynamic {
        return untyped __elixir__('
            current_tags = {0}.tags || []
            new_tags = Enum.filter(current_tags, fn t -> t != {1} end)
            Ecto.Changeset.change({0}, %{tags: new_tags})
        ', todo, tag);
    }

    /**
     * Create a new todo with default values
     */
    public static function createNew(title: String, ?userId: Int): Dynamic {
        return {
            title: title,
            description: "",
            completed: false,
            priority: "medium",
            dueDate: null,
            tags: [],
            userId: userId
        };
    }
}
