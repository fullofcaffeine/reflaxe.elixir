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

using StringTools;

// For convenience, alias Ecto types for cleaner code
typedef Repo = phoenix.Ecto.EctoRepo;
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
		
		var changeset = server.schemas.Todo.changeset(new server.schemas.Todo(), todo_params);
		
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
				var updated_socket = LiveView.assign_multiple(socket, {
					todos: todos,
					show_form: false,
					total_todos: todos.length,
					pending_todos: socket.assigns.pending_todos + 1
				});
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
				switch (PubSub.broadcast("todo:updates", {
					type: "todo_deleted",
					id: id
				})) {
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
				switch (PubSub.broadcast("todo:updates", {
					type: "todo_updated",
					todo: updated_todo
				})) {
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
		return LiveView.assign_multiple(socket, {
			todos: todos,
			total_todos: todos.length,
			pending_todos: count_pending(todos),
			completed_todos: count_completed(todos)
		});
	}
	
	static function update_todo_in_list(updated_todo: server.schemas.Todo, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todos = socket.assigns.todos.map(function(t) {
			return t.id == updated_todo.id ? updated_todo : t;
		});
		
		return LiveView.assign_multiple(socket, {
			todos: todos,
			completed_todos: count_completed(todos),
			pending_todos: count_pending(todos)
		});
	}
	
	static function remove_todo_from_list(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todos = socket.assigns.todos.filter(function(t) {
			return t.id != id;
		});
		
		return LiveView.assign_multiple(socket, {
			todos: todos,
			total_todos: todos.length,
			completed_todos: count_completed(todos),
			pending_todos: count_pending(todos)
		});
	}
	
	// Utility functions
	static function load_todos(user_id: Int): Array<server.schemas.Todo> {
		// Use type-safe EctoQuery with proper method chaining
		var query = EctoQuery.from(server.schemas.Todo, "t");
		var whereConditions = new Map<String, phoenix.Ecto.QueryValue>();
		whereConditions.set("user_id", phoenix.Ecto.QueryValue.Integer(user_id));
		var conditions: phoenix.Ecto.QueryConditions = { where: whereConditions };
		query = EctoQuery.where(query, conditions);
		query = EctoQuery.order_by(query, [{field: "inserted_at", direction: phoenix.Ecto.SortDirection.Asc, nulls: phoenix.Ecto.NullsPosition.Default}]);
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
		switch (PubSub.broadcast("todo:updates", {
			type: "bulk_update",
			action: "complete_all"
		})) {
			case Ok(_):
				// Broadcast successful
			case Error(reason):
				trace("Failed to broadcast bulk complete: " + reason);
		}
		
		// Reload todos and update socket
		var updated_todos = load_todos(socket.assigns.current_user.id);
		var updated_socket = LiveView.assign_multiple(socket, {
			todos: updated_todos,
			completed_todos: socket.assigns.total_todos,
			pending_todos: 0
		});
		
		return LiveView.put_flash(updated_socket, Info, "All todos marked as completed!");
	}
	
	static function delete_completed_todos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var completed: Array<server.schemas.Todo> = socket.assigns.todos.filter(function(t) return t.completed);
		
		for (todo in completed) {
			Repo.delete(todo);
		}
		
		phoenix.Phoenix.PubSub.broadcast("todo:updates", {
			type: "bulk_delete",
			action: "delete_completed"
		});
		
		var remaining = socket.assigns.todos.filter(function(t) return !t.completed);
		
		return socket
			.assign({
				todos: remaining,
				total_todos: remaining.length,
				completed_todos: 0,
				pending_todos: remaining.length
			})
			.put_flash("info", "Completed todos deleted!");
	}
	
	// Additional helper functions with type-safe socket handling
	static function start_editing(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = find_todo(id, socket.assigns.todos);
		return SafeAssigns.setEditingTodo(socket, todo);
	}
	
	static function save_edited_todo(params: EventParams, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = socket.assigns.editing_todo;
		if (todo == null) return socket;
		
		var changeset = server.schemas.Todo.changeset(todo, params);
		
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
				LiveView.assign_multiple(socket, {
					todos: updated_todos,
					completed_todos: count_completed(updated_todos),
					pending_todos: count_pending(updated_todos)
				});
			
			case DeleteCompleted:
				// Reload todos to reflect bulk deletion
				var updated_todos = load_todos(socket.assigns.current_user.id);
				LiveView.assign_multiple(socket, {
					todos: updated_todos,
					total_todos: updated_todos.length,
					completed_todos: count_completed(updated_todos),
					pending_todos: count_pending(updated_todos)
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
	
	static function toggle_tag_filter(tag: String, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var selected_tags: Array<String> = socket.assigns.selected_tags;
		var updated_tags = selected_tags.contains(tag) ? 
			selected_tags.filter(function(t) return t != tag) :
			selected_tags.concat([tag]);
		return SafeAssigns.setSelectedTags(socket, updated_tags);
	}
}