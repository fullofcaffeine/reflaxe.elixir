package live;

import schemas.Todo;
import schemas.User;

/**
 * LiveView component for todo management with real-time updates
 */
@:liveview
class TodoLive {
	// Socket assigns
	var todos: Array<Dynamic> = [];
	var filter: String = "all"; // all, active, completed
	var sort_by: String = "created"; // created, priority, due_date
	var current_user: Dynamic;
	var editing_todo: Dynamic = null;
	var show_form: Bool = false;
	var search_query: String = "";
	var selected_tags: Array<String> = [];
	
	// Statistics
	var total_todos: Int = 0;
	var completed_todos: Int = 0;
	var pending_todos: Int = 0;
	
	public static function mount(_params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic {
		// Subscribe to todo updates for real-time sync
		Phoenix.PubSub.subscribe("todo:updates");
		
		var current_user = get_user_from_session(session);
		var todos = load_todos(current_user.id);
		
		return socket.assign({
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
		});
	}
	
	// Handle events
	public static function handle_event(event: String, params: Dynamic, socket: Dynamic): Dynamic {
		return switch (event) {
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
				socket.assign({editing_todo: null});
			
			case "filter_todos":
				socket.assign({filter: params.filter});
			
			case "sort_todos":
				socket.assign({sort_by: params.sort_by});
			
			case "search_todos":
				socket.assign({search_query: params.query});
			
			case "toggle_tag":
				toggle_tag_filter(params.tag, socket);
			
			case "set_priority":
				update_todo_priority(params.id, params.priority, socket);
			
			case "toggle_form":
				socket.assign({show_form: !socket.assigns.show_form});
			
			case "bulk_complete":
				complete_all_todos(socket);
			
			case "bulk_delete_completed":
				delete_completed_todos(socket);
			
			case _:
				socket;
		}
	}
	
	// Handle real-time updates from other users
	public static function handle_info(msg: Dynamic, socket: Dynamic): Dynamic {
		return switch (msg.type) {
			case "todo_created":
				add_todo_to_list(msg.todo, socket);
			
			case "todo_updated":
				update_todo_in_list(msg.todo, socket);
			
			case "todo_deleted":
				remove_todo_from_list(msg.id, socket);
			
			case _:
				socket;
		}
	}
	
	// Helper functions
	static function create_new_todo(params: Dynamic, socket: Dynamic): Dynamic {
		var todo_params = {
			title: params.title,
			description: params.description,
			priority: params.priority || "medium",
			due_date: params.due_date,
			tags: parse_tags(params.tags),
			user_id: socket.assigns.current_user.id
		};
		
		var changeset = Todo.changeset(new Todo(), todo_params);
		
		return switch (Repo.insert(changeset)) {
			case {:ok, todo}:
				// Broadcast to other users
				Phoenix.PubSub.broadcast("todo:updates", {
					type: "todo_created",
					todo: todo
				});
				
				var todos = [todo].concat(socket.assigns.todos);
				socket
					.assign({
						todos: todos,
						show_form: false,
						total_todos: todos.length,
						pending_todos: socket.assigns.pending_todos + 1
					})
					.put_flash("info", "Todo created successfully!");
			
			case {:error, changeset}:
				socket.put_flash("error", "Failed to create todo");
		}
	}
	
	static function toggle_todo_status(id: Int, socket: Dynamic): Dynamic {
		var todo = find_todo(id, socket.assigns.todos);
		if (todo == null) return socket;
		
		var updated_todo = Todo.toggle_completed(todo);
		
		return switch (Repo.update(updated_todo)) {
			case {:ok, todo}:
				Phoenix.PubSub.broadcast("todo:updates", {
					type: "todo_updated",
					todo: todo
				});
				
				update_todo_in_list(todo, socket);
			
			case {:error, _}:
				socket.put_flash("error", "Failed to update todo");
		}
	}
	
	static function delete_todo(id: Int, socket: Dynamic): Dynamic {
		var todo = find_todo(id, socket.assigns.todos);
		if (todo == null) return socket;
		
		return switch (Repo.delete(todo)) {
			case {:ok, _}:
				Phoenix.PubSub.broadcast("todo:updates", {
					type: "todo_deleted",
					id: id
				});
				
				remove_todo_from_list(id, socket);
			
			case {:error, _}:
				socket.put_flash("error", "Failed to delete todo");
		}
	}
	
	static function update_todo_priority(id: Int, priority: String, socket: Dynamic): Dynamic {
		var todo = find_todo(id, socket.assigns.todos);
		if (todo == null) return socket;
		
		var updated_todo = Todo.update_priority(todo, priority);
		
		return switch (Repo.update(updated_todo)) {
			case {:ok, todo}:
				Phoenix.PubSub.broadcast("todo:updates", {
					type: "todo_updated",
					todo: todo
				});
				
				update_todo_in_list(todo, socket);
			
			case {:error, _}:
				socket.put_flash("error", "Failed to update priority");
		}
	}
	
	// List management helpers
	static function add_todo_to_list(todo: Dynamic, socket: Dynamic): Dynamic {
		// Don't add if it's our own todo (already added)
		if (todo.user_id == socket.assigns.current_user.id) {
			return socket;
		}
		
		var todos = [todo].concat(socket.assigns.todos);
		return socket.assign({
			todos: todos,
			total_todos: todos.length,
			pending_todos: count_pending(todos),
			completed_todos: count_completed(todos)
		});
	}
	
	static function update_todo_in_list(updated_todo: Dynamic, socket: Dynamic): Dynamic {
		var todos = socket.assigns.todos.map(function(t) {
			return t.id == updated_todo.id ? updated_todo : t;
		});
		
		return socket.assign({
			todos: todos,
			completed_todos: count_completed(todos),
			pending_todos: count_pending(todos)
		});
	}
	
	static function remove_todo_from_list(id: Int, socket: Dynamic): Dynamic {
		var todos = socket.assigns.todos.filter(function(t) {
			return t.id != id;
		});
		
		return socket.assign({
			todos: todos,
			total_todos: todos.length,
			completed_todos: count_completed(todos),
			pending_todos: count_pending(todos)
		});
	}
	
	// Utility functions
	static function load_todos(user_id: Int): Array<Dynamic> {
		return Repo.all(
			from(t in Todo)
				.where(t.user_id == user_id)
				.order_by(desc: t.inserted_at)
				.preload(:user)
		);
	}
	
	static function find_todo(id: Int, todos: Array<Dynamic>): Dynamic {
		for (todo in todos) {
			if (todo.id == id) return todo;
		}
		return null;
	}
	
	static function count_completed(todos: Array<Dynamic>): Int {
		var count = 0;
		for (todo in todos) {
			if (todo.completed) count++;
		}
		return count;
	}
	
	static function count_pending(todos: Array<Dynamic>): Int {
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
	
	static function get_user_from_session(session: Dynamic): Dynamic {
		// In real app, would fetch from session/token
		return {id: 1, name: "Demo User", email: "demo@example.com"};
	}
	
	// Bulk operations
	static function complete_all_todos(socket: Dynamic): Dynamic {
		var pending = socket.assigns.todos.filter(function(t) return !t.completed);
		
		for (todo in pending) {
			var updated = Todo.toggle_completed(todo);
			Repo.update(updated);
		}
		
		Phoenix.PubSub.broadcast("todo:updates", {
			type: "bulk_update",
			action: "complete_all"
		});
		
		return socket
			.assign({
				todos: load_todos(socket.assigns.current_user.id),
				completed_todos: socket.assigns.total_todos,
				pending_todos: 0
			})
			.put_flash("info", "All todos marked as completed!");
	}
	
	static function delete_completed_todos(socket: Dynamic): Dynamic {
		var completed = socket.assigns.todos.filter(function(t) return t.completed);
		
		for (todo in completed) {
			Repo.delete(todo);
		}
		
		Phoenix.PubSub.broadcast("todo:updates", {
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
}