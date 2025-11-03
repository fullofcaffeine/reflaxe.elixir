package server.live;

import HXX; // Import HXX for template rendering
import ecto.Changeset; // Import Ecto Changeset from the correct location
import ecto.Query; // Import Ecto Query from the correct location
import haxe.functional.Result; // Import Result type properly
import phoenix.LiveSocket; // Type-safe socket wrapper
import phoenix.types.Flash.FlashType;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.HandleInfoResult;
import phoenix.Phoenix.LiveView; // Use the comprehensive Phoenix module version
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;
import phoenix.Presence; // Import Presence module for PresenceEntry typedef
import server.infrastructure.Repo; // Import the TodoApp.Repo module
import server.live.SafeAssigns;
import server.presence.TodoPresence;
import server.pubsub.TodoPubSub.TodoPubSubMessage;
import server.pubsub.TodoPubSub.TodoPubSubTopic;
import server.pubsub.TodoPubSub;
import server.schemas.Todo;
import server.types.Types.BulkOperationType;
import server.types.Types.EventParams;
import server.types.Types.MountParams;
import server.types.Types.PubSubMessage;
import server.types.Types.Session;
import server.types.Types.User;

using StringTools;

/**
 * Type-safe event definitions for TodoLive.
 * 
 * This enum replaces string-based events with compile-time validated ADTs.
 * Each event variant carries its own strongly-typed parameters.
 * 
 * Benefits:
 * - Compile-time validation of event names
 * - Type-safe parameters for each event
 * - Exhaustiveness checking in handle_event
 * - IntelliSense/autocomplete support
 * - No Dynamic types or manual conversions
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
 * Type-safe assigns structure for TodoLive socket
 * 
 * This structure defines all the state that can be stored in the LiveView socket.
 * Using this typedef ensures compile-time type safety for all socket operations.
 */
typedef TodoLiveAssigns = {
	var todos: Array<server.schemas.Todo>;
	var filter: shared.TodoTypes.TodoFilter; // All | Active | Completed
	var sort_by: shared.TodoTypes.TodoSort;  // Created | Priority | DueDate
	var current_user: User;
	var editing_todo: Null<server.schemas.Todo>;
	var show_form: Bool;
	var search_query: String;
	var selected_tags: Array<String>;
	// Statistics
	var total_todos: Int;
	var completed_todos: Int;
	var pending_todos: Int;
	// Presence tracking (idiomatic Phoenix pattern: single flat map)
	var online_users: Map<String, phoenix.Presence.PresenceEntry<server.presence.TodoPresence.PresenceMeta>>;
}

/**
 * LiveView component for todo management with real-time updates
 */
@:native("TodoAppWeb.TodoLive")
@:liveview
class TodoLive {
	// All socket state is now defined in TodoLiveAssigns typedef for type safety
	
	/**
	 * Mount callback with type-safe assigns
	 * 
	 * The TAssigns type parameter will be inferred as TodoLiveAssigns from the socket parameter.
	 */
    public static function mount(_params: MountParams, session: Session, socket: phoenix.Phoenix.Socket<TodoLiveAssigns>): MountResult<TodoLiveAssigns> {
        // Subscription to PubSub is temporarily disabled to avoid runtime issues in handle_info while
        // compiler handle_info transforms are being finalized. UI remains fully functional locally.

        var currentUser = getUserFromSession(session);
        var todos = loadTodos(currentUser.id);

        var assigns: TodoLiveAssigns = {
            todos: todos,
            filter: shared.TodoTypes.TodoFilter.All,
            sort_by: shared.TodoTypes.TodoSort.Created,
            current_user: currentUser,
            editing_todo: null,
            show_form: false,
            search_query: "",
            selected_tags: [],
            total_todos: todos.length,
            completed_todos: countCompleted(todos),
            pending_todos: countPending(todos),
            online_users: new Map()
        };

        socket = LiveView.assignMultiple(socket, assigns);
        return Ok(socket);
    }
	
	/**
	 * Handle events with fully typed event system.
	 * 
	 * No more string matching or Dynamic params!
	 * Each event carries its own typed parameters.
	 */
    public static function handleEvent(event: TodoLiveEvent, socket: Socket<TodoLiveAssigns>): HandleEventResult<TodoLiveAssigns> {
        var resultSocket = switch (event) {
            // Todo CRUD operations - params are already typed!
            case CreateTodo(params):
                createTodo(params, socket);
			
			case ToggleTodo(id):
				toggleTodoStatus(id, socket);
			
            case DeleteTodo(id):
                trace('[TodoLive] handleEvent DeleteTodo id=' + id);
                deleteTodo(id, socket);
			
			case EditTodo(id):
				startEditing(id, socket);
			
			case SaveTodo(params):
				saveEditedTodoTyped(params, socket);
			
            case CancelEdit:
                // Clear editing state in presence (idiomatic Phoenix pattern)
                SafeAssigns.setEditingTodo(socket, null);
			
			// Filtering and sorting
			case FilterTodos(filter):
				SafeAssigns.setFilter(socket, filter);
			
            case SortTodos(sortBy):
                SafeAssigns.setSortByAndResort(socket, sortBy);
			
			case SearchTodos(query):
				SafeAssigns.setSearchQuery(socket, query);
			
			case ToggleTag(tag):
				toggleTagFilter(tag, socket);
			
			// Priority management
			case SetPriority(id, priority):
				updateTodoPriority(id, priority, socket);
			
			// UI interactions
			case ToggleForm:
                SafeAssigns.setShowForm(socket, !socket.assigns.show_form);
			
			// Bulk operations
			case BulkComplete:
				completeAllTodos(socket);
			
			case BulkDeleteCompleted:
				deleteCompletedTodos(socket);
			
			// No default case needed - compiler ensures exhaustiveness!
		};
		
		return NoReply(resultSocket);
	}
	
