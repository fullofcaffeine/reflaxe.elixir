package server.live;

import server.types.Types.User;
import shared.TodoTypes.TodoFilter;
import shared.TodoTypes.TodoSort;

/**
 * Type-safe event definitions for TodoLive.
 */
enum TodoLiveEvent {
    // Todo CRUD operations
    CreateTodo(params: server.schemas.Todo.TodoParams);
    ToggleTodo(id: Int);
    DeleteTodo(id: Int);
    EditTodo(id: Int);
    SaveTodo(params: server.schemas.Todo.TodoParams);
    CancelEdit;

    // Filtering and sorting
    FilterTodos(filter: String);
    SortTodos(sortBy: String);
    SearchTodos(query: String);
    ToggleTag(tag: String);

    // Priority management
    SetPriority(id: Int, priority: String);

    // UI interactions
    ToggleForm;

    // Bulk operations
    BulkComplete;
    BulkDeleteCompleted;
}

/**
 * Type-safe assigns structure for TodoLive socket.
 */
typedef TodoLiveAssigns = {
    var todos: Array<server.schemas.Todo>;
    var filter: TodoFilter; // All | Active | Completed
    var sort_by: TodoSort;  // Created | Priority | DueDate
    var current_user: User;
    var editing_todo: Null<server.schemas.Todo>;
    var show_form: Bool;
    var search_query: String;
    var selected_tags: Array<String>;
    // Optimistic UI state: ids currently flipped client-first, pending server reconcile
    var optimistic_toggle_ids: Array<Int>;
    // Precomputed view rows for HXX (zero-logic rendering)
    var visible_todos: Array<TodoView>;
    // Statistics
    var total_todos: Int;
    var completed_todos: Int;
    var pending_todos: Int;
    // Presence tracking (idiomatic Phoenix pattern: single flat map)
    var online_users: Map<String, phoenix.Presence.PresenceEntry<server.presence.TodoPresence.PresenceMeta>>;
    // UI convenience fields for zero-logic HXX
    var visible_count: Int;
    var filter_btn_all_class: String;
    var filter_btn_active_class: String;
    var filter_btn_completed_class: String;
    var sort_selected_created: Bool;
    var sort_selected_priority: Bool;
    var sort_selected_due_date: Bool;
}

/**
 * Row view model for HXX zero-logic rendering.
 */
typedef TodoView = {
    var id: Int;
    var title: String;
    var description: String;
    var completed_for_view: Bool;
    var completed_str: String;
    var dom_id: String;
    var container_class: String;
    var title_class: String;
    var desc_class: String;
    var priority: String;
    var has_due: Bool;
    var due_display: String;
    var has_tags: Bool;
    var has_description: Bool;
    var is_editing: Bool;
    var tags: Array<String>;
}
