defmodule TodoAppWeb.TodoLive do
  use Phoenix.LiveView
  
  import Phoenix.LiveView.Helpers
  import Ecto.Query
  alias TodoApp.Repo
  
  use Phoenix.Component
  import TodoAppWeb.CoreComponents
  
  @impl true
  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    _g = TodoPubSub.subscribe(:todo_updates)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        {:error, "Failed to subscribe to updates: " <> reason}
    end
    current_user = TodoLive.get_user_from_session(session)
    todos = TodoLive.load_todos(current_user.id)
    assigns = %{"todos" => todos, "filter" => "all", "sort_by" => "created", "current_user" => current_user, "editing_todo" => nil, "show_form" => false, "search_query" => "", "selected_tags" => [], "total_todos" => length(todos), "completed_todos" => TodoLive.count_completed(todos), "pending_todos" => TodoLive.count_pending(todos)}
    updated_socket = LiveView.assign_multiple(socket, assigns)
    {:ok, updated_socket}
  end

  @impl true
  @doc "Generated from Haxe handle_event"
  def handle_event(event, params, socket) do
    temp_socket = nil
    case (event) do
      "bulk_complete" ->
        temp_socket = TodoLive.complete_all_todos(socket)
      "bulk_delete_completed" ->
        temp_socket = TodoLive.delete_completed_todos(socket)
      "cancel_edit" ->
        temp_socket = SafeAssigns.setEditingTodo(socket, nil)
      "create_todo" ->
        temp_socket = TodoLive.create_new_todo(params, socket)
      "delete_todo" ->
        temp_socket = TodoLive.delete_todo(params.id, socket)
      "edit_todo" ->
        temp_socket = TodoLive.start_editing(params.id, socket)
      "filter_todos" ->
        temp_socket = SafeAssigns.setFilter(socket, params.filter)
      "save_todo" ->
        temp_socket = TodoLive.save_edited_todo(params, socket)
      "search_todos" ->
        temp_socket = SafeAssigns.setSearchQuery(socket, params.query)
      "set_priority" ->
        temp_socket = TodoLive.update_todo_priority(params.id, params.priority, socket)
      "sort_todos" ->
        temp_socket = SafeAssigns.setSortBy(socket, params.sort_by)
      "toggle_form" ->
        temp_socket = SafeAssigns.setShowForm(socket, !socket.assigns.show_form)
      "toggle_tag" ->
        temp_socket = TodoLive.toggle_tag_filter(params.tag, socket)
      "toggle_todo" ->
        temp_socket = TodoLive.toggle_todo_status(params.id, socket)
      _ ->
        temp_socket = socket
    end
    {:no_reply, temp_socket}
  end

  @impl true
  @doc "Generated from Haxe handle_info"
  def handle_info(msg, socket) do
    temp_socket = nil
    _g = TodoPubSub.parseMessage(msg)
    case (case _g do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; :error -> nil; _ -> nil end
        parsed_msg = _g
        case (elem(parsed_msg, 0)) do
          0 ->
            _g = elem(parsed_msg, 1)
            todo = _g
            temp_socket = TodoLive.add_todo_to_list(todo, socket)
          1 ->
            _g = elem(parsed_msg, 1)
            todo = _g
            temp_socket = TodoLive.update_todo_in_list(todo, socket)
          2 ->
            _g = elem(parsed_msg, 1)
            id = _g
            temp_socket = TodoLive.remove_todo_from_list(id, socket)
          3 ->
            _g = elem(parsed_msg, 1)
            action = _g
            temp_socket = TodoLive.handle_bulk_update(action, socket)
          4 ->
            elem(parsed_msg, 1)
            _g
            temp_socket = socket
          5 ->
            elem(parsed_msg, 1)
            _g
            temp_socket = socket
          6 ->
            _g = elem(parsed_msg, 1)
            _g = elem(parsed_msg, 2)
            message = _g
            level = _g
            temp_flash_type = nil
            case (elem(level, 0)) do
              0 ->
                temp_flash_type = :info
              1 ->
                temp_flash_type = :warning
              2 ->
                temp_flash_type = :error
              3 ->
                temp_flash_type = :error
            end
            flash_type = temp_flash_type
            temp_socket = LiveView.put_flash(socket, flash_type, message)
        end
      1 ->
        Log.trace("Received unknown PubSub message: " <> Std.string(msg), %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 197, "className" => "server.live.TodoLive", "methodName" => "handle_info"})
        temp_socket = socket
    end
    {:no_reply, temp_socket}
  end

  @doc "Generated from Haxe create_new_todo"
  def create_new_todo(params, socket) do
    params.title
    params.description
    false
    temp_right = nil
    if (params.priority != nil), do: temp_right = params.priority, else: temp_right = "medium"
    params.due_date
    TodoLive.parse_tags(params.tags)
    socket.assigns.current_user.id
    changeset_params = TypeSafeConversions.eventParamsToChangesetParams(params)
    changeset = Todo.changeset(Server.Schemas.Todo.new(), changeset_params)
    _g = Repo.insert(changeset)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        todo = _g
        _g = TodoPubSub.broadcast(:todo_updates, {:todo_created, todo})
        case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          1 ->
            _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = _g
            Log.trace("Failed to broadcast todo creation: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 228, "className" => "server.live.TodoLive", "methodName" => "create_new_todo"})
        end
        todos = [todo] ++ socket.assigns.todos
        current_assigns = socket.assigns
        complete_assigns = TypeSafeConversions.createCompleteAssigns(current_assigns, todos, nil, nil, nil, nil, false, nil, nil)
        updated_socket = LiveView.assign_multiple(socket, complete_assigns)
        LiveView.put_flash(updated_socket, :success, "Todo created successfully!")
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        LiveView.put_flash(socket, :error, "Failed to create todo: " <> Std.string(reason))
    end
  end

  @doc "Generated from Haxe toggle_todo_status"
  def toggle_todo_status(id, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket, else: nil
    updated_changeset = Todo.toggle_completed(todo)
    _g = Repo.update(updated_changeset)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        updated_todo = _g
        _g = TodoPubSub.broadcast(:todo_updates, {:todo_updated, updated_todo})
        case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          1 ->
            _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = _g
            Log.trace("Failed to broadcast todo update: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 267, "className" => "server.live.TodoLive", "methodName" => "toggle_todo_status"})
        end
        TodoLive.update_todo_in_list(updated_todo, socket)
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        LiveView.put_flash(socket, :error, "Failed to update todo: " <> Std.string(reason))
    end
  end

  @doc "Generated from Haxe delete_todo"
  def delete_todo(id, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket, else: nil
    _g = Repo.delete(todo)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        _g
        _g = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_deleted", "id" => id})
        case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          1 ->
            _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = _g
            Log.trace("Failed to broadcast todo deletion: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 292, "className" => "server.live.TodoLive", "methodName" => "delete_todo"})
        end
        TodoLive.remove_todo_from_list(id, socket)
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        LiveView.put_flash(socket, :error, "Failed to delete todo: " <> Std.string(reason))
    end
  end

  @doc "Generated from Haxe update_todo_priority"
  def update_todo_priority(id, priority, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket, else: nil
    updated_changeset = Todo.update_priority(todo, priority)
    _g = Repo.update(updated_changeset)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        updated_todo = _g
        _g = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_updated", "todo" => updated_todo})
        case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          1 ->
            _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = _g
            Log.trace("Failed to broadcast todo priority update: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 319, "className" => "server.live.TodoLive", "methodName" => "update_todo_priority"})
        end
        TodoLive.update_todo_in_list(updated_todo, socket)
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        LiveView.put_flash(socket, :error, "Failed to update priority: " <> Std.string(reason))
    end
  end

  @doc "Generated from Haxe add_todo_to_list"
  def add_todo_to_list(todo, socket) do
    if (todo.user_id == socket.assigns.current_user.id), do: socket, else: nil
    todos = [todo] ++ socket.assigns.todos
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.createCompleteAssigns(current_assigns, todos)
    LiveView.assign_multiple(socket, complete_assigns)
  end

  @doc "Generated from Haxe update_todo_in_list"
  def update_todo_in_list(updated_todo, socket) do
    _this = socket.assigns.todos
    _g = []
    _g = 0
    Enum.map(_this, fn temp_todo -> v = Enum.at(_this, _g)
    _g = _g + 1
    temp_todo = nil
    if (v.id == updated_todo.id), do: temp_todo = updated_todo, else: temp_todo = v
    _g ++ [temp_todo] end)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.createCompleteAssigns(current_assigns, _g)
    LiveView.assign_multiple(socket, complete_assigns)
  end

  @doc "Generated from Haxe remove_todo_from_list"
  def remove_todo_from_list(id, socket) do
    _this = socket.assigns.todos
    _g = []
    _g = 0
    Enum.filter(_this, fn item -> (item.id != id) end)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.createCompleteAssigns(current_assigns, _g)
    LiveView.assign_multiple(socket, complete_assigns)
  end

  @doc "Generated from Haxe load_todos"
  def load_todos(user_id) do
    query
      |> where(conditions)
      |> order_by(expr)
    query = Query.from(Todo, "t")
    where_conditions = %{}
    value = {:integer, user_id}
    where_conditions.set("user_id", value)
    conditions = %{"where" => where_conditions}
    Repo.all(query)
  end

  @doc "Generated from Haxe find_todo"
  def find_todo(id, todos) do
    _g = 0
    Enum.find(todos, fn todo -> (todo.id == id) end)
    nil
  end

  @doc "Generated from Haxe count_completed"
  def count_completed(todos) do
    count = 0
    _g = 0
    Enum.map(todos, fn todo -> todo = Enum.at(todos, _g)
    _g = _g + 1
    if (todo.completed), do: count = count + 1, else: nil end)
    count
  end

  @doc "Generated from Haxe count_pending"
  def count_pending(todos) do
    count = 0
    _g = 0
    Enum.map(todos, fn todo -> todo = Enum.at(todos, _g)
    _g = _g + 1
    if (!todo.completed), do: count = count + 1, else: nil end)
    count
  end

  @doc "Generated from Haxe parse_tags"
  def parse_tags(tags_string) do
    if (tags_string == nil || tags_string == ""), do: [], else: nil
    _this = String.split(tags_string, ",")
    _g = []
    _g = 0
    Enum.map(_this, fn item -> v = Enum.at(_this, _g)
    _g = _g + 1
    _g ++ [StringTools.trim(v)] end)
    _g
  end

  @doc "Generated from Haxe get_user_from_session"
  def get_user_from_session(session) do
    temp_number = nil
    if (session.user_id != nil), do: temp_number = session.user_id, else: temp_number = 1
    %{"id" => temp_number, "name" => "Demo User", "email" => "demo@example.com", "password_hash" => "hashed_password", "confirmed_at" => nil, "last_login_at" => nil, "active" => true}
  end

  @doc "Generated from Haxe complete_all_todos"
  def complete_all_todos(socket) do
    temp_array = nil
    _this = socket.assigns.todos
    _g = []
    _g = 0
    Enum.filter(_this, fn item -> (!item.completed) end)
    temp_array = _g
    _g = 0
    Enum.map(temp_array, fn item -> todo = Enum.at(temp_array, _g)
    _g = _g + 1
    updated_changeset = Todo.toggle_completed(todo)
    _g = Repo.update(updated_changeset)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        _g
        nil
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Failed to complete todo " <> Integer.to_string(todo.id) <> ": " <> Std.string(reason), %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 442, "className" => "server.live.TodoLive", "methodName" => "complete_all_todos"})
    end end)
    _g = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "bulk_update", "action" => "complete_all"})
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Failed to broadcast bulk complete: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 454, "className" => "server.live.TodoLive", "methodName" => "complete_all_todos"})
    end
    updated_todos = TodoLive.load_todos(socket.assigns.current_user.id)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.createCompleteAssigns(current_assigns, updated_todos)
    completeAssigns = %{completeAssigns | completed_todos: complete_assigns.total_todos}
    completeAssigns = %{completeAssigns | pending_todos: 0}
    updated_socket = LiveView.assign_multiple(socket, complete_assigns)
    LiveView.put_flash(updated_socket, :info, "All todos marked as completed!")
  end

  @doc "Generated from Haxe delete_completed_todos"
  def delete_completed_todos(socket) do
    temp_array = nil
    _this = socket.assigns.todos
    _g = []
    _g = 0
    Enum.filter(_this, fn item -> (item.completed) end)
    temp_array = _g
    _g = 0
    Enum.map(temp_array, fn item -> todo = Enum.at(temp_array, _g)
    _g = _g + 1
    Repo.delete(todo) end)
    Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "bulk_delete", "action" => "delete_completed"})
    temp_array1 = nil
    _this = socket.assigns.todos
    _g = []
    _g = 0
    Enum.filter(_this, fn item -> (!item.completed) end)
    temp_array1 = _g
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.createCompleteAssigns(current_assigns, temp_array1)
    completeAssigns = %{completeAssigns | completed_todos: 0}
    completeAssigns = %{completeAssigns | pending_todos: length(temp_array1)}
    updated_socket = LiveView.assign_multiple(socket, complete_assigns)
    LiveView.put_flash(updated_socket, :info, "Completed todos deleted!")
  end

  @doc "Generated from Haxe start_editing"
  def start_editing(id, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    SafeAssigns.setEditingTodo(socket, todo)
  end

  @doc "Generated from Haxe save_edited_todo"
  def save_edited_todo(params, socket) do
    todo = socket.assigns.editing_todo
    if (todo == nil), do: socket, else: nil
    changeset_params = TypeSafeConversions.eventParamsToChangesetParams(params)
    changeset = Todo.changeset(todo, changeset_params)
    _g = Repo.update(changeset)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        updated_todo = _g
        _g = TodoPubSub.broadcast(:todo_updates, {:todo_updated, updated_todo})
        case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          1 ->
            _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = _g
            Log.trace("Failed to broadcast todo save: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 522, "className" => "server.live.TodoLive", "methodName" => "save_edited_todo"})
        end
        updated_socket = TodoLive.update_todo_in_list(updated_todo, socket)
        LiveView.assign(updated_socket, "editing_todo", nil)
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        LiveView.put_flash(socket, :error, "Failed to save todo: " <> Std.string(reason))
    end
  end

  @doc "Generated from Haxe handle_bulk_update"
  def handle_bulk_update(action, socket) do
    temp_result = nil
    case (elem(action, 0)) do
      0 ->
        updated_todos = TodoLive.load_todos(socket.assigns.current_user.id)
        current_assigns = socket.assigns
        complete_assigns = TypeSafeConversions.createCompleteAssigns(current_assigns, updated_todos)
        temp_result = LiveView.assign_multiple(socket, complete_assigns)
      1 ->
        updated_todos = TodoLive.load_todos(socket.assigns.current_user.id)
        current_assigns = socket.assigns
        complete_assigns = TypeSafeConversions.createCompleteAssigns(current_assigns, updated_todos)
        temp_result = LiveView.assign_multiple(socket, complete_assigns)
      2 ->
        elem(action, 1)
        _g
        temp_result = socket
      3 ->
        elem(action, 1)
        _g
        temp_result = socket
      4 ->
        elem(action, 1)
        _g
        temp_result = socket
    end
    temp_result
  end

  @doc "Generated from Haxe toggle_tag_filter"
  def toggle_tag_filter(tag, socket) do
    selected_tags = socket.assigns.selected_tags
    temp_array = nil
    if (Enum.member?(selected_tags, tag)) do
      _g = []
      _g = 0
      _g = selected_tags
      Enum.filter(_g, fn item -> (item != tag) end)
      temp_array = _g
    else
      temp_array = selected_tags ++ [tag]
    end
    SafeAssigns.setSelectedTags(socket, temp_array)
  end

end
