package server.live;

import HXX; // Import HXX for template rendering
import ecto.Changeset; // Import Ecto Changeset from the correct location
import ecto.Query; // Import Ecto Query from the correct location
import elixir.types.Term;
import haxe.Constraints.Function;
	import elixir.Atom;
	import elixir.ElixirMap;
	import elixir.Task; // Background work via Task.start
	import elixir.List;
			import elixir.DateTime.NaiveDateTime;
			import elixir.Enum;
			import haxe.functional.Result; // Import Result type properly
	import phoenix.LiveSocket; // Type-safe socket wrapper
	import phoenix.Component;
	import phoenix.types.Assigns;
	import phoenix.types.Flash.FlashType;
	import phoenix.PhoenixFlash;
	import phoenix.Phoenix.HandleEventResult;
	import phoenix.Phoenix.HandleInfoResult;
	import phoenix.Phoenix.LiveView; // Use the comprehensive Phoenix module version
	import phoenix.Phoenix.MountResult;
	import phoenix.Phoenix.Socket;
	import phoenix.Presence; // Import Presence module for PresenceEntry typedef
	import server.infrastructure.Repo; // Import the TodoApp.Repo module
	import server.live.SafeAssigns;
import server.live.TodoLiveTypes.TodoLiveAssigns;
import server.live.TodoLiveTypes.TodoLiveRenderAssigns;
import server.live.TodoLiveTypes.TodoLiveEvent;
import server.live.TodoLiveTypes.TodoView;
import server.live.TodoLiveTypes.TagView;
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
	import server.types.Types.AlertLevel;
	import StringTools;
	using reflaxe.elixir.macros.TypedQueryLambda;

