package shared;

/**
 * TodoTypes (todo-app)
 *
 * WHAT
 * - Shared domain types (typedefs + enums) used by both:
 *   - server build (Haxe→Elixir): LiveViews, schemas, controllers
 *   - client build (Haxe→JS via genes): hooks and any client-side state
 *
 * WHY
 * - Single source of truth across the client/server boundary:
 *   - event payload shapes don’t drift
 *   - enum/tag refactors are type-checked
 *   - tests and UI code share consistent contracts
 *
 * HOW
 * - `typedef` describes JSON-like shapes (maps/objects) used at boundaries.
 * - `@:elixirIdiomatic` enums compile to Elixir-friendly tagged tuples on the server,
 *   while remaining normal Haxe enums on the client.
 */
/**
 * Todo item shape as rendered/serialized by the todo-app.
 */
typedef Todo = {
	id:Int,
	title:String,
	description:Null<String>,
	completed:Bool,
	priority:TodoPriority,
	due_date:Null<String>,
	tags:Null<String>,
	user_id:Int,
	inserted_at:String,
	updated_at:String
};

/**
 * User shape as rendered/serialized by the todo-app.
 */
typedef User = {
	id:Int,
	name:String,
	email:String,
	inserted_at:String,
	updated_at:String
};

/**
 * Todo priority levels.
 *
 * Server: `@:elixirIdiomatic` → `{:low | :medium | :high}`
 * Client: standard Haxe enum values.
 */
// @:elixirIdiomatic: prefers idiomatic Elixir enum/result shapes over literal Haxe constructor naming.

@:elixirIdiomatic
enum TodoPriority {
	Low;
	Medium;
	High;
}

/**
 * Filter options for the UI (active/completed/all).
 */
@:elixirIdiomatic
enum TodoFilter {
	All;
	Active;
	Completed;
}

/**
 * Sort options for the UI.
 */
@:elixirIdiomatic
enum TodoSort {
	Created;
	Priority;
	DueDate;
}

/**
 * LiveView socket assigns structure (server-only concept).
 *
 * This is kept in `shared/` because the shape is referenced across multiple server modules and
 * occasionally reused by client-side helpers (e.g. for typed decoding/validation).
 */
typedef TodoLiveAssigns = {
	todos:Array<Todo>,
	filter:TodoFilter,
	sort_by:TodoSort,
	current_user:User,
	editing_todo:Null<Todo>,
	show_form:Bool,
	search_query:String,
	selected_tags:Array<String>,
	total_todos:Int,
	completed_todos:Int,
	pending_todos:Int,
	page_title:String,
	last_updated:String
};

/**
 * Phoenix LiveView event payload shapes (server receives these).
 *
 * These are intentionally JSON-ish shapes so they can be validated/decoded and evolve without
 * coupling to internal structs.
 */
typedef TodoEvents = {
	toggle_todo:{id:Int},
	delete_todo:{id:Int},
	create_todo:{title:String, description:String, priority:String, due_date:String, tags:String},
	edit_todo:{id:Int},
	save_todo:{id:Int, title:String, description:String},
	cancel_edit:{},
	toggle_form:{},
	filter_todos:{filter:String},
	sort_todos:{sort_by:String},
	search_todos:{query:String},
	set_priority:{id:Int, priority:String},
	bulk_complete:{},
	bulk_delete_completed:{}
};

/**
 * Client-side state for JavaScript hooks (genes build).
 */
typedef ClientState = {
	darkMode:Bool,
	autoSave:Bool,
	lastSync:Float
};

/**
 * Phoenix PubSub message shapes (server internal).
 */
typedef PubSubMessages = {
	todo_added:{todo:Todo},
	todo_updated:{todo:Todo},
	todo_deleted:{id:Int},
	user_joined:{user:User},
	user_left:{user:User}
};

/**
 * Helper class to make this module findable by Haxe
 * Required because Haxe needs at least one class/enum in a file
 */
class TodoTypes {
	// Empty class just to make the module findable
}