	/**
	 * Handle real-time updates from other users with type-safe assigns
	 * 
	 * The TAssigns type parameter will be inferred as TodoLiveAssigns from the socket parameter.
	 */
    public static function handleInfo(msg: PubSubMessage, socket: Socket<TodoLiveAssigns>): HandleInfoResult<TodoLiveAssigns> {
        // Return per-branch to avoid intermediate aliasing and ensure clean codegen
        return switch (TodoPubSub.parseMessage(msg)) {
            case Some(TodoCreated(todo)):
                // Avoid duplicating our own just-created todo (creator already prepends it)
                if (todo.userId == socket.assigns.current_user.id) {
                    NoReply(socket);
                } else {
                    NoReply(addTodoToList(todo, socket));
                }
            case Some(TodoUpdated(todo)):
                NoReply(updateTodoInList(todo, socket));
            case Some(TodoDeleted(id)):
                NoReply(removeTodoFromList(id, socket));
            case Some(BulkUpdate(action)):
                NoReply(handleBulkUpdate(action, socket));
            case Some(UserOnline(_)):
                NoReply(socket);
            case Some(UserOffline(_)):
                NoReply(socket);
            case Some(SystemAlert(_, _)):
                // Ignore system alerts for this LiveView for now
                NoReply(socket);
            case None:
                trace("Received unknown PubSub message: " + msg);
                NoReply(socket);
        };
    }

	// Legacy function for backward compatibility - will be removed
	static function createNewTodo(params: EventParams, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		// Convert EventParams (with String dates) to TodoParams (with Date type)
		var todoParams: server.schemas.Todo.TodoParams = {
			title: params.title,
			description: params.description,
			completed: false,
			priority: params.priority != null ? params.priority : "medium",
			dueDate: params.dueDate != null ? Date.fromString(params.dueDate) : null,
			tags: params.tags != null ? parseTags(params.tags) : [],
            userId: socket.assigns.current_user.id
		};
		
		// Pass the properly typed TodoParams to changeset
		var changeset = server.schemas.Todo.changeset(new server.schemas.Todo(), todoParams);
		
		// Use type-safe Repo operations
		switch (Repo.insert(changeset)) {
			case Ok(todo):
				// Best-effort broadcast; ignore result
				TodoPubSub.broadcast(TodoUpdates, TodoCreated(todo));
				
				var todos = [todo].concat(socket.assigns.todos);
				// Use LiveSocket for type-safe assigns manipulation
        var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
				var updatedSocket = liveSocket.merge({
					todos: todos,
					show_form: false
				});
                    return LiveView.putFlash(updatedSocket, FlashType.Success, "Todo created successfully!");
				
			case Error(reason):
                    return LiveView.putFlash(socket, FlashType.Error, "Failed to create todo: " + reason);
		}
	}

    /**
     * Create a new todo using typed TodoParams.
     */
    static function createTodo(params: server.schemas.Todo.TodoParams, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        // LiveView form params arrive as a map with string keys; extract safely.
        var rawTitle: Null<String> = Reflect.field(params, "title");
        var rawDesc: Null<String> = Reflect.field(params, "description");
        var rawPriority: Null<String> = Reflect.field(params, "priority");
        var rawDue: Null<String> = Reflect.field(params, "due_date");
        var rawTags: Null<String> = Reflect.field(params, "tags");

        // Normalize values and convert shapes
        var title = (rawTitle != null) ? rawTitle : "";
        var description = (rawDesc != null) ? rawDesc : "";
        var priority = (rawPriority != null && rawPriority != "") ? rawPriority : "medium";
        var tagsArr: Array<String> = (rawTags != null && rawTags != "") ? parseTags(rawTags) : [];

        // Build a params object with camelCase keys; normalize to snake_case + proper types via std helper
        var rawParams: Dynamic = {
            title: title,
            description: description,
            completed: false,
            priority: priority,
            dueDate: (rawDue != null && rawDue != "") ? rawDue : null,
            tags: tagsArr,
            userId: socket.assigns.current_user.id
        };
        var todoStruct = new server.schemas.Todo();
        var permitted = ["title","description","completed","priority","due_date","tags","user_id"];
        var castParams: Dynamic = {
            title: title,
            description: description,
            completed: false,
            priority: priority,
            due_date: (rawDue != null && rawDue != "") ? ((rawDue.indexOf(":") == -1) ? (rawDue + " 00:00:00") : rawDue) : null,
            tags: tagsArr,
            user_id: socket.assigns.current_user.id
        };
        var cs = ecto.ChangesetTools.castWithStringFields(todoStruct, castParams, permitted);
        switch (Repo.insert(cs)) {
            case Ok(ok_value):
                // Best-effort broadcast; ignore result
                TodoPubSub.broadcast(TodoUpdates, TodoCreated(ok_value));
                var todos = [ok_value].concat(socket.assigns.todos);
                var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
                var updated = liveSocket.merge({
                    todos: todos,
                    show_form: false,
                    total_todos: socket.assigns.total_todos + 1,
                    pending_todos: socket.assigns.pending_todos + (ok_value.completed ? 0 : 1),
                    completed_todos: socket.assigns.completed_todos + (ok_value.completed ? 1 : 0)
                });
                return LiveView.putFlash(updated, FlashType.Success, "Todo created successfully!");
            case Error(_reason):
                return LiveView.putFlash(socket, FlashType.Error, "Failed to create todo");
        }
    }

static function toggleTodoStatus(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
    var current = findTodo(id, socket.assigns.todos);
    if (current == null) return socket;
    // Optimistic: flip in assigns immediately
    var optimistic = new server.schemas.Todo();
    optimistic.id = current.id;
    optimistic.title = current.title;
    optimistic.description = current.description;
    optimistic.completed = !current.completed;
    optimistic.priority = current.priority;
    optimistic.dueDate = current.dueDate;
    optimistic.tags = current.tags;
    optimistic.userId = current.userId;
    var s1: LiveSocket<TodoLiveAssigns> = updateTodoInList(optimistic, (cast socket: LiveSocket<TodoLiveAssigns>));
    // Persist and reconcile
    switch (Repo.update(server.schemas.Todo.toggleCompleted(current))) {
        case Ok(updated):
            // Local reconcile; broadcast is optional and may be re-enabled once handle_info transforms are finalized
            return updateTodoInList(updated, s1);
        case Error(_reason):
            var reverted = updateTodoInList(current, s1);
            return LiveView.putFlash(reverted, FlashType.Error, "Failed to update todo");
    }
}
	
