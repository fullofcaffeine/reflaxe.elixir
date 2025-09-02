package types;

/**
 * Type definitions for Phoenix LiveView interactions
 */

// Socket type removed - use phoenix.Phoenix.Socket<T> or phoenix.LiveSocket<T> instead
// This avoids conflicts with the proper Phoenix LiveView extern

// Socket assigns structure
typedef SocketAssigns = {
    var todos: Array<schemas.Todo>;
    var filter: String;
    var sort_by: String;
    var current_user: User;
    var editing_todo: Null<schemas.Todo>;
    var show_form: Bool;
    var search_query: String;
    var selected_tags: Array<String>;
    var total_todos: Int;
    var completed_todos: Int;
    var pending_todos: Int;
}

// User type
typedef User = {
    var id: Int;
    var name: String;
    var email: String;
}

// Use the actual Todo schema from schemas.Todo
// We don't redefine it here to avoid conflicts

// Params for LiveView events
typedef EventParams = {
    ?id: Int,
    ?title: String,
    ?description: String,
    ?priority: String,
    ?due_date: String,
    ?tags: String,
    ?filter: String,
    ?sort_by: String,
    ?query: String,
    ?tag: String
}

// Message types for PubSub
typedef PubSubMessage = {
    var type: String;
    var ?todo: schemas.Todo;
    var ?id: Int;
    var ?action: String;
}

// Session type
typedef Session = {
    var ?user_id: Int;
    var ?token: String;
}

// Mount params
typedef MountParams = {
    var ?id: String;
    var ?action: String;
}

// Changeset type for Ecto
typedef Changeset = {
    var valid: Bool;
    var changes: {};
    var errors: Array<{field: String, message: String}>;
    var data: Any;
}

// Repo result types
typedef RepoResult<T> = {
    var success: Bool;
    var data: T;
    var ?error: String;
}