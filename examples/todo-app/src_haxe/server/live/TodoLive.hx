package server.live;

import server.schemas.Todo;
import phoenix.Phoenix;
import phoenix.Phoenix.Socket;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.HandleInfoResult;
import phoenix.Phoenix.FlashType;
import phoenix.Ecto; // Re-enable Ecto imports
import server.types.Types.User;
import server.types.Types.MountParams;
import server.types.Types.Session;
import server.types.Types.EventParams;
import server.types.Types.PubSubMessage;
import server.types.Types.BulkOperationType;
import server.pubsub.TodoPubSub;
import server.pubsub.TodoPubSub.TodoPubSubTopic;
import server.pubsub.TodoPubSub.TodoPubSubMessage;
import server.live.SafeAssigns;
import server.live.TypeSafeConversions;
import server.infrastructure.Repo; // Import the TodoApp.Repo module
import elixir.types.Result.*;  // Import the enum constructors directly
import HXX;  // Import HXX for template rendering

using StringTools;

// For convenience, alias Ecto types for cleaner code
typedef EctoQuery = phoenix.Ecto.EctoQuery;
typedef EctoChangeset = phoenix.Ecto.EctoChangeset;

/**
 * Type-safe assigns structure for TodoLive socket
 * 
 * This structure defines all the state that can be stored in the LiveView socket.
 * Using this typedef ensures compile-time type safety for all socket operations.
 */