    static function deleteTodo(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        trace("[TodoLive] deleteTodo id=" + id + ", before_count=" + socket.assigns.todos.length);
        var todo = findTodo(id, socket.assigns.todos);
        if (todo == null) return socket;
        
        // Perform delete. On error, show flash and exit; otherwise proceed.
        switch (Repo.delete(todo)) {
            case Ok(_):
                // continue
            case Error(_reason):
                return LiveView.putFlash(socket, FlashType.Error, "Failed to delete todo");
        }
        // Reflect locally, then broadcast best-effort to others
        var updated = removeTodoFromList(id, socket);
        TodoPubSub.broadcast(TodoUpdates, TodoDeleted(id));
        return updated;
    }
	
static function updateTodoPriority(id: Int, priority: String, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
    var todo = findTodo(id, socket.assigns.todos);
    if (todo == null) return socket;
    switch (Repo.update(server.schemas.Todo.updatePriority(todo, priority))) {
        case Ok(_):
        case Error(_reason):
            return LiveView.putFlash(socket, FlashType.Error, "Failed to update priority");
    }
    var refreshed = Repo.get(server.schemas.Todo, id);
    if (refreshed != null) {
        TodoPubSub.broadcast(TodoUpdates, TodoUpdated(refreshed));
        return updateTodoInList(refreshed, socket);
    }
    return socket;
}
	
	// List management helpers with type-safe socket handling
	static function addTodoToList(todo: server.schemas.Todo, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		// Don't add if it's our own todo (already added)
		if (todo.userId == socket.assigns.current_user.id) {
			return socket;
		}
		
		var todos = [todo].concat(socket.assigns.todos);
		// Use LiveSocket for type-safe assigns manipulation
		var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
		return liveSocket.merge({ todos: todos });
	}
	
	
    static function loadTodos(userId: Int): Array<server.schemas.Todo> {
        // Inline query to avoid ephemeral local renames
        return Repo.all(
            ecto.TypedQuery
                .from(server.schemas.Todo)
                .where(t -> t.userId == userId)
        );
    }
	
	static function findTodo(id: Int, todos: Array<server.schemas.Todo>): Null<server.schemas.Todo> {
		for (todo in todos) {
			if (todo.id == id) return todo;
		}
		return null;
	}
	
    static function countCompleted(todos: Array<server.schemas.Todo>): Int {
        // Prefer filter+length to enable Enum.count generation on Elixir
        return todos.filter(function(t) return t.completed).length;
    }
	
    static function countPending(todos: Array<server.schemas.Todo>): Int {
        // Prefer filter+length to enable Enum.count generation on Elixir
        return todos.filter(function(t) return !t.completed).length;
    }
	
    static function parseTags(tagsString: String): Array<String> {
		if (tagsString == null || tagsString == "") return [];
            return tagsString.split(",").map(function(t) return StringTools.trim(t));
	}
	
static function getUserFromSession(session: Dynamic): User {
    // Robust nil-safe session handling: avoid Map.get on nil
    var uid: Int = if (session == null) {
        1;
    } else {
        var idVal: Null<Int> = Reflect.field(session, "user_id");
        idVal != null ? idVal : 1;
    };
    return {
        id: uid,
        name: "Demo User",
        email: "demo@example.com", 
        passwordHash: "hashed_password",
        confirmedAt: null,
        lastLoginAt: null,
        active: true
    };
}
	
