package server.live;

import phoenix.Phoenix.Socket;
import server.live.TodoLiveTypes.TodoLiveAssigns;
import elixir.List;

/**
 * Type-safe socket assign operations for TodoLive using socket assign helpers
 * 
 * This class demonstrates how to use Phoenix socket assign helpers.
 * The assign macros provide compile-time validation
 * of field names WITHOUT needing raw maps, casts, or string field names.
 * 
 * ## Architecture Benefits:
 * - **Compile-time field validation**: `_.fieldName` validates fields exist
 * - **No cast needed**: Socket assign helpers return properly typed sockets
 * - **No raw-map access needed**: Field access is validated at compile time
 * - **No strings for field names**: macro field selectors provide type safety
 * - **Automatic key normalization**: field names are converted to Phoenix atom keys
 * - **Completion options**: macro shorthand is minimal; typed keys are the strongest completion path
 * 
 * ## Usage Patterns:
 * ```haxe
 * // Type-safe individual assignments with _.fieldName selectors
 * socket = socket.assign(_.editing_todo, todo);
 * socket = socket.assign(_.selected_tags, tags);
 * 
 * // Type-safe bulk assignments with assign({...}) (Phoenix-style)
 * socket = socket.assign({
 *     todos: newTodos,
 *     total_todos: newTodos.length,
 *     completed_todos: completed,
 *     pending_todos: pending
 * });
 * ```
 * 
 * ## Why This Pattern Exists:
 * Phoenix LiveView uses dynamic assigns that could cause runtime errors.
 	 * Socket assign helpers provide compile-time validation that:
 * 1. Fields exist in the assigns typedef
 * 2. Field names are correctly converted to snake_case
 * 3. Typed-key calls (`assignKey` / `updateKey`) also enforce key-specific value types
 * 
 * This prevents the #1 source of LiveView bugs: typos in assign keys.
 * 
 * ## Future Improvements:
 * If you want stronger completion in Haxe 4.3.7, use the typed-key API:
 * `assignKey` / `assignNewKey` / `updateKey`.
 */
class SafeAssigns {
	/**
	 * Set the editingTodo field using socket assign helpers
	 * 
	 * The _.editingTodo syntax is validated at compile time to ensure:
	 * - The field exists in TodoLiveAssigns
	 * - The type matches (Null<Todo>)
	 * - The field name is converted to :editing_todo in Elixir
	 */
	public static function setEditingTodo(socket:Socket<TodoLiveAssigns>, todo:Null<server.schemas.Todo>):Socket<TodoLiveAssigns> {
		return socket.assign(_.editing_todo, todo);
	}

	/**
	 * Set the selectedTags field using socket assign helpers
	 */
	public static function setSelectedTags(socket:Socket<TodoLiveAssigns>, tags:Array<String>):Socket<TodoLiveAssigns> {
		return socket.assign(_.selected_tags, tags);
	}

	/**
	 * Set the filter field using socket assign helpers
	 */
	public static function setFilter(socket:Socket<TodoLiveAssigns>, filter:String):Socket<TodoLiveAssigns> {
		return socket.assign(_.filter, switch (filter) {
			case "active": shared.TodoTypes.TodoFilter.Active;
			case "completed": shared.TodoTypes.TodoFilter.Completed;
			case _: shared.TodoTypes.TodoFilter.All;
		});
	}

	/**
	 * Set the sortBy field using socket assign helpers
	 */
	public static function setSortBy(socket:Socket<TodoLiveAssigns>, sortBy:String):Socket<TodoLiveAssigns> {
		return socket.assign(_.sort_by, switch (sortBy) {
			case "priority": shared.TodoTypes.TodoSort.Priority;
			case "due_date": shared.TodoTypes.TodoSort.DueDate;
			case _: shared.TodoTypes.TodoSort.Created;
		});
	}

	/**
	 * Set sort_by only; caller should trigger recompute_visible afterwards.
	 * This keeps SafeAssigns zero-logic and typed while avoiding
	 * cross-module helper dependencies.
	 */
	public static function setSortByAndResort(socket:Socket<TodoLiveAssigns>, sortBy:String):Socket<TodoLiveAssigns> {
		return socket.assign(_.sort_by, switch (sortBy) {
			case "priority": shared.TodoTypes.TodoSort.Priority;
			case "due_date": shared.TodoTypes.TodoSort.DueDate;
			case _: shared.TodoTypes.TodoSort.Created;
		});
	}

	/**
	 * Set the searchQuery field using socket assign helpers
	 */
	public static function setSearchQuery(socket:Socket<TodoLiveAssigns>, query:String):Socket<TodoLiveAssigns> {
		return socket.assign(_.search_query, query);
	}

	/**
	 * Set the showForm field using socket assign helpers
	 */
	public static function setShowForm(socket:Socket<TodoLiveAssigns>, showForm:Bool):Socket<TodoLiveAssigns> {
		return socket.assign(_.show_form, showForm);
	}

	/**
	 * Toggle a tag in the selected_tags list (gets tag from params)
	 * If the tag is present, remove it; if absent, add it.
	 */
	public static function toggleTag(socket:Socket<TodoLiveAssigns>, tag:String):Socket<TodoLiveAssigns> {
		var currentTags = socket.assigns.selected_tags;
		var updatedTags = if (currentTags.contains(tag)) {
			currentTags.filter(function(existingTag) return existingTag != tag);
		} else {
			List.insertAt(currentTags, 0, tag);
		};
		return socket.assign(_.selected_tags, updatedTags);
	}

	/**
	 * Backward-compatible helper that accepts raw params.
	 * Prefer toggleTag/3 to avoid reflection.
	 */
	public static function toggleTagFromParams(socket:Socket<TodoLiveAssigns>, params:{tag:String}):Socket<TodoLiveAssigns> {
		return toggleTag(socket, params.tag);
	}

	/**
	 * Update todos and automatically recalculate statistics
	 * 
	 		 * Uses `assign({...})` for type-safe bulk updates.
	 * The macro validates all field names at compile time
	 * and ensures type compatibility. No casts or strings needed!
	 */
	public static function updateTodosAndStats(socket:Socket<TodoLiveAssigns>, todos:Array<server.schemas.Todo>):Socket<TodoLiveAssigns> {
		var completed = countCompleted(todos);
		var pending = countPending(todos);

		final updatedSocket = socket.assign({
			todos: todos,
			total_todos: todos.length,
			completed_todos: completed,
			pending_todos: pending
		});

		return updatedSocket;
	}

	/**
	 * Update just the todos list without stats recalculation
	 * 
	 * Uses socket assign helpers for single field updates.
	 */
	public static function setTodos(socket:Socket<TodoLiveAssigns>, todos:Array<server.schemas.Todo>):Socket<TodoLiveAssigns> {
		return socket.assign(_.todos, todos);
	}

	/**
	 * Helper function to count completed todos
	 */
	private static function countCompleted(todos:Array<server.schemas.Todo>):Int {
		var count = 0;
		for (todo in todos) {
			if (todo.completed)
				count++;
		}
		return count;
	}

	/**
	 * Helper function to count pending todos
	 */
	private static function countPending(todos:Array<server.schemas.Todo>):Int {
		var count = 0;
		for (todo in todos) {
			if (!todo.completed)
				count++;
		}
		return count;
	}
}
