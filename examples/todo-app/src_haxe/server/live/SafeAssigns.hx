package server.live;

import phoenix.Phoenix.Socket;
import phoenix.Phoenix.LiveView;
import server.live.TodoLive.TodoLiveAssigns;

/**
 * Type-safe socket assign operations for TodoLive
 * 
 * This approach eliminates string-based keys and provides compile-time 
 * validation for socket assign operations, similar to our SafePubSub pattern.
 * 
 * ## Benefits:
 * - **Compile-time validation**: No more typos in assign keys
 * - **Type safety**: Each assignment is validated for correct value type
 * - **IntelliSense support**: IDE can auto-complete available assignments
 * - **Refactor friendly**: Renaming fields updates all references automatically
 * 
 * ## Usage:
 * ```haxe
 * // Type-safe individual assignments
 * socket = SafeAssigns.setEditingTodo(socket, todo);
 * socket = SafeAssigns.setSelectedTags(socket, tags);
 * 
 * // Type-safe bulk assignments  
 * socket = SafeAssigns.updateStats(socket, newTodos);
 * ```
 */
class SafeAssigns {
    
    /**
     * Set the editing_todo field
     */
    public static function setEditingTodo(socket: Socket<TodoLiveAssigns>, todo: Null<server.schemas.Todo>): Socket<TodoLiveAssigns> {
        return LiveView.assign_multiple(socket, cast {editing_todo: todo});
    }
    
    /**
     * Set the selected_tags field
     */
    public static function setSelectedTags(socket: Socket<TodoLiveAssigns>, tags: Array<String>): Socket<TodoLiveAssigns> {
        return LiveView.assign_multiple(socket, cast {selected_tags: tags});
    }
    
    /**
     * Set the filter field
     */
    public static function setFilter(socket: Socket<TodoLiveAssigns>, filter: String): Socket<TodoLiveAssigns> {
        return LiveView.assign_multiple(socket, cast {filter: filter});
    }
    
    /**
     * Set the sort_by field
     */
    public static function setSortBy(socket: Socket<TodoLiveAssigns>, sortBy: String): Socket<TodoLiveAssigns> {
        return LiveView.assign_multiple(socket, cast {sort_by: sortBy});
    }
    
    /**
     * Set the search_query field
     */
    public static function setSearchQuery(socket: Socket<TodoLiveAssigns>, query: String): Socket<TodoLiveAssigns> {
        return LiveView.assign_multiple(socket, cast {search_query: query});
    }
    
    /**
     * Set the show_form field
     */
    public static function setShowForm(socket: Socket<TodoLiveAssigns>, showForm: Bool): Socket<TodoLiveAssigns> {
        return LiveView.assign_multiple(socket, cast {show_form: showForm});
    }
    
    /**
     * Update todos and automatically recalculate statistics
     */
    public static function updateTodosAndStats(socket: Socket<TodoLiveAssigns>, todos: Array<server.schemas.Todo>): Socket<TodoLiveAssigns> {
        var completed = countCompleted(todos);
        var pending = countPending(todos);
        
        return LiveView.assign_multiple(socket, cast {
            todos: todos,
            total_todos: todos.length,
            completed_todos: completed,
            pending_todos: pending
        });
    }
    
    /**
     * Update just the todos list without stats recalculation
     */
    public static function setTodos(socket: Socket<TodoLiveAssigns>, todos: Array<server.schemas.Todo>): Socket<TodoLiveAssigns> {
        return LiveView.assign_multiple(socket, cast {todos: todos});
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