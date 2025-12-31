package server.live;

import server.types.Types.User;
import shared.TodoTypes.TodoFilter;
import shared.TodoTypes.TodoSort;
import phoenix.types.Flash.FlashMap;

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
    var signed_in: Bool;
    var editing_todo: Null<server.schemas.Todo>;
    var show_form: Bool;
    var search_query: String;
    var selected_tags: Array<String>;
    // Derived from todos; used to render the tag chip row in the UI
    var available_tags: Array<TagView>;
    // Optimistic UI state: ids currently flipped client-first, pending server reconcile
    var optimistic_toggle_ids: Array<Int>;
    // Precomputed view rows for HXX (zero-logic rendering)
    var visible_todos: Array<TodoView>;
    // Statistics
    var total_todos: Int;
    var completed_todos: Int;
    var pending_todos: Int;
    // Presence: store the original "online at" timestamp we advertise in Presence metadata.
    // This keeps the value stable when we update editing-related metadata.
    var presence_online_at: Float;
    // Presence tracking (idiomatic Phoenix pattern: single flat map)
    var online_users: Map<String, phoenix.Presence.PresenceEntry<server.presence.TodoPresence.PresenceMeta>>;
    // Presence UI helpers (zero-logic HXX)
    var online_user_count: Int;
    var online_user_views: Array<OnlineUserView>;
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
 * Render assigns for TodoLive templates.
 *
 * NOTE: LiveView injects additional assigns (e.g. `flash`) that are not part of our
 * socket state updates. We model them separately so we can read them in `render/1`
 * without forcing mount/merge code to override framework-managed assigns.
 */
	typedef TodoLiveRenderAssigns = {> TodoLiveAssigns,
	    var flash: FlashMap;
	    // NOTE: We compute these in render/1 via Phoenix.Component.assign/3 so templates
	    // use tracked assigns (@flash_info/@flash_error) instead of local variables.
	    var flash_info: Null<String>;
	    var flash_error: Null<String>;
	    // Derived from show_form; assigned in render/1 for zero-logic HXX.
	    var toggle_form_label: String;
	    // Header avatar (zero-logic HXX)
	    var header_avatar_initials: String;
	    var header_avatar_class: String;
	    var header_avatar_style: String;
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
    // If present, indicates another user is editing this todo right now.
    var editing_badge: Null<String>;
    var tags: Array<TagView>;
}

/**
 * Tag chip view model (zero-logic HXX rendering).
 *
 * We precompute selection state and styling in Haxe so templates do not embed
 * HEEx/Elixir logic (Enum.member?, Kernel.*, etc).
 */
typedef TagView = {
    var tag: String;
    var selected: Bool;
    var chip_class: String;
}

/**
 * Presence UI chip view model (zero-logic HXX rendering).
 */
typedef OnlineUserView = {
    var key: String;
    var avatar_initials: String;
    var avatar_class: String;
    var avatar_style: String;
    var display_name: String;
    var sublabel: Null<String>;
    var chip_class: String;
}
