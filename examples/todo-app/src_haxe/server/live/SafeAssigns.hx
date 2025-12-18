package server.live;

import phoenix.Phoenix.Socket;
import phoenix.LiveSocket;
import server.live.TodoLiveTypes.TodoLiveAssigns;
import elixir.List;

// Bridge to the generated LiveView module for reuse of server-side helpers
@:native("TodoAppWeb.TodoLive")
extern class TodoLiveNative {
    public static function filter_and_sort_todos(
        todos: Array<server.schemas.Todo>,
        filter: shared.TodoTypes.TodoFilter,
        sortBy: shared.TodoTypes.TodoSort,
        searchQuery: String
    ): Array<server.schemas.Todo>;
}

/**
 * Type-safe socket assign operations for TodoLive using LiveSocket patterns
 * 
 * This class demonstrates how to use the Phoenix framework's LiveSocket
 * type-safe assign patterns. The LiveSocket provides compile-time validation
 * of field names WITHOUT needing raw maps, casts, or string field names.
 * 
 * ## Architecture Benefits:
 * - **Compile-time field validation**: The `_.fieldName` pattern validates fields exist
 * - **No cast needed**: LiveSocket methods return properly typed sockets
 * - **No raw-map access needed**: Field access is validated at compile time
 * - **No strings for field names**: The underscore pattern provides type safety
 * - **Automatic camelCase conversion**: Field names are converted to snake_case for Phoenix
 * - **IntelliSense support**: Full IDE autocomplete for all operations
 * 
 * ## Usage Patterns:
 * ```haxe
 * // Type-safe individual assignments with _.fieldName pattern
 * var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
 * socket = liveSocket.assign(_.editingTodo, todo);
 * socket = liveSocket.assign(_.selectedTags, tags);
 * 
 * // Type-safe bulk assignments with merge
 * socket = liveSocket.merge({
 *     todos: newTodos,
 *     totalTodos: newTodos.length,
 *     completedTodos: completed,
 *     pendingTodos: pending
 * });
 * ```
 * 
 * ## Why This Pattern Exists:
 * Phoenix LiveView uses dynamic assigns that could cause runtime errors.
 * The LiveSocket wrapper provides compile-time validation that:
 * 1. Fields exist in the assigns typedef
 * 2. Values match the expected types
 * 3. Field names are correctly converted to snake_case
 * 
 * This prevents the #1 source of LiveView bugs: typos in assign keys.
 * 
 * ## Future Improvements:
 * While the `_.fieldName` syntax works well, we're exploring more intuitive alternatives.
 * See [Future Assign Syntax Ideas](../../../docs/07-patterns/future-assign-syntax-ideas.md)
 * for proposals like typed field descriptors and fluent builders that might feel more natural.
 */
@:native("TodoApp.SafeAssigns")
class SafeAssigns {
    
    /**
     * Set the editingTodo field using LiveSocket's type-safe assign pattern
     * 
     * The _.editingTodo syntax is validated at compile time to ensure:
     * - The field exists in TodoLiveAssigns
     * - The type matches (Null<Todo>)
     * - The field name is converted to :editing_todo in Elixir
     */
    public static function setEditingTodo(socket: Socket<TodoLiveAssigns>, todo: Null<server.schemas.Todo>): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(_.editing_todo, todo);
    }
    
    /**
     * Set the selectedTags field using LiveSocket's type-safe assign pattern
     */
    public static function setSelectedTags(socket: Socket<TodoLiveAssigns>, tags: Array<String>): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(_.selected_tags, tags);
    }
    
    /**
     * Set the filter field using LiveSocket's type-safe assign pattern
     */
    public static function setFilter(socket: Socket<TodoLiveAssigns>, filter: String): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(
            _.filter,
            switch (filter) {
                case "active": shared.TodoTypes.TodoFilter.Active;
                case "completed": shared.TodoTypes.TodoFilter.Completed;
                case _: shared.TodoTypes.TodoFilter.All;
            }
        );
    }
    
    /**
     * Set the sortBy field using LiveSocket's type-safe assign pattern
     */
    public static function setSortBy(socket: Socket<TodoLiveAssigns>, sortBy: String): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(
            _.sort_by,
            switch (sortBy) {
                case "priority": shared.TodoTypes.TodoSort.Priority;
                case "due_date": shared.TodoTypes.TodoSort.DueDate;
                case _: shared.TodoTypes.TodoSort.Created;
            }
        );
    }

    /**
     * Set sort_by only; caller should trigger recompute_visible afterwards.
     * This keeps SafeAssigns zero-logic and typed while avoiding
     * cross-module helper dependencies.
     */
    public static function setSortByAndResort(socket: Socket<TodoLiveAssigns>, sortBy: String): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(
            _.sort_by,
            switch (sortBy) {
                case "priority": shared.TodoTypes.TodoSort.Priority;
                case "due_date": shared.TodoTypes.TodoSort.DueDate;
                case _: shared.TodoTypes.TodoSort.Created;
            }
        );
    }
    
    /**
     * Set the searchQuery field using LiveSocket's type-safe assign pattern
     */
    public static function setSearchQuery(socket: Socket<TodoLiveAssigns>, query: String): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(_.search_query, query);
    }
    
    /**
     * Set the showForm field using LiveSocket's type-safe assign pattern
     */
    public static function setShowForm(socket: Socket<TodoLiveAssigns>, showForm: Bool): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(_.show_form, showForm);
    }

    /**
     * Toggle a tag in the selected_tags list (gets tag from params)
     * If the tag is present, remove it; if absent, add it.
     */
    public static function toggleTag(socket: Socket<TodoLiveAssigns>, tag: String): Socket<TodoLiveAssigns> {
        var currentTags = socket.assigns.selected_tags;
        var updatedTags = if (currentTags.contains(tag)) {
            currentTags.filter(function(existingTag) return existingTag != tag);
        } else {
            List.insertAt(currentTags, 0, tag);
        };
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(_.selected_tags, updatedTags);
    }

    /**
     * Backward-compatible helper that accepts raw params.
     * Prefer toggleTag/3 to avoid reflection.
     */
    public static function toggleTagFromParams(socket: Socket<TodoLiveAssigns>, params: { tag:String }): Socket<TodoLiveAssigns> {
        return toggleTag(socket, params.tag);
    }
    
    /**
     * Update todos and automatically recalculate statistics
     * 
     * Uses LiveSocket's merge pattern for type-safe bulk updates.
     * The merge method validates all field names at compile time
     * and ensures type compatibility. No casts or strings needed!
     */
    public static function updateTodosAndStats(socket: Socket<TodoLiveAssigns>, todos: Array<server.schemas.Todo>): Socket<TodoLiveAssigns> {
        var completed = countCompleted(todos);
        var pending = countPending(todos);

        // Use LiveSocket's type-safe merge for bulk updates
        final updatedSocket = (cast socket: LiveSocket<TodoLiveAssigns>).merge({
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
     * Uses LiveSocket's assign pattern for single field update.
     */
    public static function setTodos(socket: Socket<TodoLiveAssigns>, todos: Array<server.schemas.Todo>): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(_.todos, todos);
    }
    
    /**
     * Helper function to count completed todos
     */
    private static function countCompleted(todos: Array<server.schemas.Todo>): Int {
        var count = 0;
        for (todo in todos) {
            if (todo.completed) count++;
        }
        return count;
    }
    
    /**
     * Helper function to count pending todos
     */
    private static function countPending(todos: Array<server.schemas.Todo>): Int {
        var count = 0;
        for (todo in todos) {
            if (!todo.completed) count++;
        }
        return count;
    }
}