typedef TodoLiveAssigns = {
	var todos: Array<server.schemas.Todo>;
	var filter: String; // all, active, completed
	var sort_by: String; // created, priority, due_date
	var current_user: User;
	var editing_todo: Null<server.schemas.Todo>;
	var show_form: Bool;
	var search_query: String;
	var selected_tags: Array<String>;
	// Statistics
	var total_todos: Int;
	var completed_todos: Int;
	var pending_todos: Int;
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
		
		var current_user = get_user_from_session(session);
		var todos = load_todos(current_user.id);
		
		// Create type-safe assigns structure
		var assigns: TodoLiveAssigns = {
			todos: todos,
			filter: "all",
			sort_by: "created",
			current_user: current_user,
			editing_todo: null,
			show_form: false,
			search_query: "",
			selected_tags: [],
			total_todos: todos.length,
			completed_todos: count_completed(todos),
			pending_todos: count_pending(todos)
		};
		
		// The TAssigns type parameter will be inferred as TodoLiveAssigns
		var updated_socket = LiveView.assign_multiple(socket, assigns);
		
		return Ok(updated_socket);
	}
	
	/**
	 * Handle events with type-safe assigns
	 * 
	 * The TAssigns type parameter will be inferred as TodoLiveAssigns from the socket parameter.
	 */
	public static function handle_event(event: String, params: EventParams, socket: Socket<TodoLiveAssigns>): HandleEventResult<TodoLiveAssigns> {
		var result_socket = switch (event) {
			case "create_todo":
				create_new_todo(params, socket);
			
			case "toggle_todo":
				toggle_todo_status(params.id, socket);
			
			case "delete_todo":
				delete_todo(params.id, socket);
			
			case "edit_todo":
				start_editing(params.id, socket);
			
			case "save_todo":
				save_edited_todo(params, socket);
			
			case "cancel_edit":
				SafeAssigns.setEditingTodo(socket, null);
			
			case "filter_todos":
				SafeAssigns.setFilter(socket, params.filter);
			
			case "sort_todos":
				SafeAssigns.setSortBy(socket, params.sort_by);
			
			case "search_todos":
				SafeAssigns.setSearchQuery(socket, params.query);
			
			case "toggle_tag":
				toggle_tag_filter(params.tag, socket);
			
			case "set_priority":
				update_todo_priority(params.id, params.priority, socket);
			
			case "toggle_form":
				SafeAssigns.setShowForm(socket, !socket.assigns.show_form);
			
			case "bulk_complete":
				complete_all_todos(socket);
			
			case "bulk_delete_completed":
				delete_completed_todos(socket);
			
			case _:
				socket;
		};
		
		return NoReply(result_socket);
	}
	
	/**
	 * Handle real-time updates from other users with type-safe assigns
	 * 
	 * The TAssigns type parameter will be inferred as TodoLiveAssigns from the socket parameter.
	 */
	public static function handle_info(msg: PubSubMessage, socket: Socket<TodoLiveAssigns>): HandleInfoResult<TodoLiveAssigns> {
		// Parse incoming message to type-safe enum (will be auto-generated in Phase 2)
		var result_socket = switch (TodoPubSub.parseMessage(msg)) {
			case Some(parsedMsg):
				switch (parsedMsg) {
					case TodoCreated(todo):
						add_todo_to_list(todo, socket);
					
					case TodoUpdated(todo):
						update_todo_in_list(todo, socket);
					
					case TodoDeleted(id):
						remove_todo_from_list(id, socket);
					
					case BulkUpdate(action):
						handle_bulk_update(action, socket);
					
					case UserOnline(user_id):
						// Could update online user list in future
						socket;
					
					case UserOffline(user_id):
						// Could update online user list in future
						socket;
					
					case SystemAlert(message, level):
						// Show system alert to user
						var flash_type = switch (level) {
							case Info: phoenix.Phoenix.FlashType.Info;
							case Warning: phoenix.Phoenix.FlashType.Warning;
							case Error: phoenix.Phoenix.FlashType.Error;
							case Critical: phoenix.Phoenix.FlashType.Error;
						};
						LiveView.put_flash(socket, flash_type, message);
				}
			
			case None:
				// Unknown or malformed message - log and ignore
				trace("Received unknown PubSub message: " + msg);
				socket;
		};
		
		return NoReply(result_socket);
	}
	
	// Helper functions with type-safe socket handling
	static function create_new_todo(params: EventParams, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo_params = {
			title: params.title,
			description: params.description,
			completed: false,
			priority: params.priority != null ? params.priority : "medium",
			due_date: params.due_date,
			tags: parse_tags(params.tags),
			user_id: socket.assigns.current_user.id
		};
		
		// Convert EventParams to ChangesetParams with type safety
		var changesetParams = TypeSafeConversions.eventParamsToChangesetParams(params);
		var changeset = server.schemas.Todo.changeset(new server.schemas.Todo(), changesetParams);
		
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
				// Use complete assigns structure for type safety
				var currentAssigns = socket.assigns;
				var completeAssigns = TypeSafeConversions.createCompleteAssigns(
					currentAssigns,
					todos,
					null, // filter unchanged
					null, // sort_by unchanged
					null, // current_user unchanged  
					null, // editing_todo unchanged
					false, // show_form = false
					null, // search_query unchanged
					null  // selected_tags unchanged
				);
				var updated_socket = LiveView.assign_multiple(socket, completeAssigns);
				return LiveView.put_flash(updated_socket, Success, "Todo created successfully!");
				
			case Error(reason):
				return LiveView.put_flash(socket, phoenix.Phoenix.FlashType.Error, "Failed to create todo: " + reason);
		}
	}
	
	static function toggle_todo_status(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = find_todo(id, socket.assigns.todos);
		if (todo == null) return socket;
		
		var updated_changeset = server.schemas.Todo.toggle_completed(todo);
		
		// Use type-safe Repo operations
		switch (Repo.update(updated_changeset)) {
			case Ok(updated_todo):
				// Broadcast to other users using type-safe PubSub with compile-time validation
				switch (TodoPubSub.broadcast(TodoUpdates, TodoUpdated(updated_todo))) {
					case Ok(_):
						// Broadcast successful
					case Error(reason):
						trace("Failed to broadcast todo update: " + reason);
				}
				
				return update_todo_in_list(updated_todo, socket);
				
			case Error(reason):
				return LiveView.put_flash(socket, phoenix.Phoenix.FlashType.Error, "Failed to update todo: " + reason);
		}
	}
	
	static function delete_todo(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = find_todo(id, socket.assigns.todos);
		if (todo == null) return socket;
		
		// Use type-safe Repo operations
		switch (Repo.delete(todo)) {
			case Ok(deleted_todo):
				// Broadcast to other users using type-safe PubSub
				switch (TodoPubSub.broadcast(TodoUpdates, TodoDeleted(id))) {
					case Ok(_):
						// Broadcast successful
					case Error(reason):
						trace("Failed to broadcast todo deletion: " + reason);
				}
				
				return remove_todo_from_list(id, socket);
				
			case Error(reason):
				return LiveView.put_flash(socket, phoenix.Phoenix.FlashType.Error, "Failed to delete todo: " + reason);
		}
	}
	
	static function update_todo_priority(id: Int, priority: String, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = find_todo(id, socket.assigns.todos);
		if (todo == null) return socket;
		
		var updated_changeset = server.schemas.Todo.update_priority(todo, priority);
		
		// Use type-safe Repo operations
		switch (Repo.update(updated_changeset)) {
			case Ok(updated_todo):
				// Broadcast to other users using type-safe PubSub
				switch (TodoPubSub.broadcast(TodoUpdates, TodoUpdated(updated_todo))) {
					case Ok(_):
						// Broadcast successful
					case Error(reason):
						trace("Failed to broadcast todo priority update: " + reason);
				}
				
				return update_todo_in_list(updated_todo, socket);
				
			case Error(reason):
				return LiveView.put_flash(socket, phoenix.Phoenix.FlashType.Error, "Failed to update priority: " + reason);
		}
	}
	
	// List management helpers with type-safe socket handling
	static function add_todo_to_list(todo: server.schemas.Todo, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		// Don't add if it's our own todo (already added)
		if (todo.user_id == socket.assigns.current_user.id) {
			return socket;
		}
		
		var todos = [todo].concat(socket.assigns.todos);
		// Use complete assigns structure for type safety
		var currentAssigns = socket.assigns;
		var completeAssigns = TypeSafeConversions.createCompleteAssigns(
			currentAssigns,
			todos // Updated todos list
			// All other fields will maintain current values from base
		);
		return LiveView.assign_multiple(socket, completeAssigns);
	}
	
	static function update_todo_in_list(updated_todo: server.schemas.Todo, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todos = socket.assigns.todos.map(function(t) {
			return t.id == updated_todo.id ? updated_todo : t;
		});
		
		// Use complete assigns structure for type safety
		var currentAssigns = socket.assigns;
		var completeAssigns = TypeSafeConversions.createCompleteAssigns(
			currentAssigns,
			todos // Updated todos list
			// All other fields will maintain current values from base
		);
		return LiveView.assign_multiple(socket, completeAssigns);
	}
	
	static function remove_todo_from_list(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todos = socket.assigns.todos.filter(function(t) {
			return t.id != id;
		});
		
		// Use complete assigns structure for type safety
		var currentAssigns = socket.assigns;
		var completeAssigns = TypeSafeConversions.createCompleteAssigns(
			currentAssigns,
			todos // Updated todos list
			// All other fields will maintain current values from base
		);
		return LiveView.assign_multiple(socket, completeAssigns);
	}
	
	// Utility functions
	static function load_todos(user_id: Int): Array<server.schemas.Todo> {
		// Use type-safe EctoQuery with proper method chaining
		var query = EctoQuery.from(server.schemas.Todo, "t");
		var whereConditions = new Map<String, phoenix.Ecto.QueryValue>();
		whereConditions.set("user_id", phoenix.Ecto.QueryValue.Integer(user_id));
		var conditions: phoenix.Ecto.QueryConditions = { where: whereConditions };
		query = EctoQuery.where(query, conditions);
		// TODO: Fix Ecto extern definition to support proper order_by syntax
		// CURRENT ISSUE: OrderByClause typedef generates %{"field" => "inserted_at", "direction" => :asc, "nulls" => :default}
		// IDEAL APPROACH: Should generate Elixir keyword list syntax like [asc: :inserted_at] or [asc: :inserted_at, nulls: :first]
		// SIMPLER APPROACH: Use __elixir__() injection: query |> order_by([asc: :inserted_at])
		// query = EctoQuery.order_by(query, [{field: "inserted_at", direction: phoenix.Ecto.SortDirection.Asc, nulls: phoenix.Ecto.NullsPosition.Default}]);
		return Repo.all(query);
	}
	
	static function find_todo(id: Int, todos: Array<server.schemas.Todo>): Null<server.schemas.Todo> {
		for (todo in todos) {
			if (todo.id == id) return todo;
		}
		return null;
	}
	
	static function count_completed(todos: Array<server.schemas.Todo>): Int {
		var count = 0;
		for (todo in todos) {
			if (todo.completed) count++;
		}
		return count;
	}
	
	static function count_pending(todos: Array<server.schemas.Todo>): Int {
		var count = 0;
		for (todo in todos) {
			if (!todo.completed) count++;
		}
		return count;
	}
	
	static function parse_tags(tags_string: String): Array<String> {
		if (tags_string == null || tags_string == "") return [];
		return tags_string.split(",").map(function(t) return t.trim());
	}
	
	static function get_user_from_session(session: Session): User {
		// In real app, would fetch from session/token and validate properly
		// For demo purposes, return a properly typed User object
		return {
			id: session.user_id != null ? session.user_id : 1,
			name: "Demo User",
			email: "demo@example.com", 
			password_hash: "hashed_password",
			confirmed_at: null,
			last_login_at: null,
			active: true
		};
	}
	
	// Bulk operations with type-safe socket handling
	static function complete_all_todos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var pending: Array<server.schemas.Todo> = socket.assigns.todos.filter(function(t) return !t.completed);
		
		// Update all pending todos
		for (todo in pending) {
			var updated_changeset = server.schemas.Todo.toggle_completed(todo);
			switch (Repo.update(updated_changeset)) {
				case Ok(updated_todo):
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
		var updated_todos = load_todos(socket.assigns.current_user.id);
		var currentAssigns = socket.assigns;
		var completeAssigns = TypeSafeConversions.createCompleteAssigns(
			currentAssigns,
			updated_todos
		);
		// Override calculated statistics for bulk complete
		completeAssigns.completed_todos = completeAssigns.total_todos;
		completeAssigns.pending_todos = 0;
		var updated_socket = LiveView.assign_multiple(socket, completeAssigns);
		
		return LiveView.put_flash(updated_socket, Info, "All todos marked as completed!");
	}
	
	static function delete_completed_todos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var completed: Array<server.schemas.Todo> = socket.assigns.todos.filter(function(t) return t.completed);
		
		for (todo in completed) {
			Repo.delete(todo);
		}
		
		TodoPubSub.broadcast(TodoUpdates, BulkUpdate(DeleteCompleted));
		
		var remaining = socket.assigns.todos.filter(function(t) return !t.completed);
		
		// Use complete assigns and proper type-safe socket operations
		var currentAssigns = socket.assigns;
		var completeAssigns = TypeSafeConversions.createCompleteAssigns(
			currentAssigns,
			remaining
		);
		// Override calculated statistics
		completeAssigns.completed_todos = 0;
		completeAssigns.pending_todos = remaining.length;
		
		var updated_socket = LiveView.assign_multiple(socket, completeAssigns);
		return LiveView.put_flash(updated_socket, Info, "Completed todos deleted!");
	}
	
	// Additional helper functions with type-safe socket handling
	static function start_editing(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = find_todo(id, socket.assigns.todos);
		return SafeAssigns.setEditingTodo(socket, todo);
	}
	
	static function save_edited_todo(params: EventParams, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = socket.assigns.editing_todo;
		if (todo == null) return socket;
		
		// Convert EventParams to ChangesetParams with type safety
		var changesetParams = TypeSafeConversions.eventParamsToChangesetParams(params);
		var changeset = server.schemas.Todo.changeset(todo, changesetParams);
		
		// Use type-safe Repo operations
		switch (Repo.update(changeset)) {
			case Ok(updated_todo):
				// Broadcast to other users using type-safe PubSub
				switch (TodoPubSub.broadcast(TodoUpdates, TodoUpdated(updated_todo))) {
					case Ok(_):
						// Broadcast successful
					case Error(reason):
						trace("Failed to broadcast todo save: " + reason);
				}
				
				var updated_socket = update_todo_in_list(updated_todo, socket);
				return LiveView.assign(updated_socket, "editing_todo", null);
				
			case Error(reason):
				return LiveView.put_flash(socket, phoenix.Phoenix.FlashType.Error, "Failed to save todo: " + reason);
		}
	}
	
	// Handle bulk update messages from PubSub with type-safe socket handling
	static function handle_bulk_update(action: BulkOperationType, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		return switch (action) {
			case CompleteAll:
				// Reload todos to reflect bulk completion
				var updated_todos = load_todos(socket.assigns.current_user.id);
				// Use complete assigns structure for type safety
				var currentAssigns = socket.assigns;
				var completeAssigns = TypeSafeConversions.createCompleteAssigns(
					currentAssigns,
					updated_todos
				);
				LiveView.assign_multiple(socket, completeAssigns);
			
			case DeleteCompleted:
				// Reload todos to reflect bulk deletion
				var updated_todos = load_todos(socket.assigns.current_user.id);
				// Use complete assigns structure for type safety
				var currentAssigns = socket.assigns;
				var completeAssigns = TypeSafeConversions.createCompleteAssigns(
					currentAssigns,
					updated_todos
				);
				LiveView.assign_multiple(socket, completeAssigns);
			
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
	
	static function toggle_tag_filter(tag: String, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var selected_tags: Array<String> = socket.assigns.selected_tags;
		var updated_tags = selected_tags.contains(tag) ? 
			selected_tags.filter(function(t) return t != tag) :
			selected_tags.concat([tag]);
		return SafeAssigns.setSelectedTags(socket, updated_tags);
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
									Welcome, <%= @current_user.name %>!
								</p>
							</div>
							
							<!-- Statistics -->
							<div class="flex space-x-6">
								<div class="text-center">
									<div class="text-3xl font-bold text-blue-600 dark:text-blue-400">
										<%= @total_todos %>
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Total</div>
								</div>
								<div class="text-center">
									<div class="text-3xl font-bold text-green-600 dark:text-green-400">
										<%= @completed_todos %>
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Completed</div>
								</div>
								<div class="text-center">
									<div class="text-3xl font-bold text-amber-600 dark:text-amber-400">
										<%= @pending_todos %>
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Pending</div>
								</div>
							</div>
						</div>
						
						<!-- Add Todo Button -->
						<button phx-click="toggle_form" class="w-full py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-medium rounded-lg hover:from-blue-600 hover:to-indigo-700 transition-all duration-200 shadow-md">
							<%= if @show_form, do: "✖ Cancel", else: "➕ Add New Todo" %>
						</button>
					</div>
					
					<!-- New Todo Form -->
					<%= if @show_form do %>
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
										<input type="date" name="due_date"
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
								<form phx-change="search_todos" class="relative">
									<input type="search" name="query" value={@search_query}
										class="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="Search todos..." />
									<span class="absolute left-3 top-2.5 text-gray-400">🔍</span>
								</form>
							</div>
							
							<!-- Filter Buttons -->
							<div class="flex space-x-2">
								<button phx-click="filter_todos" phx-value-filter="all"
									class={"px-4 py-2 rounded-lg font-medium transition-colors " <> if @filter == "all", do: "bg-blue-500 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300"}>
									All
								</button>
								<button phx-click="filter_todos" phx-value-filter="active"
									class={"px-4 py-2 rounded-lg font-medium transition-colors " <> if @filter == "active", do: "bg-blue-500 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300"}>
									Active
								</button>
								<button phx-click="filter_todos" phx-value-filter="completed"
									class={"px-4 py-2 rounded-lg font-medium transition-colors " <> if @filter == "completed", do: "bg-blue-500 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300"}>
									Completed
								</button>
							</div>
							
							<!-- Sort Dropdown -->
							<div>
								<select phx-change="sort_todos" name="sort_by"
									class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
									<option value="created" selected={@sort_by == "created"}>Sort by Date</option>
									<option value="priority" selected={@sort_by == "priority"}>Sort by Priority</option>
									<option value="due_date" selected={@sort_by == "due_date"}>Sort by Due Date</option>
								</select>
							</div>
						</div>
					</div>
					
					<!-- Bulk Actions -->
					${render_bulk_actions(assigns)}
					
					<!-- Todo List -->
					<div class="space-y-4">
						${render_todo_list(assigns)}
					</div>
				</div>
			</div>
		');
	}
	
	/**
	 * Render bulk actions section
	 */
	static function render_bulk_actions(assigns: TodoLiveAssigns): String {
		if (assigns.todos.length == 0) {
			return "";
		}
		
		var filteredCount = filter_todos(assigns.todos, assigns.filter, assigns.search_query).length;
		
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
	static function render_todo_list(assigns: TodoLiveAssigns): String {
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
		
		var filteredTodos = filter_and_sort_todos(assigns.todos, assigns.filter, assigns.sort_by, assigns.search_query);
		var todoItems = [];
		for (todo in filteredTodos) {
			todoItems.push(render_todo_item(todo, assigns.editing_todo));
		}
		return todoItems.join("\n");
	}
	
	/**
	 * Render individual todo item
	 */
	static function render_todo_item(todo: server.schemas.Todo, editing_todo: Null<server.schemas.Todo>): String {
		var is_editing = editing_todo != null && editing_todo.id == todo.id;
		var priority_color = switch(todo.priority) {
			case "high": "border-red-500";
			case "medium": "border-yellow-500";
			case "low": "border-green-500";
			case _: "border-gray-300";
		};
		
		if (is_editing) {
			return '<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 ${priority_color}">
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
			var completed_class = todo.completed ? "opacity-60" : "";
			var text_decoration = todo.completed ? "line-through" : "";
			var checkmark = todo.completed ? '<span class="text-green-500">✓</span>' : '';
			
			return '<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 ${priority_color} ${completed_class} transition-all hover:shadow-xl">
					<div class="flex items-start space-x-4">
						<!-- Checkbox -->
						<button phx-click="toggle_todo" phx-value-id="${todo.id}"
							class="mt-1 w-6 h-6 rounded border-2 border-gray-300 dark:border-gray-600 flex items-center justify-center hover:border-blue-500 transition-colors">
							${checkmark}
						</button>
						
						<!-- Content -->
						<div class="flex-1">
							<h3 class="text-lg font-semibold text-gray-800 dark:text-white ${text_decoration}">
								${todo.title}
							</h3>
							${todo.description != null && todo.description != "" ? 
								'<p class="text-gray-600 dark:text-gray-400 mt-1 ${text_decoration}">${todo.description}</p>' : 
								''}
							
							<!-- Meta info -->
							<div class="flex flex-wrap gap-2 mt-3">
								<span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">
									Priority: ${todo.priority}
								</span>
								${todo.due_date != null ? 
									'<span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">Due: ${todo.due_date}</span>' : 
									''}
								${render_tags(todo.tags)}
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
	static function render_tags(tags: Array<String>): String {
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
	static function filter_todos(todos: Array<server.schemas.Todo>, filter: String, search_query: String): Array<server.schemas.Todo> {
		var filtered = todos;
		
		// Apply filter
		filtered = switch(filter) {
			case "active": filtered.filter(function(t) return !t.completed);
			case "completed": filtered.filter(function(t) return t.completed);
			case _: filtered;
		};
		
		// Apply search
		if (search_query != null && search_query != "") {
			var query = search_query.toLowerCase();
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
	static function filter_and_sort_todos(todos: Array<server.schemas.Todo>, filter: String, sort_by: String, search_query: String): Array<server.schemas.Todo> {
		var filtered = filter_todos(todos, filter, search_query);
		
		// Apply sorting
		// Note: In real implementation, this would use proper date/priority comparison
		// For now, we'll keep the original order
		return filtered;
	}
}