	// Missing helper functions
	static function loadAndAssignTodos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todos = loadTodos(socket.assigns.current_user.id);
		// Use LiveSocket's merge for type-safe bulk updates
		var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
		return liveSocket.merge({
			todos: todos,
			total_todos: todos.length,
			completed_todos: countCompleted(todos),
			pending_todos: countPending(todos)
		});
	}
	
    static function updateTodoInList(todo: server.schemas.Todo, socket: LiveSocket<TodoLiveAssigns>): LiveSocket<TodoLiveAssigns> {
        var newTodos = socket.assigns.todos.map(function(t) return t.id == todo.id ? todo : t);
        return socket.merge({
            todos: newTodos,
            total_todos: newTodos.length,
            completed_todos: countCompleted(newTodos),
            pending_todos: countPending(newTodos)
        });
    }
	
    static function removeTodoFromList(id: Int, socket: LiveSocket<TodoLiveAssigns>): LiveSocket<TodoLiveAssigns> {
        // Merge filtered list directly without intermediate locals
        return socket.merge({
            todos: socket.assigns.todos.filter(function(t) return t.id != id),
            total_todos: socket.assigns.todos.filter(function(t) return t.id != id).length,
            completed_todos: countCompleted(socket.assigns.todos.filter(function(t) return t.id != id)),
            pending_todos: countPending(socket.assigns.todos.filter(function(t) return t.id != id))
        });
    }
	
    static function startEditing(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        // Update presence to show user is editing (idiomatic Phoenix pattern)
        return SafeAssigns.setEditingTodo(socket, findTodo(id, socket.assigns.todos));
    }
	
	// Bulk operations with type-safe socket handling
    static function completeAllTodos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        // Toggle completion using index loop to avoid enumerator rewrite edge cases
        var list = socket.assigns.todos;
        for (item in list) {
            if (!item.completed) {
                var cs = server.schemas.Todo.toggleCompleted(item);
                switch (Repo.update(cs)) { case Ok(_): case Error(_): }
            }
        }
        // Broadcast (best-effort)
        TodoPubSub.broadcast(TodoUpdates, BulkUpdate(CompleteAll));
        // Merge refreshed assigns inline
        var ls: LiveSocket<TodoLiveAssigns> = (cast socket: LiveSocket<TodoLiveAssigns>).merge({
                todos: loadTodos(socket.assigns.current_user.id),
                filter: socket.assigns.filter,
                sort_by: socket.assigns.sort_by,
                current_user: socket.assigns.current_user,
                editing_todo: socket.assigns.editing_todo,
                show_form: socket.assigns.show_form,
                search_query: socket.assigns.search_query,
                selected_tags: socket.assigns.selected_tags,
                total_todos: loadTodos(socket.assigns.current_user.id).length,
                completed_todos: loadTodos(socket.assigns.current_user.id).length,
                pending_todos: 0,
                online_users: socket.assigns.online_users
            });
        return LiveView.putFlash(ls, FlashType.Info, "All todos marked as completed!");
    }
	
    static function deleteCompletedTodos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        // Delete completed todos using index loop to avoid enumerator rewrite edge cases
        var list = socket.assigns.todos;
        for (item in list) {
            if (item.completed) Repo.delete(item);
        }
        // Notify others (best-effort)
        TodoPubSub.broadcast(TodoUpdates, BulkUpdate(DeleteCompleted));
        // Merge recomputed assigns inline
        var ls2: LiveSocket<TodoLiveAssigns> = (cast socket: LiveSocket<TodoLiveAssigns>).merge({
                todos: socket.assigns.todos.filter(function(t) return !t.completed),
                filter: socket.assigns.filter,
                sort_by: socket.assigns.sort_by,
                current_user: socket.assigns.current_user,
                editing_todo: socket.assigns.editing_todo,
                show_form: socket.assigns.show_form,
                search_query: socket.assigns.search_query,
                selected_tags: socket.assigns.selected_tags,
                total_todos: socket.assigns.todos.filter(function(t) return !t.completed).length,
                completed_todos: 0,
                pending_todos: socket.assigns.todos.filter(function(t) return !t.completed).length,
                online_users: socket.assigns.online_users
            });
        return LiveView.putFlash(ls2, FlashType.Info, "Completed todos deleted!");
    }
	
	// Additional helper functions with type-safe socket handling
	static function startEditingOld(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = findTodo(id, socket.assigns.todos);
		return SafeAssigns.setEditingTodo(socket, todo);
	}
	
	/**
	 * Save edited todo with typed parameters.
	 */
    static function saveEditedTodoTyped(params: server.schemas.Todo.TodoParams, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        if (socket.assigns.editing_todo == null) return socket;
        var todo = socket.assigns.editing_todo;
        // Inline computed title into changeset map to avoid local-binder rename mismatches
        switch (Repo.update(server.schemas.Todo.changeset(todo, {
            title: (Reflect.field(params, "title") != null)
                ? (cast Reflect.field(params, "title") : String)
                : todo.title
        }))) {
            case Ok(ok_value):
                // Best-effort broadcast
                TodoPubSub.broadcast(TodoUpdates, TodoUpdated(ok_value));
                var ls: LiveSocket<TodoLiveAssigns> = updateTodoInList(ok_value, (cast socket: LiveSocket<TodoLiveAssigns>));
                return ls.assign(_.editing_todo, null);
            case Error(_):
                return LiveView.putFlash(socket, FlashType.Error, "Failed to update todo");
        }
    }

    // Local helpers to bridge typed enums ↔ UI strings
    static inline function card_class_for2(todo: server.schemas.Todo): String {
        var border = switch (todo.priority) {
            case "high": "border-red-500";
            case "low": "border-green-500";
            case "medium": "border-yellow-500";
            case _: "border-gray-300";
        };
        var base = "bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 "+ border;
        if (todo.completed) base += " opacity-60";
        return base + " transition-all hover:shadow-xl";
    }

    // Compatibility shim: legacy event handler expects create_todo_typed/2
    // Bridge dynamic params to strongly-typed TodoParams and delegate to createTodoTyped/2
    static function create_todo_typed(params: Dynamic, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        var rawTitle: Null<String> = Reflect.field(params, "title");
        var rawDesc: Null<String> = Reflect.field(params, "description");
        var rawPriority: Null<String> = Reflect.field(params, "priority");
        var rawDue: Null<String> = Reflect.field(params, "due_date");
        var rawTags: Null<String> = Reflect.field(params, "tags");

        var todoParams: server.schemas.Todo.TodoParams = {
            title: rawTitle != null ? rawTitle : "",
            description: rawDesc != null ? rawDesc : "",
            completed: false,
            priority: (rawPriority != null && rawPriority != "") ? rawPriority : "medium",
            dueDate: (rawDue != null && rawDue != "") ? Date.fromString(rawDue) : null,
            tags: (rawTags != null && rawTags != "") ? parseTags(rawTags) : [],
            userId: socket.assigns.current_user.id
        };
        return createTodo(todoParams, socket);
    }
    static inline function format_due_date(d: Dynamic): String {
        return d == null ? "" : Std.string(d);
    }
    static inline function encodeSort(s: shared.TodoTypes.TodoSort): String {
        return switch (s) { case Created: "created"; case Priority: "priority"; case DueDate: "due_date"; };
    }
    static inline function encodeFilter(f: shared.TodoTypes.TodoFilter): String {
        return switch (f) { case All: "all"; case Active: "active"; case Completed: "completed"; };
    }

    // Typed UI helpers (no inline HEEx ops in HXX)
    static inline function filterBtnClass(current: shared.TodoTypes.TodoFilter, expect: shared.TodoTypes.TodoFilter): String {
        // Build final class without intermediate locals to avoid underscore/rename hygiene issues
        return "px-4 py-2 rounded-lg font-medium transition-colors"
            + (current == expect
                ? " bg-blue-500 text-white"
                : " bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300");
    }
    static inline function sortSelected(current: shared.TodoTypes.TodoSort, expect: shared.TodoTypes.TodoSort): Bool {
        return current == expect;
    }
    static inline function boolToStr(b: Bool): String {
        return b ? "true" : "false";
    }
    static inline function cardId(id: Int): String {
        return "todo-" + Std.string(id);
    }
    static inline function borderForPriority(p: String): String {
        return switch (p) { case "high": "border-red-500"; case "medium": "border-yellow-500"; case "low": "border-green-500"; default: "border-gray-300"; };
    }
    static inline function cardClassFor(todo: server.schemas.Todo): String {
        return "bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 "
            + borderForPriority(todo.priority)
            + (todo.completed ? " opacity-60" : "")
            + " transition-all hover:shadow-xl";
    }
    static inline function titleClass(completed: Bool): String {
        return "text-lg font-semibold text-gray-800 dark:text-white"
            + (completed ? " line-through" : "");
    }
    static inline function descClass(completed: Bool): String {
        return "text-gray-600 dark:text-gray-400 mt-1"
            + (completed ? " line-through" : "");
    }
	
	// Legacy function for backward compatibility - will be removed
	static function saveEditedTodo(params: EventParams, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = socket.assigns.editing_todo;
		if (todo == null) return socket;
		
		// Convert EventParams (with String dates) to TodoParams (with Date type)
		var todoParams: server.schemas.Todo.TodoParams = {
			title: params.title,
			description: params.description,
			priority: params.priority,
			dueDate: params.dueDate != null ? Date.fromString(params.dueDate) : null,
			tags: params.tags != null ? parseTags(params.tags) : null,
			completed: params.completed
		};
		var changeset = server.schemas.Todo.changeset(todo, todoParams);
		
		// Use type-safe Repo operations
		switch (Repo.update(changeset)) {
			case Ok(updatedTodo):
				// Best-effort broadcast
				TodoPubSub.broadcast(TodoUpdates, TodoUpdated(updatedTodo));
				
				var updatedSocket = updateTodoInList(updatedTodo, socket);
				// Convert to LiveSocket to use assign for single field
				var liveSocket: LiveSocket<TodoLiveAssigns> = updatedSocket;
				return liveSocket.assign(_.editing_todo, null);
				
			case Error(reason):
				return LiveView.putFlash(socket, FlashType.Error, "Failed to save todo");
		}
	}
	
	// Handle bulk update messages from PubSub with type-safe socket handling
	static function handleBulkUpdate(action: BulkOperationType, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        return switch (action) {
            case CompleteAll:
                // Reload todos and apply in a single merge without temporaries
                (cast socket: LiveSocket<TodoLiveAssigns>).merge({
                    todos: loadTodos(socket.assigns.current_user.id),
                    total_todos: loadTodos(socket.assigns.current_user.id).length,
                    completed_todos: countCompleted(loadTodos(socket.assigns.current_user.id)),
                    pending_todos: countPending(loadTodos(socket.assigns.current_user.id))
                });
            
            case DeleteCompleted:
                (cast socket: LiveSocket<TodoLiveAssigns>).merge({
                    todos: loadTodos(socket.assigns.current_user.id),
                    total_todos: loadTodos(socket.assigns.current_user.id).length,
                    completed_todos: countCompleted(loadTodos(socket.assigns.current_user.id)),
                    pending_todos: countPending(loadTodos(socket.assigns.current_user.id))
                });
			
			case SetPriority(priority):
				// Could handle bulk priority changes in future
				socket;
			
			case AddTag(tag):
				// Could handle bulk tag addition in future
				socket;
			
			case RemoveTag(tag):
				// Could handle bulk tag removal in future
				socket;
		};
	}
	
    static function toggleTagFilter(tag: String, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        return SafeAssigns.setSelectedTags(
            socket,
            socket.assigns.selected_tags.contains(tag)
                ? socket.assigns.selected_tags.filter(function(t) return t != tag)
                : socket.assigns.selected_tags.concat([tag])
        );
    }
	
	/**
	 * Router action handlers for LiveView routes
	 * These are called when the router dispatches to specific actions
	 */
	
	/**
	 * Handle index route - main todo list view
	 */
	public static function index(): String {
		// For LiveView routes, these actions are typically handled through mount()
		// This is a placeholder implementation to satisfy the router validation
		return "index";
	}
	
	/**
	 * Handle show route - display a specific todo
	 */
	public static function show(): String {
		// Show specific todo - parameters would be passed through mount()
		return "show";
	}
	
	/**
	 * Handle edit route - edit a specific todo
	 */
	public static function edit(): String {
		// Edit specific todo - editing state would be handled in mount()
		return "edit";
	}
	
	/**
	 * Render function for the LiveView component
	 * This generates the HTML template that gets sent to the browser
	 */
    public static function render(assigns: TodoLiveAssigns): Dynamic {
        return HXX.hxx('
			<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
				<div id="root" class="container mx-auto px-4 py-8 max-w-6xl" phx-hook="Ping">
					
					<!-- Header -->
					<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 mb-8">
						<div class="flex justify-between items-center mb-6">
							<div>
								<h1 class="text-4xl font-bold text-gray-800 dark:text-white mb-2">
									📝 Todo Manager
								</h1>
								<p class="text-gray-600 dark:text-gray-400">
									Welcome, ${assigns.current_user.name}!
								</p>
							</div>
							
							<!-- Statistics -->
							<div class="flex space-x-6">
								<div class="text-center">
									<div class="text-3xl font-bold text-blue-600 dark:text-blue-400">
										${assigns.total_todos}
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Total</div>
								</div>
								<div class="text-center">
									<div class="text-3xl font-bold text-green-600 dark:text-green-400">
										${assigns.completed_todos}
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Completed</div>
								</div>
								<div class="text-center">
									<div class="text-3xl font-bold text-amber-600 dark:text-amber-400">
										${assigns.pending_todos}
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Pending</div>
								</div>
							</div>
						</div>
						
						<!-- Add Todo Button -->
						<button phx-click="toggle_form" data-testid="btn-new-todo" class="w-full py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-medium rounded-lg hover:from-blue-600 hover:to-indigo-700 transition-all duration-200 shadow-md">
							${assigns.show_form ? "✖ Cancel" : "➕ Add New Todo"}
						</button>
					</div>
					
					<!-- New Todo Form -->
					<if {assigns.show_form}>
						<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8 border-l-4 border-blue-500">
							<form phx-submit="create_todo" class="space-y-4">
								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Title *
									</label>
									<input type="text" name="title" required data-testid="input-title"
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="What needs to be done?" />
								</div>

								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Description
									</label>
									<textarea name="description" rows="3"
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="Add more details..."></textarea>
								</div>

								<div class="grid grid-cols-2 gap-4">
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Priority
										</label>
										<select name="priority"
											class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
											<option value="low">Low</option>
											<option value="medium" selected>Medium</option>
											<option value="high">High</option>
										</select>
									</div>

									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Due Date
										</label>
                            <input type="date" name="due_date"
                                placeholder="YYYY-MM-DD"
                                class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
									</div>
								</div>

								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Tags (comma-separated)
									</label>
									<input type="text" name="tags"
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="work, personal, urgent" />
								</div>

									<button type="submit" data-testid="btn-create-todo"
									class="w-full py-3 bg-green-500 text-white font-medium rounded-lg hover:bg-green-600 transition-colors shadow-md">
									✅ Create Todo
								</button>
							</form>
						</div>
					</if>
					
					<!-- Filters and Search -->
					<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8">
						<div class="flex flex-wrap gap-4">
							<!-- Search -->
							<div class="flex-1 min-w-[300px]">
                            <form phx-change="search_todos" class="relative">
									<input type="search" name="query" value={@search_query}
										class="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="Search todos..." />
									<span class="absolute left-3 top-2.5 text-gray-400">🔍</span>
								</form>
							</div>
							
                        <!-- Filter Buttons -->
                        <div class="flex space-x-2">
                            <button phx-click="filter_todos" phx-value-filter="all" data-testid="btn-filter-all"
                                class={filter_btn_class(@filter, :all)}>All</button>
                            <button phx-click="filter_todos" phx-value-filter="active" data-testid="btn-filter-active"
                                class={filter_btn_class(@filter, :active)}>Active</button>
                            <button phx-click="filter_todos" phx-value-filter="completed" data-testid="btn-filter-completed"
                                class={filter_btn_class(@filter, :completed)}>Completed</button>
                        </div>
							
							<!-- Sort Dropdown -->
							<div>
                            <select phx-change="sort_todos" name="sort_by"
                                class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
                                <option value="created" selected={sort_selected(@sort_by, :created)}>Sort by Date</option>
                                <option value="priority" selected={sort_selected(@sort_by, :priority)}>Sort by Priority</option>
                                <option value="due_date" selected={sort_selected(@sort_by, :due_date)}>Sort by Due Date</option>
                            </select>
							</div>
						</div>
					</div>
					
					<!-- Online Users Panel -->
                    <!-- Presence panel (optional) -->
					
					<!-- Bulk Actions -->
                    <!-- Bulk Actions (typed HXX) -->
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 mb-6 flex justify-between items-center">
                        <div class="text-sm text-gray-600 dark:text-gray-400">
                            Showing #{length(filter_and_sort_todos(assigns.todos, assigns.filter, assigns.sort_by, assigns.search_query, assigns.selected_tags))} of #{@total_todos} todos
                        </div>
                        <div class="flex space-x-2">
                            <button phx-click="bulk_complete"
                                class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors text-sm">✅ Complete All</button>
                            <button phx-click="bulk_delete_completed" data-confirm="Are you sure you want to delete all completed todos?"
                                class="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm">🗑️ Delete Completed</button>
                        </div>
                    </div>
					
					<!-- Todo List -->
                    <div id="todo-list" class="space-y-4">
                        <for {todo in filter_and_sort_todos(assigns.todos, assigns.filter, assigns.sort_by, assigns.search_query, assigns.selected_tags)}>
                            <if {not Kernel.is_nil(assigns.editing_todo) and assigns.editing_todo.id == todo.id}>
                                <div id={card_id(todo.id)} data-testid="todo-card" data-completed={bool_to_str(todo.completed)}
                                    class={card_class_for2(todo)}>
                                    <form phx-submit="save_todo" class="space-y-4">
                                        <input type="text" name="title" value={todo.title} required data-testid="input-title"
                                            class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
                                        <textarea name="description" rows="2"
                                            class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">#{todo.description}</textarea>
                                        <div class="flex space-x-2">
                                            <button type="submit" class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600">Save</button>
                                            <button type="button" phx-click="cancel_edit" class="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400">Cancel</button>
                                        </div>
                                    </form>
                                </div>
                            <else>
                                <div id={card_id(todo.id)} data-testid="todo-card" data-completed={bool_to_str(todo.completed)}
                                    class={card_class_for2(todo)}>
                                    <div class="flex items-start space-x-4">
                                        <!-- Checkbox -->
                                        <button type="button" phx-click="toggle_todo" phx-value-id={todo.id} data-testid="btn-toggle-todo"
                                            class="mt-1 w-6 h-6 rounded border-2 border-gray-300 dark:border-gray-600 flex items-center justify-center hover:border-blue-500 transition-colors">
                                            <if {todo.completed}>
                                                <span class="text-green-500">✓</span>
                                            </if>
                                        </button>

                                        <!-- Content -->
                                        <div class="flex-1">
                                            <h3 class={title_class(todo.completed)}>
                                                #{todo.title}
                                            </h3>
                                            <if {not Kernel.is_nil(todo.description) and todo.description != ""}>
                                                <p class={desc_class(todo.completed)}>
                                                    #{todo.description}
                                                </p>
                                            </if>

                                            <!-- Meta info -->
                                            <div class="flex flex-wrap gap-2 mt-3">
                                                <span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">
                                                    Priority: #{todo.priority}
                                                </span>
                                                <if {not Kernel.is_nil(todo.due_date)}>
                                                    <span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">
                                                        Due: #{format_due_date(todo.due_date)}
                                                    </span>
                                                </if>
                                                <if {not Kernel.is_nil(todo.tags) and length(todo.tags) > 0}>
                                                    <for {tag in todo.tags}>
                                                        <button phx-click="search_todos" phx-value-query={tag}
                                                            class="px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400 rounded text-xs hover:bg-blue-200">#{tag}</button>
                                                    </for>
                                                </if>
                                            </div>
                                        </div>

                                        <!-- Actions -->
                                        <div class="flex space-x-2">
                                            <button type="button" phx-click="edit_todo" phx-value-id={todo.id} data-testid="btn-edit-todo"
                                                class="p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition-colors">✏️</button>
                                            <button type="button" phx-click="delete_todo" phx-value-id={todo.id} data-testid="btn-delete-todo"
                                                class="p-2 text-red-600 hover:bg-red-100 rounded-lg transition-colors">🗑️</button>
                                        </div>
                                    </div>
                                </div>
                            </if>
                        </for>
                    </div>
                </div>
            </div>
        ');
    }
	
	/**
	 * Render presence panel showing online users and editing status
	 * 
	 * Uses idiomatic Phoenix pattern: single presence map with all user state
	 */
    @:keep public static function renderPresencePanel(onlineUsers: Map<String, phoenix.Presence.PresenceEntry<server.presence.TodoPresence.PresenceMeta>>): String {
        // TEMP: Presence panel disabled pending compiler Map iteration fix.
        // Keeps runtime clean while we finalize Presence iteration transform in AST pipeline.
        return "";
    }
	
	/**
	 * Render bulk actions section
	 */
    @:keep public static function renderBulkActions(assigns: TodoLiveAssigns): String {
		if (assigns.todos.length == 0) {
			return "";
		}
		
		var filteredCount = filterTodos(assigns.todos, assigns.filter, assigns.search_query).length;
		
		return '<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 mb-6 flex justify-between items-center">
				<div class="text-sm text-gray-600 dark:text-gray-400">
					Showing ${filteredCount} of ${assigns.total_todos} todos
				</div>
				<div class="flex space-x-2">
					<button phx-click="bulk_complete"
						class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors text-sm">
						✅ Complete All
					</button>
					<button phx-click="bulk_delete_completed" 
						data-confirm="Are you sure you want to delete all completed todos?"
						class="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm">
						🗑️ Delete Completed
					</button>
				</div>
			</div>';
	}
	
	/**
	 * Render the todo list section
	 */
    @:keep public static function renderTodoList(assigns: TodoLiveAssigns): String {
		if (assigns.todos.length == 0) {
			return HXX.hxx('
				<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-16 text-center">
					<div class="text-6xl mb-4">📋</div>
					<h3 class="text-xl font-semibold text-gray-800 dark:text-white mb-2">
						No todos yet!
					</h3>
					<p class="text-gray-600 dark:text-gray-400">
						Click "Add New Todo" to get started.
					</p>
				</div>
			');
		}
		
		var filteredTodos:Array<server.schemas.Todo> = filterAndSortTodos(
			assigns.todos,
			assigns.filter,
			assigns.sort_by,
			assigns.search_query,
			assigns.selected_tags
		);
		var todoItems = [];
		for (todo in filteredTodos) {
			todoItems.push(renderTodoItem(todo, assigns.editing_todo));
		}
		return todoItems.join("\n");
	}
	
	/**
	 * Render individual todo item
	 */
	static function renderTodoItem(todo: server.schemas.Todo, editingTodo: Null<server.schemas.Todo>): String {
		var isEditing = editingTodo != null && editingTodo.id == todo.id;
		var priorityColor = switch(todo.priority) {
			case "high": "border-red-500";
			case "medium": "border-yellow-500";
			case "low": "border-green-500";
			case _: "border-gray-300";
		};
		
		if (isEditing) {
			return '<div id="todo-${todo.id}" data-testid="todo-card" data-completed="${Std.string(todo.completed)}" class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 ${priorityColor}">
					<form phx-submit="save_todo" class="space-y-4">
						<input type="text" name="title" value="${todo.title}" required data-testid="input-title"
							class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
						<textarea name="description" rows="2"
							class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">${todo.description}</textarea>
						<div class="flex space-x-2">
							<button type="submit" class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600">
								Save
							</button>
							<button type="button" phx-click="cancel_edit" class="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400">
								Cancel
							</button>
						</div>
					</form>
				</div>';
		} else {
			var completedClass = todo.completed ? "opacity-60" : "";
			var textDecoration = todo.completed ? "line-through" : "";
			var checkmark = todo.completed ? '<span class="text-green-500">✓</span>' : '';
			
			return '<div id="todo-${todo.id}" data-testid="todo-card" data-completed="${Std.string(todo.completed)}" class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 ${priorityColor} ${completedClass} transition-all hover:shadow-xl">
					<div class="flex items-start space-x-4">
                        <!-- Checkbox -->
                            <button type="button" phx-click="toggle_todo" phx-value-id="${todo.id}" data-testid="btn-toggle-todo"
                                class="mt-1 w-6 h-6 rounded border-2 border-gray-300 dark:border-gray-600 flex items-center justify-center hover:border-blue-500 transition-colors">
                                ${checkmark}
                            </button>
						
						<!-- Content -->
						<div class="flex-1">
							<h3 class="text-lg font-semibold text-gray-800 dark:text-white ${textDecoration}">
								${todo.title}
							</h3>
							${todo.description != null && todo.description != "" ? 
								'<p class="text-gray-600 dark:text-gray-400 mt-1 ${textDecoration}">${todo.description}</p>' : 
								''}
							
							<!-- Meta info -->
							<div class="flex flex-wrap gap-2 mt-3">
								<span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">
									Priority: ${todo.priority}
								</span>
                                ${todo.dueDate != null ? 
                                    '<span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">Due: ${format_due_date(todo.dueDate)}</span>' : 
                                    ''}
								${renderTags(todo.tags)}
							</div>
						</div>
						
						<!-- Actions -->
						<div class="flex space-x-2">
                                <button type="button" phx-click="edit_todo" phx-value-id="${todo.id}" data-testid="btn-edit-todo"
                                    class="p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition-colors">
                                    ✏️
                                </button>
                                <button type="button" phx-click="delete_todo" phx-value-id="${todo.id}" data-testid="btn-delete-todo"
                                    class="p-2 text-red-600 hover:bg-red-100 rounded-lg transition-colors">
                                    🗑️
                                </button>
						</div>
					</div>
				</div>';
		}
	}
	
	/**
	 * Render tags for a todo item
	 */
	static function renderTags(tags: Array<String>): String {
		if (tags == null || tags.length == 0) {
			return "";
		}
		
		var tagElements = [];
			for (tag in tags) {
				tagElements.push('<button phx-click="search_todos" phx-value-query="${tag}" class="px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400 rounded text-xs hover:bg-blue-200">#${tag}</button>');
			}
		return tagElements.join("");
	}
	
	/**
	 * Helper to filter todos based on filter and search query
	 */
    static function filterTodos(todos: Array<server.schemas.Todo>, filter: shared.TodoTypes.TodoFilter, searchQuery: String): Array<server.schemas.Todo> {
        var base = switch (filter) {
            case Active: todos.filter(function(t) return !t.completed);
            case Completed: todos.filter(function(t) return t.completed);
            case All: todos;
        };
        var qlOpt: Null<String> = (searchQuery != null && searchQuery != "") ? searchQuery.toLowerCase() : null;
        return (qlOpt == null)
            ? base
            : base.filter(function(t) {
                var title = t.title != null ? t.title.toLowerCase() : "";
                var desc = t.description != null ? t.description.toLowerCase() : "";
                return title.indexOf(qlOpt) >= 0 || desc.indexOf(qlOpt) >= 0;
            });
    }
	
	/**
	 * Helper to filter and sort todos
	 */
    public static function filterAndSortTodos(todos: Array<server.schemas.Todo>, filter: shared.TodoTypes.TodoFilter, sortBy: shared.TodoTypes.TodoSort, searchQuery: String, selectedTags: Array<String>): Array<server.schemas.Todo> {
        var filtered = filterTodos(todos, filter, searchQuery);
        if (selectedTags != null && selectedTags.length > 0) {
            filtered = filtered.filter(function(t) {
                var tags = (t.tags != null) ? t.tags : [];
                // include if any selected tag is present on the todo
                return Lambda.exists(selectedTags, function(tag) return Lambda.has(tags, tag));
            });
        }
        // Delegate sorting to std helper (emitted under app namespace), avoid app __elixir__
        return phoenix.Sorting.by(encodeSort(sortBy), filtered);
    }
}
