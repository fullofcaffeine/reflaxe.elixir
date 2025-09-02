package server.live;

import phoenix.Phoenix.Socket;
import phoenix.LiveSocket;
import phoenix.Phoenix.LiveView;  // Use the comprehensive Phoenix module version
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
     * Set the editingTodo field
     */
    public static function setEditingTodo(socket: Socket<TodoLiveAssigns>, todo: Null<server.schemas.Todo>): Socket<TodoLiveAssigns> {
        var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
        return liveSocket.assign(_.editingTodo, todo);
    }
    
    /**
     * Set the selectedTags field
     */
    public static function setSelectedTags(socket: Socket<TodoLiveAssigns>, tags: Array<String>): Socket<TodoLiveAssigns> {
        var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
        return liveSocket.assign(_.selectedTags, tags);
    }
    
    /**
     * Set the filter field
     */
    public static function setFilter(socket: Socket<TodoLiveAssigns>, filter: String): Socket<TodoLiveAssigns> {
        var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
        return liveSocket.assign(_.filter, filter);
    }
    
    /**
     * Set the sortBy field
     */
    public static function setSortBy(socket: Socket<TodoLiveAssigns>, sortBy: String): Socket<TodoLiveAssigns> {
        var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
        return liveSocket.assign(_.sortBy, sortBy);
    }
    
    /**
     * Set the searchQuery field
     */
    public static function setSearchQuery(socket: Socket<TodoLiveAssigns>, query: String): Socket<TodoLiveAssigns> {
        var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
        return liveSocket.assign(_.searchQuery, query);
    }
    
    /**
     * Set the showForm field
     */
    public static function setShowForm(socket: Socket<TodoLiveAssigns>, showForm: Bool): Socket<TodoLiveAssigns> {
        var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
        return liveSocket.assign(_.showForm, showForm);
    }
    
    /**
     * Update todos and automatically recalculate statistics
     */
    public static function updateTodosAndStats(socket: Socket<TodoLiveAssigns>, todos: Array<server.schemas.Todo>): Socket<TodoLiveAssigns> {
        var completed = countCompleted(todos);
        var pending = countPending(todos);
        
        var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
        return liveSocket.merge({
            todos: todos,
            totalTodos: todos.length,
            completedTodos: completed,
            pendingTodos: pending
        });
    }
    
    /**
     * Update just the todos list without stats recalculation
     */
    public static function setTodos(socket: Socket<TodoLiveAssigns>, todos: Array<server.schemas.Todo>): Socket<TodoLiveAssigns> {
        var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
        return liveSocket.assign(_.todos, todos);
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