/**
 * LiveView component for todo management with real-time updates
 */
	@:native("TodoAppWeb.TodoLive")
	@:liveview
	class TodoLive {
	    // Prevent DCE from stripping private helpers used by LiveView callbacks.
	    @:keep private static var __keep_fns:Array<Function> = [
	        create_todo,
	        toggle_todo_status,
	        delete_todo,
	        update_todo_priority,
	        start_editing,
        save_edited_todo_typed,
        complete_all_todos,
        delete_completed_todos,
        extract_id,
        findTodo,
        parseTags
    ];
	// All socket state is now defined in TodoLiveAssigns typedef for type safety
	
	/**
	 * Mount callback with type-safe assigns
	 * 
	 * The TAssigns type parameter will be inferred as TodoLiveAssigns from the socket parameter.
	 */
		    public static function mount(_params: MountParams, session: Session, socket: phoenix.Phoenix.Socket<TodoLiveAssigns>): MountResult<TodoLiveAssigns> {
		        // Prepare LiveSocket wrapper
		        var sock: LiveSocket<TodoLiveAssigns> = socket;

	        var currentUser = getUserFromSession(session);
		        var todos = loadTodos(currentUser.id);

				        // Subscribe only on the connected mount (the initial static render is disconnected).
				        // This enables cross-session real-time updates via Phoenix.PubSub.
				        if (socket.transport_pid != null) {
				            TodoPubSub.subscribe(TodoUpdates);
				        }

	        var assigns: TodoLiveAssigns = {
	            todos: todos,
	            filter: shared.TodoTypes.TodoFilter.All,
	            sort_by: shared.TodoTypes.TodoSort.Created,
	            current_user: currentUser,
	            editing_todo: null,
	            show_form: false,
	            search_query: "",
	            selected_tags: [],
	            available_tags: computeAvailableTags(todos, []),
	            optimistic_toggle_ids: [],
	            visible_todos: [],
	            visible_count: 0,
	            filter_btn_all_class: filterBtnClass(shared.TodoTypes.TodoFilter.All, shared.TodoTypes.TodoFilter.All),
            filter_btn_active_class: filterBtnClass(shared.TodoTypes.TodoFilter.All, shared.TodoTypes.TodoFilter.Active),
            filter_btn_completed_class: filterBtnClass(shared.TodoTypes.TodoFilter.All, shared.TodoTypes.TodoFilter.Completed),
            sort_selected_created: sortSelected(shared.TodoTypes.TodoSort.Created, shared.TodoTypes.TodoSort.Created),
            sort_selected_priority: sortSelected(shared.TodoTypes.TodoSort.Created, shared.TodoTypes.TodoSort.Priority),
            sort_selected_due_date: sortSelected(shared.TodoTypes.TodoSort.Created, shared.TodoTypes.TodoSort.DueDate),
            total_todos: todos.length,
            completed_todos: countCompleted(todos),
            pending_todos: countPending(todos),
            online_users: new Map()
        };

        sock = LiveView.assignMultiple(sock, assigns);
        var ls: LiveSocket<TodoLiveAssigns> = recomputeVisible(sock);
        return Ok(ls);
    }
	
	/**
	 * Handle events with fully typed event system.
	 * 
	 * No more string matching or raw params!
	 * Each event carries its own typed parameters.
	 */
	    @:keep
	    @:native("handle_event")
		    public static function handle_event(event: String, params: Term, socket: Socket<TodoLiveAssigns>): HandleEventResult<TodoLiveAssigns> {
		        var nextSocket: Socket<TodoLiveAssigns> =
		            if (event == "create_todo") {
		                create_todo(params, socket);
		            } else if (event == "toggle_todo") {
		                toggle_todo_status(extract_id(params), socket);
		            } else if (event == "delete_todo") {
		                delete_todo(extract_id(params), socket);
		            } else if (event == "edit_todo") {
	                start_editing(extract_id(params), socket);
	            } else if (event == "save_todo") {
	                save_edited_todo_typed(params, socket);
	            } else if (event == "cancel_edit") {
	                recomputeVisible(SafeAssigns.setEditingTodo(socket, null));
	            } else if (event == "filter_todos") {
	                var filterValue: Null<String> = cast Reflect.field(params, "filter");
	                recomputeVisible(SafeAssigns.setFilter(socket, filterValue != null ? filterValue : "all"));
	            } else if (event == "sort_todos") {
	                var sortBy: Null<String> = cast Reflect.field(params, "sort_by");
	                recomputeVisible(SafeAssigns.setSortByAndResort(socket, sortBy != null ? sortBy : "created"));
			            } else if (event == "search_todos") {
			                var query: Null<String> = cast Reflect.field(params, "query");
			                var withQuery = SafeAssigns.setSearchQuery(socket, query != null ? query : "");
			                // Ensure tag-selection state composes with search changes.
			                recomputeVisible(SafeAssigns.setSelectedTags(withQuery, socket.assigns.selected_tags));
		            } else if (event == "toggle_tag") {
		                var tagValue: Null<String> = Reflect.field(params, "tag");
		                if (tagValue == null) {
		                    socket;
		                } else {
			                    var tag: String = tagValue;
			                    var current = socket.assigns.selected_tags;
			                    var updated = if (current.contains(tag)) {
			                        current.filter(function(t) return t != tag);
			                    } else {
			                        List.insertAt(current, 0, tag);
			                    };
			                    recomputeVisible(SafeAssigns.setSelectedTags(socket, updated));
			                }
		            } else if (event == "set_priority") {
	                var priority: Null<String> = cast Reflect.field(params, "priority");
	                update_todo_priority(extract_id(params), priority != null ? priority : "medium", socket);
	            } else if (event == "toggle_form") {
	                recomputeVisible(SafeAssigns.setShowForm(socket, !socket.assigns.show_form));
	            } else if (event == "bulk_complete") {
	                complete_all_todos(socket);
	            } else if (event == "bulk_delete_completed") {
	                delete_completed_todos(socket);
	            } else {
	                socket;
	            };
	
	        return NoReply(nextSocket);
	    }

    @:keep
    public static function extract_id(params: Term): Int {
        var direct: Term = Reflect.field(params, "id");
        var todoObj: Term = Reflect.field(params, "todo");
        var todoId: Term = (todoObj != null) ? Reflect.field(todoObj, "id") : null;
        var candidate: Term = (direct != null) ? direct : todoId;

        if (candidate == null) return 0;
        if (elixir.Kernel.isInteger(candidate)) return cast candidate;
        else if (elixir.Kernel.isFloat(candidate)) return elixir.Kernel.trunc(candidate);
        else if (elixir.Kernel.isBinary(candidate)) {
            var parsed = Std.parseInt(cast candidate);
            return parsed != null ? parsed : 0;
        } else {
            return 0;
        }
    }
	
    /**
     * Handle real-time updates from other users with type-safe assigns
     * 
     * The TAssigns type parameter will be inferred as TodoLiveAssigns from the socket parameter.
     */
	    @:keep
	    public static function handleInfo(msg: TodoPubSubMessage, socket: Socket<TodoLiveAssigns>): HandleInfoResult<TodoLiveAssigns> {
	        var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
	        return handlePubSub(msg, liveSocket);
	    }

    @:keep
    static function handlePubSub(payload: TodoPubSubMessage, socket: LiveSocket<TodoLiveAssigns>): HandleInfoResult<TodoLiveAssigns> {
        return switch (payload) {
            case TodoCreated(todo):
                var merged = socket.merge({
                    todos: [todo].concat(socket.assigns.todos),
                    total_todos: socket.assigns.total_todos + 1,
                    pending_todos: socket.assigns.pending_todos + (todo.completed ? 0 : 1),
                    completed_todos: socket.assigns.completed_todos + (todo.completed ? 1 : 0)
                });
                NoReply(recomputeVisible(merged));
            case TodoUpdated(todo):
                var clearedIds = socket.assigns.optimistic_toggle_ids.filter(function(x) return x != todo.id);
                var cleared = socket.assign(_.optimistic_toggle_ids, clearedIds);
                NoReply(recomputeVisible(updateTodoInList(todo, cleared)));
            case TodoDeleted(id):
                NoReply(recomputeVisible(removeTodoFromList(id, socket)));
            case BulkUpdate(action):
                switch (action) {
                    case CompleteAll, DeleteCompleted:
                        var refreshed = loadTodos(socket.assigns.current_user.id);
                        var merged = socket.merge({
                            todos: refreshed,
                            total_todos: refreshed.length,
                            completed_todos: countCompleted(refreshed),
                            pending_todos: countPending(refreshed)
                        });
                        NoReply(recomputeVisible(merged));
                    case _:
                        NoReply(socket);
                }
            case UserOnline(_):
                NoReply(socket);
            case UserOffline(_):
                NoReply(socket);
            case _:
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
			dueDate: params.dueDate != null ? parseDueDate(params.dueDate) : null,
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
				
			case Error(_):
					return LiveView.putFlash(socket, FlashType.Error, "Failed to create todo");
		}
	}

	    /**
	     * Create a new todo using typed TodoParams.
	     */
	    @:keep
	    public static function create_todo(params: Term, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
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
        var dueDate = parseDueDate(rawDue);

        // Build the todo struct for changeset
        var todoStruct = new server.schemas.Todo();
        var castParams: server.schemas.Todo.TodoChangesetParams = {
            title: title,
            description: description,
            completed: false,
            priority: priority,
            dueDate: dueDate,
            tags: tagsArr,
            userId: socket.assigns.current_user.id
        };
        // Use the schema-generated changeset to keep casting/validation idiomatic
        var cs = Todo.changeset(todoStruct, castParams);
        switch (Repo.insert(cs)) {
	            case Ok(value):
	                // broadcast best-effort; ignore returned term
	                var _broadcastResult = TodoPubSub.broadcast(TodoUpdates, TodoCreated(value));
	                var todos = [value].concat(socket.assigns.todos);
	                var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
	                var updatedSocket: LiveSocket<TodoLiveAssigns> = liveSocket.merge({
	                    todos: todos,
	                    show_form: false,
	                    total_todos: socket.assigns.total_todos + 1,
	                    pending_todos: socket.assigns.pending_todos + (value.completed ? 0 : 1),
	                    completed_todos: socket.assigns.completed_todos + (value.completed ? 1 : 0)
	                });
                var lsCreated: LiveSocket<TodoLiveAssigns> = recomputeVisible(updatedSocket);
                return LiveView.putFlash(lsCreated, FlashType.Success, "Todo created successfully!");
            case Error(_):
                return LiveView.putFlash(socket, FlashType.Error, "Failed to create todo");
            case _:
                return LiveView.putFlash(socket, FlashType.Error, "Failed to create todo");
        }
    }

/**
 * toggleTodoStatus
 *
 * WHAT
 * - Server-driven optimistic toggle with safe reconciliation.
 *
 * WHY
 * - Provide immediate user feedback while keeping LiveView authoritative.
 *
 * HOW
 * - Mark id as optimistic → flip local row → persist (Repo.update) → broadcast TodoUpdated.
 *   handle_info updates the list with the authoritative record; on error we broadcast the
 *   current DB row to revert.
 */
	    @:keep
	    public static function toggle_todo_status(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
	        var s: LiveSocket<TodoLiveAssigns> = socket;
	        var toggledTodos = s.assigns.todos.map(function(todo) {
	            if (todo.id == id) {
	                return cast ElixirMap.put(todo, Atom.create("completed"), !todo.completed);
	            }
            return todo;
        });

        var sOptimistic = recomputeVisible(s.merge({
            optimistic_toggle_ids: [],
            todos: toggledTodos,
            completed_todos: countCompleted(toggledTodos),
            pending_todos: countPending(toggledTodos)
        }));

        var db = Repo.get(server.schemas.Todo, id);
        if (db == null) {
            return sOptimistic;
        }

        switch (Repo.update(server.schemas.Todo.toggleCompleted(db))) {
            case Ok(_):
                var refreshed = Repo.get(server.schemas.Todo, id);
                var finalTodo = (refreshed != null) ? refreshed : db;
                var withTodo = updateTodoInList(finalTodo, sOptimistic);
                var _ = TodoPubSub.broadcast(TodoUpdates, TodoUpdated(finalTodo));
                return recomputeVisible(withTodo);
            case _:
                var _ = TodoPubSub.broadcast(TodoUpdates, TodoUpdated(db));
                return LiveView.putFlash(sOptimistic, FlashType.Error, "Failed to toggle todo");
        }
    }

// Background reconcile for optimistic toggle
// Handle in-process persistence request in handleInfo
	
    @:keep
    public static function delete_todo(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        var todo = findTodo(id, socket.assigns.todos);
        if (todo == null) return socket;
        
        // Perform delete. On error, show flash and exit; otherwise proceed.
        switch (Repo.delete(todo)) {
            case Ok(_):
                // continue
            case _:
                return LiveView.putFlash(socket, FlashType.Error, "Failed to delete todo");
        }
        // Reflect locally, then broadcast best-effort to others
        var updated = removeTodoFromList(id, socket);
        var _ = TodoPubSub.broadcast(TodoUpdates, TodoDeleted(id));
        return recomputeVisible(updated);
    }
	
    @:keep
    public static function update_todo_priority(id: Int, priority: String, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        var todo = findTodo(id, socket.assigns.todos);
        if (todo == null) return socket;
        switch (Repo.update(server.schemas.Todo.updatePriority(todo, priority))) {
            case Ok(_):
                // proceed to refresh below
            case _:
                return LiveView.putFlash(socket, FlashType.Error, "Failed to update priority");
        }
        var refreshed = Repo.get(server.schemas.Todo, id);
        if (refreshed != null) {
            var _ = TodoPubSub.broadcast(TodoUpdates, TodoUpdated(refreshed));
            return recomputeVisible(updateTodoInList(refreshed, socket));
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
        var query = ecto.TypedQuery.from(server.schemas.Todo).where(t -> t.userId == userId);
        return Repo.all(query);
    }

    @:keep
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
	
    @:keep @:native("parse_tags")
    static function parseTags(tagsString: String): Array<String> {
        return server.support.TagTools.parseTags(tagsString);
    }

    static inline function parseDueDate(rawDue: Null<String>): Null<NaiveDateTime> {
        if (rawDue == null || rawDue == "") return null;
        var iso = (rawDue.indexOf(":") == -1) ? (rawDue + " 00:00:00") : rawDue;
        return switch (NaiveDateTime.from_iso8601(iso)) {
            case Ok(dt): dt;
            case Error(_): null;
        };
    }
	
    static function getUserFromSession(session: Session): User {
        var uid: Int = switch (session) {
            case null: 1;
            case _:
                var sessionTerm: Term = cast session;
                var primary: Term = elixir.ElixirMap.get(sessionTerm, "user_id");
                var chosen: Term = primary != null ? primary : elixir.ElixirMap.get(sessionTerm, "userId");
                chosen != null ? cast chosen : 1;
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
        var updated = socket.merge({
            todos: newTodos,
            total_todos: newTodos.length,
            completed_todos: countCompleted(newTodos),
            pending_todos: countPending(newTodos)
        });
        return updated;
    }

    static function buildTodoRow(todoItem: server.schemas.Todo, forceCompletedView: Bool, editing: Null<server.schemas.Todo>, selectedTags: Array<String>): TodoView {
        var completedFlag: Bool = if (forceCompletedView) {
            true;
        } else {
            todoItem.completed;
        }
        var lineThrough = completedFlag ? " line-through" : "";
        var border = borderForPriority(todoItem.priority);
        var containerClass = "bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 "
            + border
            + (completedFlag ? " opacity-60" : "")
            + " transition-all hover:shadow-xl";
        var hasDue = (todoItem.dueDate != null);
        var dueDisplay = hasDue ? format_due_date(todoItem.dueDate) : "";
        var tagViews = buildTagViews((todoItem.tags != null ? todoItem.tags : []), selectedTags);
        var hasTags = tagViews.length > 0;
        var hasDescription = (todoItem.description != null && todoItem.description != "");
        var isEditing = (editing != null && editing.id == todoItem.id);
        return {
            id: todoItem.id,
            title: todoItem.title,
            description: todoItem.description,
            completed_for_view: completedFlag,
            completed_str: completedFlag ? "true" : "false",
            dom_id: "todo-" + Std.string(todoItem.id),
            container_class: containerClass,
            title_class: "text-lg font-semibold text-gray-800 dark:text-white" + lineThrough,
            desc_class: "text-gray-600 dark:text-gray-400 mt-1" + lineThrough,
            priority: todoItem.priority,
            has_due: hasDue,
            due_display: dueDisplay,
            has_tags: hasTags,
            has_description: hasDescription,
            is_editing: isEditing,
            tags: tagViews
        };
    }

    /**
     * Build typed view rows for zero-logic HXX rendering.
     */
    static function buildVisibleTodos(assigns: TodoLiveAssigns): Array<TodoView> {
        var base = filterAndSortTodos(assigns.todos, assigns.filter, assigns.sort_by, assigns.search_query, assigns.selected_tags);
        var forceCompletedView = (assigns.filter == shared.TodoTypes.TodoFilter.Completed) && countCompleted(assigns.todos) == 0;
        var currentEdit = assigns.editing_todo;
        var selectedTags = assigns.selected_tags;
        var rows = elixir.Enum.map(base, function(rowSource: server.schemas.Todo): TodoView {
            return buildTodoRow(rowSource, forceCompletedView, currentEdit, selectedTags);
        });
        return rows;
    }

    /**
     * Recompute and merge visible_todos into assigns; returns a typed LiveSocket.
     */
	    static function recomputeVisible(socket: Socket<TodoLiveAssigns>): LiveSocket<TodoLiveAssigns> {
	        var ls: LiveSocket<TodoLiveAssigns> = socket;
	        var rows = buildVisibleTodos(ls.assigns);
	        // Precompute UI helpers
	        var selected = ls.assigns.sort_by;
	        var filter = ls.assigns.filter;
	        var merged = ls.merge({
	            visible_todos: rows,
	            visible_count: rows.length,
	            available_tags: computeAvailableTags(ls.assigns.todos, ls.assigns.selected_tags),
	            filter_btn_all_class: filterBtnClass(filter, shared.TodoTypes.TodoFilter.All),
	            filter_btn_active_class: filterBtnClass(filter, shared.TodoTypes.TodoFilter.Active),
	            filter_btn_completed_class: filterBtnClass(filter, shared.TodoTypes.TodoFilter.Completed),
	            sort_selected_created: sortSelected(selected, shared.TodoTypes.TodoSort.Created),
            sort_selected_priority: sortSelected(selected, shared.TodoTypes.TodoSort.Priority),
            sort_selected_due_date: sortSelected(selected, shared.TodoTypes.TodoSort.DueDate)
        });
        return merged;
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
	
    @:keep
    public static function start_editing(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        // Update presence to show user is editing (idiomatic Phoenix pattern)
        // Must call recomputeVisible to update visible_todos with is_editing flag
        return recomputeVisible(SafeAssigns.setEditingTodo(socket, findTodo(id, socket.assigns.todos)));
    }
	
	// Bulk operations with type-safe socket handling
    @:keep
    public static function complete_all_todos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        elixir.Enum.each(socket.assigns.todos, function(item) {
            if (!item.completed) {
                var cs = server.schemas.Todo.toggleCompleted(item);
                Repo.update(cs);
            }
        });
        // Broadcast (best-effort)
        var _ = TodoPubSub.broadcast(TodoUpdates, BulkUpdate(CompleteAll));
        // Reload todos and update assigns
        var refreshedTodos = loadTodos(socket.assigns.current_user.id);
        var updated = recomputeVisible(SafeAssigns.updateTodosAndStats(socket, refreshedTodos));
        updated = LiveView.clearFlash(updated);
        return LiveView.putFlash(
            updated,
            FlashType.Info,
            "All todos marked as completed!"
        );
    }

    @:keep
    public static function delete_completed_todos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        elixir.Enum.each(socket.assigns.todos, function(item) {
            if (item.completed) Repo.delete(item);
        });
        // Notify others (best-effort)
        var _ = TodoPubSub.broadcast(TodoUpdates, BulkUpdate(DeleteCompleted));
        // Reload fresh todos from DB and update assigns
        var remaining = loadTodos(socket.assigns.current_user.id);
        var updated = recomputeVisible(SafeAssigns.updateTodosAndStats(socket, remaining));
        updated = LiveView.clearFlash(updated);
        return LiveView.putFlash(
            updated,
            FlashType.Info,
            "Completed todos deleted!"
        );
    }
	
	// Additional helper functions with type-safe socket handling
	static function startEditingOld(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = findTodo(id, socket.assigns.todos);
		return SafeAssigns.setEditingTodo(socket, todo);
	}
	
    /**
     * Save edited todo with typed parameters.
     */
    @:keep
    public static function save_edited_todo_typed(params: Term, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        if (socket.assigns.editing_todo == null) return socket;
        var todo = socket.assigns.editing_todo;
        // LiveView form params arrive as a map with string keys; extract safely.
        var rawTitle: Null<String> = Reflect.field(params, "title");
        var rawDesc: Null<String> = Reflect.field(params, "description");
        var rawPriority: Null<String> = Reflect.field(params, "priority");
        var rawDue: Null<String> = Reflect.field(params, "due_date");
        var rawTags: Null<String> = Reflect.field(params, "tags");

        // Inline computed fields into changeset map to avoid local-binder rename mismatches
	        switch (Repo.update(server.schemas.Todo.changeset(todo, {
	            title: (rawTitle != null) ? rawTitle : todo.title,
	            description: (rawDesc != null) ? rawDesc : (todo.description != null ? todo.description : ""),
	            priority: (rawPriority != null && rawPriority != "") ? rawPriority : todo.priority,
            dueDate: (rawDue != null) ? parseDueDate(rawDue) : todo.dueDate,
            tags: (rawTags != null) ? (rawTags != "" ? parseTags(rawTags) : []) : (todo.tags != null ? todo.tags : []),
            completed: todo.completed,
            userId: todo.userId
        }))) {
	            case Ok(value):
	                // Best-effort broadcast
	                TodoPubSub.broadcast(TodoUpdates, TodoUpdated(value));
	                var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
	                var ls: LiveSocket<TodoLiveAssigns> = updateTodoInList(value, liveSocket);
	                ls = ls.assign(_.editing_todo, null);
	                ls = recomputeVisible(ls);
	                return ls;
            case _:
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

    static inline function format_due_date(d: Null<NaiveDateTime>): String {
        if (d == null) return "";
        var iso = d.to_iso8601();
        return iso.substr(0, 10);
    }
    static inline function encodeSort(s: shared.TodoTypes.TodoSort): String {
        return switch (s) { case Created: "created"; case Priority: "priority"; case DueDate: "due_date"; };
    }
    static inline function encodeFilter(f: shared.TodoTypes.TodoFilter): String {
        return switch (f) { case All: "all"; case Active: "active"; case Completed: "completed"; };
    }
    static inline function priorityRankForSort(priority: String): Int {
        return switch (priority) {
            case "low": 0;
            case "medium": 1;
            case "high": 2;
            case _: 3;
        };
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
			dueDate: params.dueDate != null ? parseDueDate(params.dueDate) : null,
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
	                // Reload todos once and apply in a single merge
	                var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
	                var refreshed = loadTodos(socket.assigns.current_user.id);
	                liveSocket.merge({
	                    todos: refreshed,
	                    total_todos: refreshed.length,
	                    completed_todos: countCompleted(refreshed),
	                    pending_todos: countPending(refreshed)
	                });
	            
	            case DeleteCompleted:
	                var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
	                var refreshed = loadTodos(socket.assigns.current_user.id);
	                liveSocket.merge({
	                    todos: refreshed,
	                    total_todos: refreshed.length,
	                    completed_todos: countCompleted(refreshed),
	                    pending_todos: countPending(refreshed)
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
    @:keep public static function render(assigns: TodoLiveRenderAssigns): String {
        // Phoenix warns when templates access locals defined outside ~H (it disables change tracking).
        // Compute derived flash strings into tracked assigns, then reference @flash_info/@flash_error in HEEx.
        var renderAssigns: Assigns<TodoLiveRenderAssigns> = assigns;
        renderAssigns = Component.assign(renderAssigns, "flash_info", PhoenixFlash.get(assigns.flash, "info"));
        renderAssigns = Component.assign(renderAssigns, "flash_error", PhoenixFlash.get(assigns.flash, "error"));
        assigns = renderAssigns;

        return HXX.hxx('
			<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
				<div id="root" class="container mx-auto px-4 py-8 max-w-6xl" phx-hook="Ping">
					<!-- Flash messages (info/error) -->
						<if {assigns.flash_info}>
							<div data-testid="flash-info" class="bg-blue-50 border border-blue-200 text-blue-700 px-4 py-3 rounded-lg mb-6">
								${assigns.flash_info}
							</div>
						</if>
						<if {assigns.flash_error}>
							<div data-testid="flash-error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-6">
								${assigns.flash_error}
							</div>
						</if>
					
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
									<input type="search" name="query" value=${assigns.search_query} phx-debounce="300"
										class="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="Search todos..." />
									<span class="absolute left-3 top-2.5 text-gray-400">🔍</span>
								</form>
							</div>
							
	                        <!-- Filter Buttons -->
	                        <div class="flex space-x-2">
	                            <button type="button" phx-click="filter_todos" phx-value-filter="all" data-testid="btn-filter-all"
	                                class=${assigns.filter_btn_all_class}>All</button>
	                            <button type="button" phx-click="filter_todos" phx-value-filter="active" data-testid="btn-filter-active"
	                                class=${assigns.filter_btn_active_class}>Active</button>
	                            <button type="button" phx-click="filter_todos" phx-value-filter="completed" data-testid="btn-filter-completed"
	                                class=${assigns.filter_btn_completed_class}>Completed</button>
	                        </div>
	                        <div class="flex flex-wrap gap-2" data-testid="available-tags">
	                            <for {tagView in assigns.available_tags}>
	                                <button type="button" phx-click="toggle_tag" phx-value-tag=#{tagView.tag} data-testid="tag-chip" data-tag=#{tagView.tag}
	                                    class=#{tagView.chip_class}>
	                                    #{tagView.tag}
	                                </button>
	                            </for>
							</div>
							
							<!-- Sort Dropdown -->
							<div>
                            <form phx-change="sort_todos">
                                <select name="sort_by"
                                    class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
                                    <option value="created" selected=${assigns.sort_selected_created}>Sort by Date</option>
                                    <option value="priority" selected=${assigns.sort_selected_priority}>Sort by Priority</option>
                                    <option value="due_date" selected=${assigns.sort_selected_due_date}>Sort by Due Date</option>
                                </select>
                            </form>
							</div>
						</div>
					</div>
					
					<!-- Online Users Panel -->
                    <!-- Presence panel (optional) -->
					
					<!-- Bulk Actions -->
                    <!-- Bulk Actions (typed HXX) -->
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 mb-6 flex justify-between items-center">
                        <div class="text-sm text-gray-600 dark:text-gray-400">
                            Showing ${assigns.visible_count} of ${assigns.total_todos} todos
                        </div>
                        <div class="flex space-x-2">
                            <button type="button" phx-click="bulk_complete"
                                class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors text-sm">✅ Complete All</button>
                            <button type="button" phx-click="bulk_delete_completed" data-confirm="Are you sure you want to delete all completed todos?"
                                class="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm">🗑️ Delete Completed</button>
                        </div>
                    </div>
					
					<!-- Todo List -->
                    <div id="todo-list" class="space-y-4">
                        <for {v in assigns.visible_todos}>
                            <if {v.is_editing}>
                                <div id=#{v.dom_id} data-testid="todo-card" data-completed=#{v.completed_str}
                                    class=#{v.container_class}>
                                    <form phx-submit="save_todo" class="space-y-4">
                                        <input type="text" name="title" value=#{v.title} required data-testid="input-title"
                                            class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
                                        <textarea name="description" rows="2"
                                            class="w-full px-4 py-2 border border-gray-300 dark-border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">#{v.description}</textarea>
                                        <div class="flex space-x-2">
                                            <button type="submit" class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600">Save</button>
                                            <button type="button" phx-click="cancel_edit" class="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400">Cancel</button>
                                        </div>
                                    </form>
                                </div>
                            <else>
                                <div id=#{v.dom_id} data-testid="todo-card" data-completed=#{v.completed_str}
                                    class=#{v.container_class}>
                                    <div class="flex items-start space-x-4">
                                        <!-- Checkbox -->
                                        <button type="button" phx-click="toggle_todo" phx-value-id=#{v.id} data-testid="btn-toggle-todo"
                                            class="mt-1 w-6 h-6 rounded border-2 border-gray-300 dark:border-gray-600 flex items-center justify-center hover:border-blue-500 transition-colors">
                                            <if {v.completed_for_view}>
                                                <span class="text-green-500">✓</span>
                                            </if>
                                        </button>

                                        <!-- Content -->
                                        <div class="flex-1">
                                            <h3 class=#{v.title_class}>
                                                #{v.title}
                                            </h3>
                                            <if {v.has_description}>
                                                <p class=#{v.desc_class}>
                                                    #{v.description}
                                                </p>
                                            </if>

                                            <!-- Meta info -->
                                            <div class="flex flex-wrap gap-2 mt-3">
                                                <span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">
                                                    Priority: #{v.priority}
                                                </span>
                                                <if {v.has_due}>
                                                    <span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">
                                                        Due: #{v.due_display}
                                                    </span>
	                                                </if>
	                                                <if {v.has_tags}>
	                                                    <for {tagView in v.tags}>
	                                                        <button type="button" phx-click="toggle_tag" phx-value-tag=#{tagView.tag} data-testid="todo-tag" data-tag=#{tagView.tag}
	                                                            class=#{tagView.chip_class}>
	                                                            #{tagView.tag}
	                                                        </button>
	                                                    </for>
	                                                </if>
	                                            </div>
                                        </div>

                                        <!-- Actions -->
                                        <div class="flex space-x-2">
                                            <button type="button" phx-click="edit_todo" phx-value-id=#{v.id} data-testid="btn-edit-todo"
                                                class="p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition-colors">✏️</button>
                                            <button type="button" phx-click="delete_todo" phx-value-id=#{v.id} data-testid="btn-delete-todo"
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
	
    public static function renderBulkActions(assigns: TodoLiveAssigns): String {
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
     * Helper to filter todos based on filter and search query
     * Pure Haxe implementation (no raw Elixir injection).
        */
	    static function filterTodos(todos: Array<server.schemas.Todo>, filter: shared.TodoTypes.TodoFilter, searchQuery: String): Array<server.schemas.Todo> {
	        inline function lower(s:String):String {
	            return s.toLowerCase();
	        }
	        var base = switch (filter) {
	            case shared.TodoTypes.TodoFilter.Active: todos.filter(function(t) return !t.completed);
	            case shared.TodoTypes.TodoFilter.Completed: todos.filter(function(t) return t.completed);
	            case shared.TodoTypes.TodoFilter.All: todos;
	        };

	        var result = if (searchQuery == null || searchQuery == "") {
	            base;
	        } else {
	            var ql = lower(searchQuery);
	            base.filter(function(t) {
	                var title = (t.title != null) ? lower(t.title) : "";
	                var desc = (t.description != null) ? lower(t.description) : "";
	                var matchesTag = (t.tags != null) && Enum.any(t.tags, function(tag) {
	                    if (tag == null) return false;
	                    var normalized = lower(tag);
	                    return normalized != "" && normalized.indexOf(ql) != -1;
	                });
	                return title.indexOf(ql) != -1 || desc.indexOf(ql) != -1 || matchesTag;
	            });
	        }
	        return result;
	    }

	    static inline function tagChipClass(selected: Bool): String {
	        var base = "px-2 py-1 rounded text-xs transition-colors ";
	        return base + (selected
	            ? "bg-blue-500 text-white hover:bg-blue-600"
	            : "bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400 hover:bg-blue-200");
	    }

	    static function buildTagViews(tagValues: Array<String>, selectedTags: Array<String>): Array<TagView> {
	        if (tagValues == null || tagValues.length == 0) return [];

	        var trimmedValues = Enum.map(
	            Enum.filter(tagValues, function(tag) return tag != null && StringTools.trim(tag) != ""),
	            function(tag) return StringTools.trim(tag)
	        );

	        return Enum.map(trimmedValues, function(tag): TagView {
	            var selected = selectedTags != null && selectedTags.contains(tag);
	            return {
	                tag: tag,
	                selected: selected,
	                chip_class: tagChipClass(selected)
	            };
	        });
	    }

	    static function computeAvailableTags(todos: Array<server.schemas.Todo>, selectedTags: Array<String>): Array<TagView> {
	        // Use Enum.flat_map + Enum.uniq + Enum.sort to generate idiomatic Elixir and
	        // avoid nested-loop binder hygiene issues in generated code.
	        var allTags = Enum.flatMap(todos, function(todo) {
	            return (todo.tags != null)
	                ? Enum.map(
	                    Enum.filter(todo.tags, function(tag) {
	                        return tag != null && StringTools.trim(tag) != "";
	                    }),
	                    function(tag) return StringTools.trim(tag)
	                )
	                : [];
	        });

	        return buildTagViews(Enum.sort(Enum.uniq(allTags)), selectedTags);
	    }
	
    /**
     * Helper to filter and sort todos
     *
     * NOTE: This is intentionally implemented in pure Haxe (no `__elixir__()` in apps).
     * We rely on faithful Enum externs so the compiler emits idiomatic Elixir.
     */
    public static function filterAndSortTodos(todos: Array<server.schemas.Todo>, filter: shared.TodoTypes.TodoFilter, sortBy: shared.TodoTypes.TodoSort, searchQuery: String, selectedTags: Array<String>): Array<server.schemas.Todo> {
        // First, filter the todos in Haxe
        var filtered = filterTodos(todos, filter, searchQuery);
        // Then apply tag filtering if needed
        if (selectedTags != null && selectedTags.length > 0) {
            filtered = filtered.filter(function(t) {
                var tags = (t.tags != null) ? t.tags : [];
                return Enum.any(selectedTags, function(sel) return tags.indexOf(sel) != -1);
            });
        }

        // Use Enum.sort_by (via ElixirEnum) with lexicographic list keys.
        // Arrays compile to Elixir lists and are comparable under term ordering.
        return switch (sortBy) {
            case Priority:
                Enum.sortBy(filtered, function(t) return (cast ([priorityRankForSort(t.priority), -t.id] : Array<Term>)));
            case DueDate:
                Enum.sortBy(filtered, function(t) return (cast ([elixir.Kernel.isNil(t.dueDate), t.dueDate, -t.id] : Array<Term>)));
            case Created:
                // Newest first (stable): use id desc as a proxy for creation order.
                Enum.sortBy(filtered, function(t) return (cast ([-t.id] : Array<Term>)));
        };
    }
}
