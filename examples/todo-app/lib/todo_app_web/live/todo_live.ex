defmodule TodoAppWeb.TodoLive do
  use TodoAppWeb, :live_view

  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    (
          g_array = TodoPubSub.subscribe(:todo_updates)
          case g_array do
      {:ok, _} -> elem(g_array, 1)
      {:error, _} -> (
          g_array = elem(g_array, 1)
          reason = g_array
          MountResult.error("Failed to subscribe to updates: " <> reason)
        )
    end
        )
    current_user = TodoAppWeb.TodoLive.get_user_from_session(session)
    todos = TodoAppWeb.TodoLive.load_todos(current_user.id)
    assigns = %{"todos" => todos, "filter" => "all", "sort_by" => "created", "current_user" => current_user, "editing_todo" => nil, "show_form" => false, "search_query" => "", "selected_tags" => [], "total_todos" => todos.length, "completed_todos" => TodoAppWeb.TodoLive.count_completed(todos), "pending_todos" => TodoAppWeb.TodoLive.count_pending(todos)}
    updated_socket = Phoenix.LiveView.assign(socket, assigns)
    MountResult.ok(updated_socket)
  end


  @doc "Generated from Haxe handle_event"
  def handle_event(event, params, socket) do
    temp_socket = nil

    temp_socket = nil
    case event do
      "bulk_complete" -> TodoAppWeb.TodoLive.complete_all_todos(socket)
      "bulk_delete_completed" -> TodoAppWeb.TodoLive.delete_completed_todos(socket)
      "cancel_edit" -> SafeAssigns.set_editing_todo(socket, nil)
      "create_todo" -> TodoAppWeb.TodoLive.create_new_todo(params, socket)
      "delete_todo" -> TodoAppWeb.TodoLive.delete_todo(params.id, socket)
      "edit_todo" -> TodoAppWeb.TodoLive.start_editing(params.id, socket)
      "filter_todos" -> SafeAssigns.set_filter(socket, params.filter)
      "save_todo" -> TodoAppWeb.TodoLive.save_edited_todo(params, socket)
      "search_todos" -> SafeAssigns.set_search_query(socket, params.query)
      "set_priority" -> TodoAppWeb.TodoLive.update_todo_priority(params.id, params.priority, socket)
      "sort_todos" -> SafeAssigns.set_sort_by(socket, params.sort_by)
      "toggle_form" -> SafeAssigns.set_show_form(socket, not socket.assigns.show_form)
      "toggle_tag" -> TodoAppWeb.TodoLive.toggle_tag_filter(params.tag, socket)
      "toggle_todo" -> TodoAppWeb.TodoLive.toggle_todo_status(params.id, socket)
      _ -> socket
    end
    HandleEventResult.no_reply(temp_socket)
  end


  @doc "Generated from Haxe handle_info"
  def handle_info(msg, socket) do
    temp_socket = nil
    temp_flash_type = nil

    temp_socket
    (
          g_array = TodoPubSub.parse_message(msg)
          case g_array do
      {:ok, _} -> (
          g_array = elem(g_array, 1)
          parsed_msg = g_array
          case parsed_msg do
      :todo_created -> (
          g_array = elem(parsed_msg, 1)
          (
          todo = g_array
          temp_socket = TodoAppWeb.TodoLive.add_todo_to_list(todo, socket)
        )
        )
      :todo_updated -> (
          g_array = elem(parsed_msg, 1)
          (
          todo = g_array
          temp_socket = TodoAppWeb.TodoLive.update_todo_in_list(todo, socket)
        )
        )
      :todo_deleted -> (
          g_array = elem(parsed_msg, 1)
          id = g_array
          temp_socket = TodoAppWeb.TodoLive.remove_todo_from_list(id, socket)
        )
      :bulk_update -> (
          g_array = elem(parsed_msg, 1)
          action = g_array
          temp_socket = TodoAppWeb.TodoLive.handle_bulk_update(action, socket)
        )
      :user_online -> (
          elem(parsed_msg, 1)
          (
          g_array
          temp_socket = socket
        )
        )
      :user_offline -> (
          elem(parsed_msg, 1)
          (
          g_array
          temp_socket = socket
        )
        )
      :system_alert -> g_array = elem(parsed_msg, 1)
    g_array = elem(parsed_msg, 2)
    message = g_array
    level = g_array
    temp_flash_type = nil
    case level do
      :info -> :info
      :warning -> :warning
      :error -> :error
      :critical -> :error
    end
    flash_type = temp_flash_type
    temp_socket = Phoenix.LiveView.put_flash(socket, flash_type, message)
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
    temp_right = nil

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
    TodoAppWeb.TodoLive.parse_tags(params.tags)
    socket.assigns.current_user.id
    changeset_params = TypeSafeConversions.event_params_to_changeset_params(params)
    changeset = Todo.changeset(Server.Schemas.Todo.new(), changeset_params)
    (
          g_array = TodoApp.Repo.insert(changeset)
          case g_array do
      {:ok, _} -> g_array = elem(g_array, 1)
    todo = g_array
    (
          g_array = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_created(todo))
          case g_array do
      {:ok, _} -> elem(g_array, 1)
      {:error, _} -> (
          g_array = elem(g_array, 1)
          (
          reason = g_array
          Log.trace("Failed to broadcast todo creation: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 228, "className" => "server.live.TodoLive", "methodName" => "create_new_todo"})
        )
        )
    end
        )
    todos = [todo] ++ socket.assigns.todos
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, todos, nil, nil, nil, nil, false, nil, nil)
    updated_socket = Phoenix.LiveView.assign(socket, complete_assigns)
    Phoenix.LiveView.put_flash(updated_socket, :success, "Todo created successfully!")
      {:error, _} -> (
          g_array = elem(g_array, 1)
          (
          reason = g_array
          Phoenix.LiveView.put_flash(socket, :error, "Failed to create todo: " <> Std.string(reason))
        )
        )
    end
        )
  end


  @doc "Generated from Haxe toggle_todo_status"
  def toggle_todo_status(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    if ((todo == nil)) do
          socket
        end
    updated_changeset = Todo.toggle_completed(todo)
    (
          g_array = TodoApp.Repo.update(updated_changeset)
          case g_array do
      {:ok, _} -> (
          g_array = elem(g_array, 1)
          updated_todo = g_array
          (
          g_array = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_updated(updated_todo))
          case g_array do
      {:ok, _} -> elem(g_array, 1)
      {:error, _} -> (
          g_array = elem(g_array, 1)
          (
          reason = g_array
          Log.trace("Failed to broadcast todo update: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 267, "className" => "server.live.TodoLive", "methodName" => "toggle_todo_status"})
        )
        )
    end
        )
          TodoAppWeb.TodoLive.update_todo_in_list(updated_todo, socket)
        )
      {:error, _} -> (
          g_array = elem(g_array, 1)
          (
          reason = g_array
          Phoenix.LiveView.put_flash(socket, :error, "Failed to update todo: " <> Std.string(reason))
        )
        )
    end
        )
  end


  @doc "Generated from Haxe delete_todo"
  def delete_todo(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    if ((todo == nil)) do
          socket
        end
    (
          g_array = TodoApp.Repo.delete(todo)
          case g_array do
      {:ok, _} -> (
          elem(g_array, 1)
          g_array
          (
          g_array = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_deleted", "id" => id})
          case g_array do
      {:ok, _} -> elem(g_array, 1)
      {:error, _} -> (
          g_array = elem(g_array, 1)
          (
          reason = g_array
          Log.trace("Failed to broadcast todo deletion: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 292, "className" => "server.live.TodoLive", "methodName" => "delete_todo"})
        )
        )
    end
        )
          TodoAppWeb.TodoLive.remove_todo_from_list(id, socket)
        )
      {:error, _} -> (
          g_array = elem(g_array, 1)
          (
          reason = g_array
          Phoenix.LiveView.put_flash(socket, :error, "Failed to delete todo: " <> Std.string(reason))
        )
        )
    end
        )
  end


  @doc "Generated from Haxe update_todo_priority"
  def update_todo_priority(id, priority, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    if ((todo == nil)) do
          socket
        end
    updated_changeset = Todo.update_priority(todo, priority)
    (
          g_array = TodoApp.Repo.update(updated_changeset)
          case g_array do
      {:ok, _} -> (
          g_array = elem(g_array, 1)
          updated_todo = g_array
          (
          g_array = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_updated", "todo" => updated_todo})
          case g_array do
      {:ok, _} -> elem(g_array, 1)
      {:error, _} -> (
          g_array = elem(g_array, 1)
          (
          reason = g_array
          Log.trace("Failed to broadcast todo priority update: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 319, "className" => "server.live.TodoLive", "methodName" => "update_todo_priority"})
        )
        )
    end
        )
          TodoAppWeb.TodoLive.update_todo_in_list(updated_todo, socket)
        )
      {:error, _} -> (
          g_array = elem(g_array, 1)
          (
          reason = g_array
          Phoenix.LiveView.put_flash(socket, :error, "Failed to update priority: " <> Std.string(reason))
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
    Phoenix.LiveView.assign(socket, complete_assigns)
  end


  @doc "Generated from Haxe update_todo_in_list"
  def update_todo_in_list(updated_todo, socket) do
    temp_todo = nil

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
      g_array ++ [temp_todo]
    end)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, g_array)
    Phoenix.LiveView.assign(socket, complete_assigns)
  end


  @doc "Generated from Haxe remove_todo_from_list"
  def remove_todo_from_list(id, socket) do
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    Enum.each(this, fn v -> 
      if ((v.id != id)) do
          g_array ++ [v]
        end
    end)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, g_array)
    Phoenix.LiveView.assign(socket, complete_assigns)
  end


  @doc "Generated from Haxe load_todos"
  def load_todos(user_id) do
    query = Ecto.Query.from(Todo, "t")
    where_conditions = Haxe.Ds.StringMap.new()
    value = QueryValue.integer(user_id)
    where_conditions.set("user_id", value)
    conditions = %{"where" => where_conditions}
    query = Ecto.Query.where(query, conditions)
    Enum.all?(TodoApp.Repo, query)
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
      g_array ++ [StringTools.trim(v)]
    end)
    g_array
  end


  @doc "Generated from Haxe get_user_from_session"
  def get_user_from_session(session) do
    temp_number = nil

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
    temp_array = nil

    temp_array
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    Enum.each(this, fn v -> 
      if (not v.completed) do
          g_array ++ [v]
        end
    end)
    temp_array = g_array
    g_counter = 0
    Enum.each(temp_array, fn todo -> 
      updated_changeset = Todo.toggle_completed(todo)
      (
          g_array = TodoApp.Repo.update(updated_changeset)
          case g_array do
      {:ok, _} -> (
          elem(g_array, 1)
          (
          g_array
          nil
        )
        )
      {:error, _} -> (
          g_array = elem(g_array, 1)
          (
          reason = g_array
          Log.trace("Failed to complete todo " <> to_string(todo.id) <> ": " <> Std.string(reason), %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 446, "className" => "server.live.TodoLive", "methodName" => "complete_all_todos"})
        )
        )
    end
        )
    end)
    (
          g_array = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "bulk_update", "action" => "complete_all"})
          case g_array do
      {:ok, _} -> elem(g_array, 1)
      {:error, _} -> (
          g_array = elem(g_array, 1)
          (
          reason = g_array
          Log.trace("Failed to broadcast bulk complete: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 458, "className" => "server.live.TodoLive", "methodName" => "complete_all_todos"})
        )
        )
    end
        )
    updated_todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
    %{complete_assigns | completed_todos: complete_assigns.total_todos}
    %{complete_assigns | pending_todos: 0}
    updated_socket = Phoenix.LiveView.assign(socket, complete_assigns)
    Phoenix.LiveView.put_flash(updated_socket, :info, "All todos marked as completed!")
  end


  @doc "Generated from Haxe delete_completed_todos"
  def delete_completed_todos(socket) do
    temp_array = nil
    temp_array1 = nil

    temp_array
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    Enum.each(this, fn v -> 
      if v.completed do
          g_array ++ [v]
        end
    end)
    temp_array = g_array
    g_counter = 0
    Enum.each(temp_array, fn todo -> 
      TodoApp.Repo.delete(todo)
    end)
    Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "bulk_delete", "action" => "delete_completed"})
    temp_array1 = nil
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    Enum.each(this, fn v -> 
      if (not v.completed) do
          g_array ++ [v]
        end
    end)
    temp_array1 = g_array
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, temp_array1)
    %{complete_assigns | completed_todos: 0}
    %{complete_assigns | pending_todos: temp_array1.length}
    updated_socket = Phoenix.LiveView.assign(socket, complete_assigns)
    Phoenix.LiveView.put_flash(updated_socket, :info, "Completed todos deleted!")
  end


  @doc "Generated from Haxe start_editing"
  def start_editing(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
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
          g_array = TodoApp.Repo.update(changeset)
          case g_array do
      {:ok, _} -> (
          g_array = elem(g_array, 1)
          updated_todo = g_array
          (
          g_array = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_updated(updated_todo))
          case g_array do
      {:ok, _} -> elem(g_array, 1)
      {:error, _} -> (
          g_array = elem(g_array, 1)
          (
          reason = g_array
          Log.trace("Failed to broadcast todo save: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 526, "className" => "server.live.TodoLive", "methodName" => "save_edited_todo"})
        )
        )
    end
        )
          updated_socket = TodoAppWeb.TodoLive.update_todo_in_list(updated_todo, socket)
          Phoenix.LiveView.assign(updated_socket, "editing_todo", nil)
        )
      {:error, _} -> (
          g_array = elem(g_array, 1)
          (
          reason = g_array
          Phoenix.LiveView.put_flash(socket, :error, "Failed to save todo: " <> Std.string(reason))
        )
        )
    end
        )
  end


  @doc "Generated from Haxe handle_bulk_update"
  def handle_bulk_update(action, socket) do
    temp_result = nil

    temp_result
    case action do
      :complete_all -> (
          updated_todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
          current_assigns = socket.assigns
          complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
          temp_result = Phoenix.LiveView.assign(socket, complete_assigns)
        )
      :delete_completed -> (
          updated_todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
          current_assigns = socket.assigns
          complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
          temp_result = Phoenix.LiveView.assign(socket, complete_assigns)
        )
      :set_priority -> (
          elem(action, 1)
          g_array
          temp_result = socket
        )
      :add_tag -> (
          elem(action, 1)
          (
          g_array
          temp_result = socket
        )
        )
      :remove_tag -> (
          elem(action, 1)
          (
          g_array
          temp_result = socket
        )
        )
    end
    temp_result
  end


  @doc "Generated from Haxe toggle_tag_filter"
  def toggle_tag_filter(tag, socket) do
    temp_array = nil

    selected_tags = socket.assigns.selected_tags
    temp_array
    if Enum.member?(selected_tags, tag) do
          (
          g_array = []
          g_counter = 0
          g_array = selected_tags
          Enum.each(g_array, fn v -> 
      if ((v != tag)) do
          g_array ++ [v]
        end
    end)
          temp_array = g_array
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
