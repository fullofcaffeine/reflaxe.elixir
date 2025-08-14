package types;

/**
 * Shared types for the todo-app
 */

// User type
typedef User = {
    var id: Int;
    var name: String;
    var email: String;
}

// Socket type for LiveView
typedef Socket = {
    var assigns: SocketAssigns;
    function assign(args: Dynamic): Socket;
    function put_flash(type: String, message: String): Socket;
}

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

// Params for LiveView events
typedef EventParams = {
    var ?id: Int;
    var ?title: String;
    var ?description: String;
    var ?priority: String;
    var ?due_date: String;
    var ?tags: String;
    var ?filter: String;
    var ?sort_by: String;
    var ?query: String;
    var ?tag: String;
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