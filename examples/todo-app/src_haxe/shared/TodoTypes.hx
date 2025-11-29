package shared;

/**
 * Shared type definitions for Todo application
 * Used by both client (Haxe→JS) and server (Haxe→Elixir) code
 */

/**
 * Todo item data structure
 */
typedef Todo = {
    id: Int,
    title: String,
    description: Null<String>,
    completed: Bool,
    priority: TodoPriority,
    due_date: Null<String>,
    tags: Null<String>,
    user_id: Int,
    inserted_at: String,
    updated_at: String
};

/**
 * User data structure
 */
typedef User = {
    id: Int,
    name: String,
    email: String,
    inserted_at: String,
    updated_at: String
};

/**
 * Todo priority levels
 */
@:elixirIdiomatic
enum TodoPriority {
    Low;
    Medium;
    High;
}

/**
 * Filter options for todos
 */
@:elixirIdiomatic
enum TodoFilter {
    All;
    Active;
    Completed;
}

/**
 * Sort options for todos
 */
@:elixirIdiomatic
enum TodoSort {
    Created;
    Priority;
    DueDate;
}

/**
 * LiveView socket assigns structure
 */
typedef TodoLiveAssigns = {
    todos: Array<Todo>,
    filter: TodoFilter,
    sort_by: TodoSort,
    current_user: User,
    editing_todo: Null<Todo>,
    show_form: Bool,
    search_query: String,
    selected_tags: Array<String>,
    total_todos: Int,
    completed_todos: Int,
    pending_todos: Int,
    page_title: String,
    last_updated: String
};

/**
 * Phoenix LiveView event payloads
 */
typedef TodoEvents = {
    toggle_todo: {id: Int},
    delete_todo: {id: Int},
    create_todo: {title: String, description: String, priority: String, due_date: String, tags: String},
    edit_todo: {id: Int},
    save_todo: {id: Int, title: String, description: String},
    cancel_edit: {},
    toggle_form: {},
    filter_todos: {filter: String},
    sort_todos: {sort_by: String},
    search_todos: {query: String},
    set_priority: {id: Int, priority: String},
    bulk_complete: {},
    bulk_delete_completed: {}
};

/**
 * Client-side state for JavaScript hooks
 */
typedef ClientState = {
    darkMode: Bool,
    autoSave: Bool,
    lastSync: Float
};

/**
 * Phoenix PubSub message types
 */
typedef PubSubMessages = {
    todo_added: {todo: Todo},
    todo_updated: {todo: Todo},
    todo_deleted: {id: Int},
    user_joined: {user: User},
    user_left: {user: User}
};

/**
 * Helper class to make this module findable by Haxe
 * Required because Haxe needs at least one class/enum in a file
 */
class TodoTypes {
    // Empty class just to make the module findable
}
