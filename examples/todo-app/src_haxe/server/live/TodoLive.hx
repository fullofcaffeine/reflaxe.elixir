package server.live;

import HXX; // Import HXX for template rendering
import ecto.Changeset; // Import Ecto Changeset from the correct location
import ecto.Query; // Import Ecto Query from the correct location
import haxe.functional.Result; // Import Result type properly
import phoenix.LiveSocket; // Type-safe socket wrapper
import phoenix.Phoenix.FlashType;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.HandleInfoResult;
import phoenix.Phoenix.LiveView; // Use the comprehensive Phoenix module version
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;
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
	var filter: String; // all, active, completed
	var sortBy: String; // created, priority, dueDate - camelCase!
	var currentUser: User;
	var editingTodo: Null<server.schemas.Todo>;
	var showForm: Bool;
	var searchQuery: String;
	var selectedTags: Array<String>;
	// Statistics
	var totalTodos: Int;
	var completedTodos: Int;
	var pendingTodos: Int;
	// Presence tracking (idiomatic Phoenix pattern: single flat map)
	var onlineUsers: Map<String, phoenix.Phoenix.PresenceEntry<server.presence.TodoPresence.PresenceMeta>>;
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
		// Subscribe to todo updates for real-time sync using type-safe PubSub
		switch (TodoPubSub.subscribe(TodoUpdates)) {
			case Error(reason):
				return Error("Failed to subscribe to updates: " + reason);
			case Ok(_):
				// Subscription successful, continue
		}
		
		var currentUser = getUserFromSession(session);
		var todos = loadTodos(currentUser.id);
		
		// Track user presence for real-time collaboration
		var presenceSocket = server.presence.TodoPresence.trackUser(socket, currentUser);
		
		// Create type-safe assigns structure
		var assigns: TodoLiveAssigns = {
			todos: todos,
			filter: "all",
			sortBy: "created",  // camelCase!
			currentUser: currentUser,  // camelCase!
			editingTodo: null,  // camelCase!
			showForm: false,  // camelCase!
			searchQuery: "",  // camelCase!
			selectedTags: [],  // camelCase!
			totalTodos: todos.length,  // camelCase!
			completedTodos: countCompleted(todos),  // camelCase!
			pendingTodos: countPending(todos),  // camelCase!
			// Initialize presence tracking (single map - Phoenix pattern)
			onlineUsers: new Map()  // Will be populated by handle_info
		};
		
		// Use assign_multiple for bulk assigns (full object)
		var updatedSocket = LiveView.assignMultiple(presenceSocket, assigns);
		
		return Ok(updatedSocket);
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
				createTodoTyped(params, socket);
			
			case ToggleTodo(id):
				toggleTodoStatus(id, socket);
			
			case DeleteTodo(id):
				deleteTodo(id, socket);
			
			case EditTodo(id):
				startEditing(id, socket);
			
			case SaveTodo(params):
				saveEditedTodoTyped(params, socket);
			
			case CancelEdit:
				// Clear editing state in presence (idiomatic Phoenix pattern)
				var presenceSocket = server.presence.TodoPresence.updateUserEditing(socket, socket.assigns.currentUser, null);
				SafeAssigns.setEditingTodo(presenceSocket, null);
			
			// Filtering and sorting
			case FilterTodos(filter):
				SafeAssigns.setFilter(socket, filter);
			
			case SortTodos(sortBy):
				SafeAssigns.setSortBy(socket, sortBy);
			
			case SearchTodos(query):
				SafeAssigns.setSearchQuery(socket, query);
			
			case ToggleTag(tag):
				toggleTagFilter(tag, socket);
			
			// Priority management
			case SetPriority(id, priority):
				updateTodoPriority(id, priority, socket);
			
			// UI interactions
			case ToggleForm:
				SafeAssigns.setShowForm(socket, !socket.assigns.showForm);  // camelCase!
			
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
		// Parse incoming message to type-safe enum (will be auto-generated in Phase 2)
		var resultSocket = switch (TodoPubSub.parseMessage(msg)) {
			case Some(parsedMsg):
				switch (parsedMsg) {
					case TodoCreated(todo):
						addTodoToList(todo, socket);
					
					case TodoUpdated(todo):
						updateTodoInList(todo, socket);
					
					case TodoDeleted(id):
						removeTodoFromList(id, socket);
					
					case BulkUpdate(action):
						handleBulkUpdate(action, socket);
					
					case UserOnline(userId):
						// Could update online user list in future
						socket;
					
					case UserOffline(userId):
						// Could update online user list in future
						socket;
					
					case SystemAlert(message, level):
						// Show system alert to user
						var flashType = switch (level) {
							case Info: phoenix.Phoenix.FlashType.Info;
							case Warning: phoenix.Phoenix.FlashType.Warning;
							case Error: phoenix.Phoenix.FlashType.Error;
							case Critical: phoenix.Phoenix.FlashType.Error;
						};
						LiveView.putFlash(socket, flashType, message);
				}
			
			case None:
				// Unknown or malformed message - log and ignore
				trace("Received unknown PubSub message: " + msg);
				socket;
		};
		
		return NoReply(resultSocket);
	}
	
	// Helper functions with type-safe socket handling
	
	/**
	 * Create a new todo with typed parameters - no conversion needed!
	 */
	static function createTodoTyped(params: server.schemas.Todo.TodoParams, socket: Socket<TodoLiveAssigns>) : Socket<TodoLiveAssigns> {
		// Add userId from socket assigns
		params.userId = socket.assigns.currentUser.id;  // camelCase!
		
		// Direct use of typed params - no conversion!
		var changeset = server.schemas.Todo.changeset(new server.schemas.Todo(), params);
		
		// Use type-safe Repo operations
		switch (Repo.insert(changeset)) {
			case Ok(todo):
				// Broadcast to other users using type-safe PubSub
				switch (TodoPubSub.broadcast(TodoUpdates, TodoCreated(todo))) {
					case Ok(_):
						// Broadcast successful
					case Error(reason):
						trace("Failed to broadcast todo creation: " + reason);
				}
				
				// Refresh todos and update UI
				var updatedSocket = loadAndAssignTodos(socket);
				return SafeAssigns.setShowForm(updatedSocket, false);
				
			case Error(changeset):
				// Handle validation errors
				return LiveView.putFlash(socket, phoenix.Phoenix.FlashType.Error, "Failed to create todo");
		}
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
			userId: socket.assigns.currentUser.id
		};
		
		// Pass the properly typed TodoParams to changeset
		var changeset = server.schemas.Todo.changeset(new server.schemas.Todo(), todoParams);
		
		// Use type-safe Repo operations
		switch (Repo.insert(changeset)) {
			case Ok(todo):
				// Broadcast to other users using type-safe PubSub with compile-time validation
				switch (TodoPubSub.broadcast(TodoUpdates, TodoCreated(todo))) {
					case Ok(_):
						// Broadcast successful
					case Error(reason):
						trace("Failed to broadcast todo creation: " + reason);
				}
				
				var todos = [todo].concat(socket.assigns.todos);
				// Use LiveSocket for type-safe assigns manipulation
				var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
				var updatedSocket = liveSocket.merge({
					todos: todos,
					showForm: false
				});
				return LiveView.putFlash(updatedSocket, phoenix.Phoenix.FlashType.Success, "Todo created successfully!");
				
			case Error(reason):
				return LiveView.putFlash(socket, phoenix.Phoenix.FlashType.Error, "Failed to create todo: " + reason);
		}
	}
	
	static function toggleTodoStatus(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = findTodo(id, socket.assigns.todos);
		if (todo == null) return socket;
		
		var updatedChangeset = server.schemas.Todo.toggleCompleted(todo);
		
		// Use type-safe Repo operations
		switch (Repo.update(updatedChangeset)) {
			case Ok(updatedTodo):
				// Broadcast to other users using type-safe PubSub with compile-time validation
				switch (TodoPubSub.broadcast(TodoUpdates, TodoUpdated(updatedTodo))) {
					case Ok(_):
						// Broadcast successful
					case Error(reason):
						trace("Failed to broadcast todo update: " + reason);
				}
				
				return updateTodoInList(updatedTodo, socket);
				
			case Error(reason):
				return LiveView.putFlash(socket, phoenix.Phoenix.FlashType.Error, "Failed to update todo: " + reason);
		}
	}
	
	static function deleteTodo(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = findTodo(id, socket.assigns.todos);
		if (todo == null) return socket;
		
		// Use type-safe Repo operations
		switch (Repo.delete(todo)) {
			case Ok(deletedTodo):
				// Broadcast to other users using type-safe PubSub
				switch (TodoPubSub.broadcast(TodoUpdates, TodoDeleted(id))) {
					case Ok(_):
						// Broadcast successful
					case Error(reason):
						trace("Failed to broadcast todo deletion: " + reason);
				}
				
				return removeTodoFromList(id, socket);
				
			case Error(reason):
				return LiveView.putFlash(socket, phoenix.Phoenix.FlashType.Error, "Failed to delete todo: " + reason);
		}
	}
	
	static function updateTodoPriority(id: Int, priority: String, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = findTodo(id, socket.assigns.todos);
		if (todo == null) return socket;
		
		var updatedChangeset = server.schemas.Todo.updatePriority(todo, priority);
		
		// Use type-safe Repo operations
		switch (Repo.update(updatedChangeset)) {
			case Ok(updatedTodo):
				// Broadcast to other users using type-safe PubSub
				switch (TodoPubSub.broadcast(TodoUpdates, TodoUpdated(updatedTodo))) {
					case Ok(_):
						// Broadcast successful
					case Error(reason):
						trace("Failed to broadcast todo priority update: " + reason);
				}
				
				return updateTodoInList(updatedTodo, socket);
				
			case Error(reason):
				return LiveView.putFlash(socket, phoenix.Phoenix.FlashType.Error, "Failed to update priority: " + reason);
		}
	}
	
	// List management helpers with type-safe socket handling
	static function addTodoToList(todo: server.schemas.Todo, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		// Don't add if it's our own todo (already added)
		if (todo.userId == socket.assigns.currentUser.id) {
			return socket;
		}
		
		var todos = [todo].concat(socket.assigns.todos);
		// Use LiveSocket for type-safe assigns manipulation
		var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
		return liveSocket.merge({ todos: todos });
	}
	
	
	static function loadTodos(userId: Int): Array<server.schemas.Todo> {
		// Use type-safe Query API with proper chaining
		var query = Query.from(server.schemas.Todo)
			.where("userId", userId)
			.orderBy("inserted_at", "asc");
		return Repo.all(query);
	}
	
	static function findTodo(id: Int, todos: Array<server.schemas.Todo>): Null<server.schemas.Todo> {
		for (todo in todos) {
			if (todo.id == id) return todo;
		}
		return null;
	}
	
	static function countCompleted(todos: Array<server.schemas.Todo>): Int {
		var count = 0;
		for (todo in todos) {
			if (todo.completed) count++;
		}
		return count;
	}
	
	static function countPending(todos: Array<server.schemas.Todo>): Int {
		var count = 0;
		for (todo in todos) {
			if (!todo.completed) count++;
		}
		return count;
	}
	
	static function parseTags(tagsString: String): Array<String> {
		if (tagsString == null || tagsString == "") return [];
		return tagsString.split(",").map(function(t) return t.trim());
	}
	
	static function getUserFromSession(session: Dynamic): User {
		// In real app, would fetch from session/token and validate properly
		// For demo purposes, return a properly typed User object
		// Handle empty session case (when Phoenix passes %{})
		// Use Reflect.field for safe map access since session is Dynamic
		var userId: Null<Int> = Reflect.field(session, "user_id");  // Note: Phoenix uses snake_case keys
		
		return {
			id: userId != null ? userId : 1,  // Default to user 1 for demo
			name: "Demo User",
			email: "demo@example.com", 
			passwordHash: "hashed_password",  // camelCase!
			confirmedAt: null,  // camelCase!
			lastLoginAt: null,  // camelCase!
			active: true
		};
	}
	
	// Missing helper functions
	static function loadAndAssignTodos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todos = loadTodos(socket.assigns.currentUser.id);
		// Use LiveSocket's merge for type-safe bulk updates
		var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
		return liveSocket.merge({
			todos: todos,
			totalTodos: todos.length,
			completedTodos: countCompleted(todos),
			pendingTodos: countPending(todos)
		});
	}
	
	static function updateTodoInList(todo: server.schemas.Todo, socket: LiveSocket<TodoLiveAssigns>): LiveSocket<TodoLiveAssigns> {
		var todos = socket.assigns.todos;
		var updatedTodos = todos.map(function(t) {
			return t.id == todo.id ? todo : t;
		});
		
		// Use LiveSocket's merge for type-safe bulk updates
		return socket.merge({
			todos: updatedTodos,
			totalTodos: updatedTodos.length,
			completedTodos: countCompleted(updatedTodos),
			pendingTodos: countPending(updatedTodos)
		});
	}
	
	static function removeTodoFromList(id: Int, socket: LiveSocket<TodoLiveAssigns>): LiveSocket<TodoLiveAssigns> {
		var todos = socket.assigns.todos;
		var updatedTodos = todos.filter(function(t) return t.id != id);
		
		// Use LiveSocket's merge for batch updates
		return socket.merge({
			todos: updatedTodos,
			totalTodos: updatedTodos.length,
			completedTodos: countCompleted(updatedTodos),
			pendingTodos: countPending(updatedTodos)
		});
	}
	
	static function startEditing(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = findTodo(id, socket.assigns.todos);
		// Update presence to show user is editing (idiomatic Phoenix pattern)
		var presenceSocket = server.presence.TodoPresence.updateUserEditing(socket, socket.assigns.currentUser, id);
		return SafeAssigns.setEditingTodo(presenceSocket, todo);
	}
	
	// Bulk operations with type-safe socket handling
	static function completeAllTodos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var pending: Array<server.schemas.Todo> = socket.assigns.todos.filter(function(t) return !t.completed);
		
		// Update all pending todos
		for (todo in pending) {
			var updatedChangeset = server.schemas.Todo.toggleCompleted(todo);
			switch (Repo.update(updatedChangeset)) {
				case Ok(updatedTodo):
					// Individual update successful
				case Error(reason):
					trace("Failed to complete todo " + todo.id + ": " + reason);
			}
		}
		
		// Broadcast bulk update
		switch (TodoPubSub.broadcast(TodoUpdates, BulkUpdate(CompleteAll))) {
			case Ok(_):
				// Broadcast successful
			case Error(reason):
				trace("Failed to broadcast bulk complete: " + reason);
		}
		
		// Reload todos and update socket with complete assigns
		var updatedTodos = loadTodos(socket.assigns.currentUser.id);
		var currentAssigns = socket.assigns;
		var completeAssigns: TodoLiveAssigns = {
			todos: updatedTodos,
			filter: currentAssigns.filter,
			sortBy: currentAssigns.sortBy,
			currentUser: currentAssigns.currentUser,
			editingTodo: currentAssigns.editingTodo,
			showForm: currentAssigns.showForm,
			searchQuery: currentAssigns.searchQuery,
			selectedTags: currentAssigns.selectedTags,
			totalTodos: updatedTodos.length,
			completedTodos: updatedTodos.length,  // All are completed now
			pendingTodos: 0,  // None pending after bulk complete
			onlineUsers: currentAssigns.onlineUsers  // Include onlineUsers field
		};
		var updatedSocket = LiveView.assignMultiple(socket, completeAssigns);
		
		return LiveView.putFlash(updatedSocket, phoenix.Phoenix.FlashType.Info, "All todos marked as completed!");
	}
	
	static function deleteCompletedTodos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var completed: Array<server.schemas.Todo> = socket.assigns.todos.filter(function(t) return t.completed);
		
		for (todo in completed) {
			Repo.delete(todo);
		}
		
		TodoPubSub.broadcast(TodoUpdates, BulkUpdate(DeleteCompleted));
		
		var remaining = socket.assigns.todos.filter(function(t) return !t.completed);
		
		// Use complete assigns and proper type-safe socket operations
		var currentAssigns = socket.assigns;
		var completeAssigns: TodoLiveAssigns = {
			todos: remaining,
			filter: currentAssigns.filter,
			sortBy: currentAssigns.sortBy,
			currentUser: currentAssigns.currentUser,
			editingTodo: currentAssigns.editingTodo,
			showForm: currentAssigns.showForm,
			searchQuery: currentAssigns.searchQuery,
			selectedTags: currentAssigns.selectedTags,
			totalTodos: remaining.length,
			completedTodos: 0,  // All completed ones deleted
			pendingTodos: remaining.length,  // Only pending remain
			onlineUsers: currentAssigns.onlineUsers  // Include onlineUsers field
		};
		
		var updatedSocket = LiveView.assignMultiple(socket, completeAssigns);
		return LiveView.putFlash(updatedSocket, phoenix.Phoenix.FlashType.Info, "Completed todos deleted!");
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
		if (socket.assigns.editingTodo == null) {
			return socket;
		}
		
		var todo = socket.assigns.editingTodo;
		var changeset = server.schemas.Todo.changeset(todo, params);
		
		switch (Repo.update(changeset)) {
			case Ok(updatedTodo):
				// Broadcast update
				switch (TodoPubSub.broadcast(TodoUpdates, TodoUpdated(updatedTodo))) {
					case Ok(_):
						// Success
					case Error(reason):
						trace("Failed to broadcast todo update: " + reason);
				}
				
				// Clear editing state in presence and assigns (idiomatic Phoenix pattern)
				var presenceSocket = server.presence.TodoPresence.updateUserEditing(socket, socket.assigns.currentUser, null);
				var updatedSocket = SafeAssigns.setEditingTodo(presenceSocket, null);
				return loadAndAssignTodos(updatedSocket);
				
			case Error(changeset):
				return LiveView.putFlash(socket, phoenix.Phoenix.FlashType.Error, "Failed to update todo");
		}
	}
	
	// Legacy function for backward compatibility - will be removed
	static function saveEditedTodo(params: EventParams, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = socket.assigns.editingTodo;
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
				// Broadcast to other users using type-safe PubSub
				switch (TodoPubSub.broadcast(TodoUpdates, TodoUpdated(updatedTodo))) {
					case Ok(_):
						// Broadcast successful
					case Error(reason):
						trace("Failed to broadcast todo save: " + reason);
				}
				
				var updatedSocket = updateTodoInList(updatedTodo, socket);
				// Convert to LiveSocket to use assign for single field
				var liveSocket: LiveSocket<TodoLiveAssigns> = updatedSocket;
				return liveSocket.assign(_.editingTodo, null);
				
			case Error(reason):
				return LiveView.putFlash(socket, phoenix.Phoenix.FlashType.Error, "Failed to save todo: " + reason);
		}
	}
	
	// Handle bulk update messages from PubSub with type-safe socket handling
	static function handleBulkUpdate(action: BulkOperationType, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		return switch (action) {
			case CompleteAll:
				// Reload todos to reflect bulk completion
				var updatedTodos = loadTodos(socket.assigns.currentUser.id);
				// Use LiveSocket's merge for batch updates
				var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
				return liveSocket.merge({
					todos: updatedTodos,
					totalTodos: updatedTodos.length,
					completedTodos: countCompleted(updatedTodos),
					pendingTodos: countPending(updatedTodos)
				});
			
			case DeleteCompleted:
				// Reload todos to reflect bulk deletion
				var updatedTodos = loadTodos(socket.assigns.currentUser.id);
				// Use LiveSocket's merge for batch updates
				var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
				return liveSocket.merge({
					todos: updatedTodos,
					totalTodos: updatedTodos.length,
					completedTodos: countCompleted(updatedTodos),
					pendingTodos: countPending(updatedTodos)
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
		var selectedTags: Array<String> = socket.assigns.selectedTags;
		var updatedTags = selectedTags.contains(tag) ? 
			selectedTags.filter(function(t) return t != tag) :
			selectedTags.concat([tag]);
		return SafeAssigns.setSelectedTags(socket, updatedTags);
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
	public static function render(assigns: TodoLiveAssigns): String {
		return HXX.hxx('
			<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
				<div class="container mx-auto px-4 py-8 max-w-6xl">
					
					<!-- Header -->
					<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 mb-8">
						<div class="flex justify-between items-center mb-6">
							<div>
								<h1 class="text-4xl font-bold text-gray-800 dark:text-white mb-2">
									📝 Todo Manager
								</h1>
								<p class="text-gray-600 dark:text-gray-400">
									Welcome, <%= @currentUser.name %>!
								</p>
							</div>
							
							<!-- Statistics -->
							<div class="flex space-x-6">
								<div class="text-center">
									<div class="text-3xl font-bold text-blue-600 dark:text-blue-400">
										<%= @totalTodos %>
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Total</div>
								</div>
								<div class="text-center">
									<div class="text-3xl font-bold text-green-600 dark:text-green-400">
										<%= @completedTodos %>
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Completed</div>
								</div>
								<div class="text-center">
									<div class="text-3xl font-bold text-amber-600 dark:text-amber-400">
										<%= @pendingTodos %>
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Pending</div>
								</div>
							</div>
						</div>
						
						<!-- Add Todo Button -->
						<button phx-click="toggle_form" class="w-full py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-medium rounded-lg hover:from-blue-600 hover:to-indigo-700 transition-all duration-200 shadow-md">
							<%= if @showForm, do: "✖ Cancel", else: "➕ Add New Todo" %>
						</button>
					</div>
					
					<!-- New Todo Form -->
					<%= if @showForm do %>
						<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8 border-l-4 border-blue-500">
							<form phx-submit="create_todo" class="space-y-4">
								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Title *
									</label>
									<input type="text" name="title" required
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
										<input type="date" name="dueDate"
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
								
								<button type="submit"
									class="w-full py-3 bg-green-500 text-white font-medium rounded-lg hover:bg-green-600 transition-colors shadow-md">
									✅ Create Todo
								</button>
							</form>
						</div>
					<% end %>
					
					<!-- Filters and Search -->
					<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8">
						<div class="flex flex-wrap gap-4">
							<!-- Search -->
							<div class="flex-1 min-w-[300px]">
								<form phx-change="SearchTodos" class="relative">
									<input type="search" name="query" value={@searchQuery}
										class="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="Search todos..." />
									<span class="absolute left-3 top-2.5 text-gray-400">🔍</span>
								</form>
							</div>
							
							<!-- Filter Buttons -->
							<div class="flex space-x-2">
								<button phx-click="FilterTodos" phx-value-filter="all"
									class={"px-4 py-2 rounded-lg font-medium transition-colors " <> if @filter == "all", do: "bg-blue-500 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300"}>
									All
								</button>
								<button phx-click="FilterTodos" phx-value-filter="active"
									class={"px-4 py-2 rounded-lg font-medium transition-colors " <> if @filter == "active", do: "bg-blue-500 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300"}>
									Active
								</button>
								<button phx-click="FilterTodos" phx-value-filter="completed"
									class={"px-4 py-2 rounded-lg font-medium transition-colors " <> if @filter == "completed", do: "bg-blue-500 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300"}>
									Completed
								</button>
							</div>
							
							<!-- Sort Dropdown -->
							<div>
								<select phx-change="sort_todos" name="sortBy"
									class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
									<option value="created" selected={@sortBy == "created"}>Sort by Date</option>
									<option value="priority" selected={@sortBy == "priority"}>Sort by Priority</option>
									<option value="dueDate" selected={@sortBy == "dueDate"}>Sort by Due Date</option>
								</select>
							</div>
						</div>
					</div>
					
					<!-- Online Users Panel -->
					${renderPresencePanel(assigns)}
					
					<!-- Bulk Actions -->
					${renderBulkActions(assigns)}
					
					<!-- Todo List -->
					<div class="space-y-4">
						${renderTodoList(assigns)}
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
	static function renderPresencePanel(assigns: TodoLiveAssigns): String {
		var onlineCount = 0;
		var onlineUsersList = [];
		var editingIndicators = [];
		
		// Iterate once through the single presence map (Phoenix pattern)
		for (userId => entry in assigns.onlineUsers) {
			onlineCount++;
			if (entry.metas.length > 0) {
				var meta = entry.metas[0];
				
				// Show online user with editing indicator if applicable
				var editingBadge = meta.editingTodoId != null 
					? ' <span class="text-xs text-blue-500">✏️</span>' 
					: '';
				
				onlineUsersList.push('<div class="flex items-center space-x-2">
					<div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
					<span class="text-sm text-gray-700 dark:text-gray-300">${meta.userName}${editingBadge}</span>
				</div>');
				
				// Add to editing indicators if they're editing
				if (meta.editingTodoId != null) {
					editingIndicators.push('<div class="text-xs text-gray-500 dark:text-gray-400 italic">
						🖊️ ${meta.userName} is editing todo #${meta.editingTodoId}
					</div>');
				}
			}
		}
		
		if (onlineCount == 0) {
			return "";  // Don't show panel if no users online
		}
		
		return '<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 mb-6">
			<div class="flex items-center justify-between mb-2">
				<h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300">
					👥 Online Users (${onlineCount})
				</h3>
			</div>
			<div class="grid grid-cols-2 md:grid-cols-4 gap-2">
				${onlineUsersList.join("")}
			</div>
			${editingIndicators.length > 0 ? '<div class="mt-3 pt-3 border-t border-gray-200 dark:border-gray-700 space-y-1">' + editingIndicators.join("") + '</div>' : ""}
		</div>';
	}
	
	/**
	 * Render bulk actions section
	 */
	static function renderBulkActions(assigns: TodoLiveAssigns): String {
		if (assigns.todos.length == 0) {
			return "";
		}
		
		var filteredCount = filterTodos(assigns.todos, assigns.filter, assigns.searchQuery).length;
		
		return '<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 mb-6 flex justify-between items-center">
				<div class="text-sm text-gray-600 dark:text-gray-400">
					Showing ${filteredCount} of ${assigns.totalTodos} todos
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
	static function renderTodoList(assigns: TodoLiveAssigns): String {
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
		
		var filteredTodos = filterAndSortTodos(assigns.todos, assigns.filter, assigns.sortBy, assigns.searchQuery);
		var todoItems = [];
		for (todo in filteredTodos) {
			todoItems.push(renderTodoItem(todo, assigns.editingTodo));
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
			return '<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 ${priorityColor}">
					<form phx-submit="save_todo" class="space-y-4">
						<input type="hidden" name="id" value="${todo.id}" />
						<input type="text" name="title" value="${todo.title}" required
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
			
			return '<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 ${priorityColor} ${completedClass} transition-all hover:shadow-xl">
					<div class="flex items-start space-x-4">
						<!-- Checkbox -->
						<button phx-click="toggle_todo" phx-value-id="${todo.id}"
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
									'<span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">Due: ${todo.dueDate}</span>' : 
									''}
								${renderTags(todo.tags)}
							</div>
						</div>
						
						<!-- Actions -->
						<div class="flex space-x-2">
							<button phx-click="edit_todo" phx-value-id="${todo.id}"
								class="p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition-colors">
								✏️
							</button>
							<button phx-click="delete_todo" phx-value-id="${todo.id}"
								data-confirm="Are you sure?"
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
			tagElements.push('<button phx-click="toggle_tag" phx-value-tag="${tag}" class="px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400 rounded text-xs hover:bg-blue-200">#${tag}</button>');
		}
		return tagElements.join("");
	}
	
	/**
	 * Helper to filter todos based on filter and search query
	 */
	static function filterTodos(todos: Array<server.schemas.Todo>, filter: String, searchQuery: String): Array<server.schemas.Todo> {
		var filtered = todos;
		
		// Apply filter
		filtered = switch(filter) {
			case "active": filtered.filter(function(t) return !t.completed);
			case "completed": filtered.filter(function(t) return t.completed);
			case _: filtered;
		};
		
		// Apply search
		if (searchQuery != null && searchQuery != "") {
			var query = searchQuery.toLowerCase();
			filtered = filtered.filter(function(t) {
				return t.title.toLowerCase().indexOf(query) >= 0 ||
					   (t.description != null && t.description.toLowerCase().indexOf(query) >= 0);
			});
		}
		
		return filtered;
	}
	
	/**
	 * Helper to filter and sort todos
	 */
	static function filterAndSortTodos(todos: Array<server.schemas.Todo>, filter: String, sortBy: String, searchQuery: String): Array<server.schemas.Todo> {
		var filtered = filterTodos(todos, filter, searchQuery);
		
		// Apply sorting
		// Note: In real implementation, this would use proper date/priority comparison
		// For now, we'll keep the original order
		return filtered;
	}
}
