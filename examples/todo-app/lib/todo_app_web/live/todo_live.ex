defmodule TodoLive do
  use AppWeb, :live_view

  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    (
          g = TodoPubSub.subscribe(:todo_updates)
          case g do
      {:ok, _} -> elem(g, 1)
      {:error, _} -> (
          g = elem(g, 1)
          reason = g
          MountResult.error("Failed to subscribe to updates: " <> reason)
        )
    end
        )
    current_user = TodoLive.get_user_from_session(session)
    todos = TodoLive.load_todos(current_user.id)
    assigns = %{"todos" => todos, "filter" => "all", "sort_by" => "created", "current_user" => current_user, "editing_todo" => nil, "show_form" => false, "search_query" => "", "selected_tags" => [], "total_todos" => todos.length, "completed_todos" => TodoLive.count_completed(todos), "pending_todos" => TodoLive.count_pending(todos)}
    updated_socket = LiveView.assign_multiple(socket, assigns)
    MountResult.ok(updated_socket)
  end


  @doc "Generated from Haxe handle_event"
  def handle_event(event, params, socket) do
    temp_socket = nil
    case event do
      "bulk_complete" -> temp_socket = TodoLive.complete_all_todos(socket)
      "bulk_delete_completed" -> temp_socket = TodoLive.delete_completed_todos(socket)
      "cancel_edit" -> temp_socket = SafeAssigns.set_editing_todo(socket, nil)
      "create_todo" -> temp_socket = TodoLive.create_new_todo(params, socket)
      "delete_todo" -> temp_socket = TodoLive.delete_todo(params.id, socket)
      "edit_todo" -> temp_socket = TodoLive.start_editing(params.id, socket)
      "filter_todos" -> temp_socket = SafeAssigns.set_filter(socket, params.filter)
      "save_todo" -> temp_socket = TodoLive.save_edited_todo(params, socket)
      "search_todos" -> temp_socket = SafeAssigns.set_search_query(socket, params.query)
      "set_priority" -> temp_socket = TodoLive.update_todo_priority(params.id, params.priority, socket)
      "sort_todos" -> temp_socket = SafeAssigns.set_sort_by(socket, params.sort_by)
      "toggle_form" -> temp_socket = SafeAssigns.set_show_form(socket, not socket.assigns.show_form)
      "toggle_tag" -> temp_socket = TodoLive.toggle_tag_filter(params.tag, socket)
      "toggle_todo" -> temp_socket = TodoLive.toggle_todo_status(params.id, socket)
      _ -> temp_socket = socket
    end
    HandleEventResult.no_reply(temp_socket)
  end


  @doc "Generated from Haxe handle_info"
  def handle_info(msg, socket) do
    temp_socket
    (
          g = TodoPubSub.parse_message(msg)
          case g do
      {:ok, _} -> (
          g = elem(g, 1)
          parsed_msg = g
          case (elem(parsed_msg, 0)) do
      {0, todo} -> (
          g = elem(parsed_msg, 1)
          temp_socket = TodoLive.add_todo_to_list(todo, socket)
        )
      {1, todo} -> (
          g = elem(parsed_msg, 1)
          temp_socket = TodoLive.update_todo_in_list(todo, socket)
        )
      {2, id} -> (
          g = elem(parsed_msg, 1)
          temp_socket = TodoLive.remove_todo_from_list(id, socket)
        )
      {3, action} -> (
          g = elem(parsed_msg, 1)
          temp_socket = TodoLive.handle_bulk_update(action, socket)
        )
      {4, user_id} -> (
          elem(parsed_msg, 1)
          temp_socket = socket
        )
      {5, user_id} -> (
          elem(parsed_msg, 1)
          temp_socket = socket
        )
      {6, message, level} -> (
          g = elem(parsed_msg, 1)
          g = elem(parsed_msg, 2)
          temp_flash_type = nil
          case (elem(level, 0)) do
      0 -> temp_flash_type = :info
      1 -> temp_flash_type = :warning
      2 -> temp_flash_type = :error
      3 -> temp_flash_type = :error
    end
          flash_type = temp_flash_type
          temp_socket = LiveView.put_flash(socket, flash_type, message)
        )
    end
        )
      :error -> (
          Log.trace("Received unknown PubSub message: " <> Std.string(msg), %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 197, "className" => "server.live.TodoLive", "methodName" => "handle_info"})
          temp_socket = socket
        )
    end
        )
    HandleInfoResult.no_reply(temp_socket)
  end


  @doc "Generated from Haxe create_new_todo"
  def create_new_todo(params, socket) do
    params.title
    params.description
    false
    temp_right = nil
    if ((params.priority != nil)) do
          temp_right = params.priority
        else
          temp_right = "medium"
        end
    params.due_date
    TodoLive.parse_tags(params.tags)
    socket.assigns.current_user.id
    changeset_params = TypeSafeConversions.event_params_to_changeset_params(params)
    changeset = Todo.changeset(Server.Schemas.Todo.new(), changeset_params)
    (
          g = Repo.insert(changeset)
          case g do
      {:ok, _} -> g = elem(g, 1)
    todo = g
    (
          g = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_created(todo))
          case g do
      {:ok, _} -> elem(g, 1)
      {:error, _} -> (
          g = elem(g, 1)
          (
          reason = g
          Log.trace("Failed to broadcast todo creation: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 228, "className" => "server.live.TodoLive", "methodName" => "create_new_todo"})
        )
        )
    end
        )
    todos = [todo] ++ socket.assigns.todos
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, todos, nil, nil, nil, nil, false, nil, nil)
    updated_socket = LiveView.assign_multiple(socket, complete_assigns)
    LiveView.put_flash(updated_socket, :success, "Todo created successfully!")
      {:error, _} -> (
          g = elem(g, 1)
          (
          reason = g
          LiveView.put_flash(socket, :error, "Failed to create todo: " <> Std.string(reason))
        )
        )
    end
        )
  end


  @doc "Generated from Haxe toggle_todo_status"
  def toggle_todo_status(id, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    if ((todo == nil)) do
          socket
        end
    updated_changeset = Todo.toggle_completed(todo)
    (
          g = Repo.update(updated_changeset)
          case g do
      {:ok, _} -> (
          g = elem(g, 1)
          updated_todo = g
          (
          g = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_updated(updated_todo))
          case g do
      {:ok, _} -> elem(g, 1)
      {:error, _} -> (
          g = elem(g, 1)
          (
          reason = g
          Log.trace("Failed to broadcast todo update: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 267, "className" => "server.live.TodoLive", "methodName" => "toggle_todo_status"})
        )
        )
    end
        )
          TodoLive.update_todo_in_list(updated_todo, socket)
        )
      {:error, _} -> (
          g = elem(g, 1)
          (
          reason = g
          LiveView.put_flash(socket, :error, "Failed to update todo: " <> Std.string(reason))
        )
        )
    end
        )
  end


  @doc "Generated from Haxe delete_todo"
  def delete_todo(id, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    if ((todo == nil)) do
          socket
        end
    (
          g = Repo.delete(todo)
          case g do
      {:ok, _} -> (
          elem(g, 1)
          g
          (
          g = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_deleted", "id" => id})
          case g do
      {:ok, _} -> elem(g, 1)
      {:error, _} -> (
          g = elem(g, 1)
          (
          reason = g
          Log.trace("Failed to broadcast todo deletion: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 292, "className" => "server.live.TodoLive", "methodName" => "delete_todo"})
        )
        )
    end
        )
          TodoLive.remove_todo_from_list(id, socket)
        )
      {:error, _} -> (
          g = elem(g, 1)
          (
          reason = g
          LiveView.put_flash(socket, :error, "Failed to delete todo: " <> Std.string(reason))
        )
        )
    end
        )
  end


  @doc "Generated from Haxe update_todo_priority"
  def update_todo_priority(id, priority, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    if ((todo == nil)) do
          socket
        end
    updated_changeset = Todo.update_priority(todo, priority)
    (
          g = Repo.update(updated_changeset)
          case g do
      {:ok, _} -> (
          g = elem(g, 1)
          updated_todo = g
          (
          g = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_updated", "todo" => updated_todo})
          case g do
      {:ok, _} -> elem(g, 1)
      {:error, _} -> (
          g = elem(g, 1)
          (
          reason = g
          Log.trace("Failed to broadcast todo priority update: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 319, "className" => "server.live.TodoLive", "methodName" => "update_todo_priority"})
        )
        )
    end
        )
          TodoLive.update_todo_in_list(updated_todo, socket)
        )
      {:error, _} -> (
          g = elem(g, 1)
          (
          reason = g
          LiveView.put_flash(socket, :error, "Failed to update priority: " <> Std.string(reason))
        )
        )
    end
        )
  end


  @doc "Generated from Haxe add_todo_to_list"
  def add_todo_to_list(todo, socket) do
    if ((todo.user_id == socket.assigns.current_user.id)) do
          socket
        end
    todos = [todo] ++ socket.assigns.todos
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, todos)
    LiveView.assign_multiple(socket, complete_assigns)
  end


  @doc "Generated from Haxe update_todo_in_list"
  def update_todo_in_list(updated_todo, socket) do
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    Enum.each(this, fn v -> 
      temp_todo = nil
      if ((v.id == updated_todo.id)) do
          temp_todo = updated_todo
        else
          temp_todo = v
        end
      g ++ [temp_todo]
    end)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, g)
    LiveView.assign_multiple(socket, complete_assigns)
  end


  @doc "Generated from Haxe remove_todo_from_list"
  def remove_todo_from_list(id, socket) do
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    Enum.each(this, fn v -> 
      if ((v.id != id)) do
          g ++ [v]
        end
    end)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, g)
    LiveView.assign_multiple(socket, complete_assigns)
  end


  @doc "Generated from Haxe load_todos"
  def load_todos(user_id) do
    query = Query.from(Todo, "t")
    where_conditions = Haxe.Ds.StringMap.new()
    value = QueryValue.integer(user_id)
    where_conditions.set("user_id", value)
    conditions = %{"where" => where_conditions}
    query = Query.where(query, conditions)
    Enum.all?(Repo, query)
  end


  @doc "Generated from Haxe find_todo"
  def find_todo(id, todos) do
    g_counter = 0
    Enum.each(todos, fn todo -> 
      if ((todo.id == id)) do
          todo
        end
    end)
    nil
  end


  @doc "Generated from Haxe count_completed"
  def count_completed(todos) do
    count = 0
    g_counter = 0
    Enum.each(todos, fn todo -> 
      if todo.completed do
          count + 1
        end
    end)
    count
  end


  @doc "Generated from Haxe count_pending"
  def count_pending(todos) do
    count = 0
    g_counter = 0
    Enum.each(todos, fn todo -> 
      if (not todo.completed) do
          count + 1
        end
    end)
    count
  end


  @doc "Generated from Haxe parse_tags"
  def parse_tags(tags_string) do
    if (((tags_string == nil) || (tags_string == ""))) do
          []
        end
    this = tags_string.split(",")
    g_array = []
    g_counter = 0
    Enum.each(this, fn v -> 
      g ++ [StringTools.trim(v)]
    end)
    g
  end


  @doc "Generated from Haxe get_user_from_session"
  def get_user_from_session(session) do
    temp_number = nil
    if ((session.user_id != nil)) do
          temp_number = session.user_id
        else
          temp_number = 1
        end
    %{"id" => temp_number, "name" => "Demo User", "email" => "demo@example.com", "password_hash" => "hashed_password", "confirmed_at" => nil, "last_login_at" => nil, "active" => true}
  end


  @doc "Generated from Haxe complete_all_todos"
  def complete_all_todos(socket) do
    temp_array
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    Enum.each(this, fn v -> 
      if (not v.completed) do
          g ++ [v]
        end
    end)
    temp_array = g
    g_counter = 0
    Enum.each(temp_array, fn todo -> 
      updated_changeset = Todo.toggle_completed(todo)
      (
          g = Repo.update(updated_changeset)
          case g do
      {:ok, _} -> (
          elem(g, 1)
          (
          g
          nil
        )
        )
      {:error, _} -> (
          g = elem(g, 1)
          (
          reason = g
          Log.trace("Failed to complete todo " <> to_string(todo.id) <> ": " <> Std.string(reason), %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 446, "className" => "server.live.TodoLive", "methodName" => "complete_all_todos"})
        )
        )
    end
        )
    end)
    (
          g = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "bulk_update", "action" => "complete_all"})
          case g do
      {:ok, _} -> elem(g, 1)
      {:error, _} -> (
          g = elem(g, 1)
          (
          reason = g
          Log.trace("Failed to broadcast bulk complete: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 458, "className" => "server.live.TodoLive", "methodName" => "complete_all_todos"})
        )
        )
    end
        )
    updated_todos = TodoLive.load_todos(socket.assigns.current_user.id)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
    %{complete_assigns | completed_todos: complete_assigns.total_todos}
    %{complete_assigns | pending_todos: 0}
    updated_socket = LiveView.assign_multiple(socket, complete_assigns)
    LiveView.put_flash(updated_socket, :info, "All todos marked as completed!")
  end


  @doc "Generated from Haxe delete_completed_todos"
  def delete_completed_todos(socket) do
    temp_array
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    Enum.each(this, fn v -> 
      if v.completed do
          g ++ [v]
        end
    end)
    temp_array = g
    g_counter = 0
    Enum.map(temp_array, fn todo -> todo end)
    Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "bulk_delete", "action" => "delete_completed"})
    temp_array1 = nil
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    Enum.each(this, fn v -> 
      if (not v.completed) do
          g ++ [v]
        end
    end)
    temp_array1 = g
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, temp_array1)
    %{complete_assigns | completed_todos: 0}
    %{complete_assigns | pending_todos: temp_array1.length}
    updated_socket = LiveView.assign_multiple(socket, complete_assigns)
    LiveView.put_flash(updated_socket, :info, "Completed todos deleted!")
  end


  @doc "Generated from Haxe start_editing"
  def start_editing(id, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    SafeAssigns.set_editing_todo(socket, todo)
  end


  @doc "Generated from Haxe save_edited_todo"
  def save_edited_todo(params, socket) do
    todo = socket.assigns.editing_todo
    if ((todo == nil)) do
          socket
        end
    changeset_params = TypeSafeConversions.event_params_to_changeset_params(params)
    changeset = Todo.changeset(todo, changeset_params)
    (
          g = Repo.update(changeset)
          case g do
      {:ok, _} -> (
          g = elem(g, 1)
          updated_todo = g
          (
          g = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_updated(updated_todo))
          case g do
      {:ok, _} -> elem(g, 1)
      {:error, _} -> (
          g = elem(g, 1)
          (
          reason = g
          Log.trace("Failed to broadcast todo save: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 526, "className" => "server.live.TodoLive", "methodName" => "save_edited_todo"})
        )
        )
    end
        )
          updated_socket = TodoLive.update_todo_in_list(updated_todo, socket)
          LiveView.assign(updated_socket, "editing_todo", nil)
        )
      {:error, _} -> (
          g = elem(g, 1)
          (
          reason = g
          LiveView.put_flash(socket, :error, "Failed to save todo: " <> Std.string(reason))
        )
        )
    end
        )
  end


  @doc "Generated from Haxe handle_bulk_update"
  def handle_bulk_update(action, socket) do
    temp_result
    case (elem(action, 0)) do
      0 -> (
          updated_todos = TodoLive.load_todos(socket.assigns.current_user.id)
          current_assigns = socket.assigns
          complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
          temp_result = LiveView.assign_multiple(socket, complete_assigns)
        )
      1 -> (
          updated_todos = TodoLive.load_todos(socket.assigns.current_user.id)
          current_assigns = socket.assigns
          complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
          temp_result = LiveView.assign_multiple(socket, complete_assigns)
        )
      {2, priority} -> (
          elem(action, 1)
          temp_result = socket
        )
      {3, tag} -> (
          elem(action, 1)
          temp_result = socket
        )
      {4, tag} -> (
          elem(action, 1)
          temp_result = socket
        )
    end
    temp_result
  end


  @doc "Generated from Haxe toggle_tag_filter"
  def toggle_tag_filter(tag, socket) do
    selected_tags = socket.assigns.selected_tags
    temp_array
    if Enum.member?(selected_tags, tag) do
          (
          g_array = []
          g_counter = 0
          g = selected_tags
          Enum.each(g, fn v -> 
      if ((v != tag)) do
          g ++ [v]
        end
    end)
          temp_array = g
        )
        else
          temp_array = selected_tags ++ [tag]
        end
    SafeAssigns.set_selected_tags(socket, temp_array)
  end


  @doc "Generated from Haxe index"
  def index() do
    "index"
  end


  @doc "Generated from Haxe show"
  def show() do
    "show"
  end


  @doc "Generated from Haxe edit"
  def edit() do
    "edit"
  end


end
