defmodule TodoAppWeb.TodoLive do
  use TodoAppWeb, :live_view

  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    g_array = TodoPubSub.subscribe(:todo_updates)
    case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> nil
      {1, reason} -> g_array = elem(g_array, 1)
    MountResult.error("Failed to subscribe to updates: " <> reason)
    end

    current_user = TodoAppWeb.TodoLive.get_user_from_session(session)

    todos = TodoAppWeb.TodoLive.load_todos(current_user.id)

    _assigns = %{todos: todos, filter: "all", sort_by: "created", current_user: current_user, editing_todo: nil, show_form: false, search_query: "", selected_tags: [], total_todos: todos.length, completed_todos: TodoAppWeb.TodoLive.count_completed(todos), pending_todos: TodoAppWeb.TodoLive.count_pending(todos)}

    updated_socket = Phoenix.LiveView.assign(socket, _assigns)

    MountResult.ok(updated_socket)
  end


  @doc "Generated from Haxe handle_event"
  def handle_event(event, params, socket) do
    temp_socket = nil

    temp_socket = nil

    case (event) do
      _ -> socket
    end

    HandleEventResult.no_reply(temp_socket)
  end


  @doc "Generated from Haxe handle_info"
  def handle_info(msg, socket) do
    temp_socket = nil
    temp_flash_type = nil

    temp_socket = nil

    g_array = TodoPubSub.parse_message(msg)
    case (case g_array do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, _parsed_msg} -> g_array = elem(g_array, 1)
    case (case parsed_msg do :todo_created -> 0; :todo_updated -> 1; :todo_deleted -> 2; :bulk_update -> 3; :user_online -> 4; :user_offline -> 5; :system_alert -> 6; _ -> -1 end) do
      {0, todo} -> g_array = elem(parsedMsg, 1)
    temp_socket = TodoAppWeb.TodoLive.add_todo_to_list(todo, socket)
      {1, todo} -> g_array = elem(parsedMsg, 1)
    temp_socket = TodoAppWeb.TodoLive.update_todo_in_list(todo, socket)
      {2, id} -> g_array = elem(parsedMsg, 1)
    temp_socket = TodoAppWeb.TodoLive.remove_todo_from_list(id, socket)
      {3, action} -> g_array = elem(parsedMsg, 1)
    temp_socket = TodoAppWeb.TodoLive.handle_bulk_update(action, socket)
      {4, __user_id} -> g_array = elem(parsedMsg, 1)
    temp_socket = socket
      {5, __user_id} -> g_array = elem(parsedMsg, 1)
    temp_socket = socket
      {6, message, _level} -> g_array = elem(parsedMsg, 1)
    g_array = elem(parsedMsg, 2)
    temp_flash_type = nil
    case (case level do :info -> 0; :warning -> 1; :error -> 2; :critical -> 3; _ -> -1 end) do
      0 -> :info
      1 -> :warning
      2 -> :error
      3 -> :error
    end
    flash_type = temp_flash_type
    temp_socket = Phoenix.LiveView.put_flash(socket, flash_type, message)
    end
      1 -> Log.trace("Received unknown PubSub message: " <> Std.string(msg), %{fileName: "src_haxe/server/live/TodoLive.hx", lineNumber: 197, className: "server.live.TodoLive", methodName: "handle_info"})
    temp_socket = socket
    end

    HandleInfoResult.no_reply(temp_socket)
  end


  @doc "Generated from Haxe create_new_todo"
  def create_new_todo(params, socket) do
    temp_right = nil

    _todo_params_title = params.title

    _todo_params_description = params.description

    _todo_params_completed = false

    temp_right = nil

    if ((params.priority != nil)), do: temp_right = params.priority, else: temp_right = "medium"

    _todo_params_due_date = params.due_date

    _todo_params_tags = TodoAppWeb.TodoLive.parse_tags(params.tags)

    _todo_params_user_id = socket.assigns.current_user.id

    changeset_params = TypeSafeConversions.event_params_to_changeset_params(params)

    _changeset = Todo.changeset(Todo.new(), changeset_params)

    g_array = TodoApp.Repo.insert(_changeset)
    case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, todo} -> g_array = elem(g_array, 1)
    g_array = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_created(todo))
    case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> nil
      {1, reason} -> g_array = elem(g3_array, 1)
    Log.trace("Failed to broadcast todo creation: " <> reason, %{fileName: "src_haxe/server/live/TodoLive.hx", lineNumber: 228, className: "server.live.TodoLive", methodName: "create_new_todo"})
    end
    todos = [todo] ++ socket.assigns.todos
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, todos, nil, nil, nil, nil, false, nil, nil)
    updated_socket = Phoenix.LiveView.assign(socket, complete_assigns)
    Phoenix.LiveView.put_flash(updated_socket, :success, "Todo created successfully!")
      {1, reason} -> g_array = elem(g_array, 1)
    Phoenix.LiveView.put_flash(socket, :error, "Failed to create todo: " <> Std.string(reason))
    end
  end


  @doc "Generated from Haxe toggle_todo_status"
  def toggle_todo_status(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)

    if ((todo == nil)) do
      socket
    else
      nil
    end

    updated_changeset = Todo.toggle_completed(todo)

    g_array = TodoApp.Repo.update(updated_changeset)
    case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, updated_todo} -> g_array = elem(g_array, 1)
    g_array = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_updated(updated_todo))
    case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> nil
      {1, reason} -> g_array = elem(g3_array, 1)
    Log.trace("Failed to broadcast todo update: " <> reason, %{fileName: "src_haxe/server/live/TodoLive.hx", lineNumber: 267, className: "server.live.TodoLive", methodName: "toggle_todo_status"})
    end
    TodoAppWeb.TodoLive.update_todo_in_list(updated_todo, socket)
      {1, reason} -> g_array = elem(g_array, 1)
    Phoenix.LiveView.put_flash(socket, :error, "Failed to update todo: " <> Std.string(reason))
    end
  end


  @doc "Generated from Haxe delete_todo"
  def delete_todo(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)

    if ((todo == nil)) do
      socket
    else
      nil
    end

    g_array = TodoApp.Repo.delete(todo)
    case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, __deleted_todo} -> g_array = elem(g_array, 1)
    g_array = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_deleted(id))
    case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> nil
      {1, reason} -> g_array = elem(g3_array, 1)
    Log.trace("Failed to broadcast todo deletion: " <> reason, %{fileName: "src_haxe/server/live/TodoLive.hx", lineNumber: 289, className: "server.live.TodoLive", methodName: "delete_todo"})
    end
    TodoAppWeb.TodoLive.remove_todo_from_list(id, socket)
      {1, reason} -> g_array = elem(g_array, 1)
    Phoenix.LiveView.put_flash(socket, :error, "Failed to delete todo: " <> Std.string(reason))
    end
  end


  @doc "Generated from Haxe update_todo_priority"
  def update_todo_priority(id, priority, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)

    if ((todo == nil)) do
      socket
    else
      nil
    end

    updated_changeset = Todo.update_priority(todo, priority)

    g_array = TodoApp.Repo.update(updated_changeset)
    case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, updated_todo} -> g_array = elem(g_array, 1)
    g_array = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_updated(updated_todo))
    case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> nil
      {1, reason} -> g_array = elem(g3_array, 1)
    Log.trace("Failed to broadcast todo priority update: " <> reason, %{fileName: "src_haxe/server/live/TodoLive.hx", lineNumber: 313, className: "server.live.TodoLive", methodName: "update_todo_priority"})
    end
    TodoAppWeb.TodoLive.update_todo_in_list(updated_todo, socket)
      {1, reason} -> g_array = elem(g_array, 1)
    Phoenix.LiveView.put_flash(socket, :error, "Failed to update priority: " <> Std.string(reason))
    end
  end


  @doc "Generated from Haxe add_todo_to_list"
  def add_todo_to_list(todo, socket) do
    if ((todo.user_id == socket.assigns.current_user.id)) do
      socket
    else
      nil
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

    (fn loop ->
      if ((g_counter < this.length)) do
            v = Enum.at(this, g_counter)
        g_counter + 1
        temp_todo = nil
        if ((v.id == updated_todo.id)), do: temp_todo = updated_todo, else: temp_todo = v
        g_array ++ [temp_todo]
        loop.()
      end
    end).()

    current_assigns = socket.assigns

    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, g_array)

    Phoenix.LiveView.assign(socket, complete_assigns)
  end


  @doc "Generated from Haxe remove_todo_from_list"
  def remove_todo_from_list(id, socket) do
    this = socket.assigns.todos

    g_array = []

    g_counter = 0

    (fn loop ->
      if ((g_counter < this.length)) do
            v = Enum.at(this, g_counter)
        g_counter + 1
        if ((v.id != id)), do: g_array ++ [v], else: nil
        loop.()
      end
    end).()

    current_assigns = socket.assigns

    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, g_array)

    Phoenix.LiveView.assign(socket, complete_assigns)
  end


  @doc "Generated from Haxe load_todos"
  def load_todos(user_id) do
    query = Ecto.Query.from(Todo, "t")

    where_conditions = StringMap.new()

    _value = QueryValue.integer(user_id)

    where_conditions = Map.put(where_conditions, "user_id", _value)

    conditions = %{where: where_conditions}

    query = Ecto.Query.where(query, conditions)

    Enum.all?(TodoApp.Repo, query)
  end


  @doc "Generated from Haxe find_todo"
  def find_todo(id, todos) do
    g_counter = 0

    (fn loop ->
      if ((g_counter < todos.length)) do
            todo = Enum.at(todos, g_counter)
        g_counter + 1
        if ((todo.id == id)) do
          todo
        else
          nil
        end
        loop.()
      end
    end).()

    nil
  end


  @doc "Generated from Haxe count_completed"
  def count_completed(todos) do
    count = 0

    g_counter = 0

    (fn loop ->
      if ((g_counter < todos.length)) do
            todo = Enum.at(todos, g_counter)
        g_counter + 1
        if todo.completed, do: count + 1, else: nil
        loop.()
      end
    end).()

    count
  end


  @doc "Generated from Haxe count_pending"
  def count_pending(todos) do
    count = 0

    g_counter = 0

    (fn loop ->
      if ((g_counter < todos.length)) do
            todo = Enum.at(todos, g_counter)
        g_counter + 1
        if (not todo.completed), do: count + 1, else: nil
        loop.()
      end
    end).()

    count
  end


  @doc "Generated from Haxe parse_tags"
  def parse_tags(tags_string) do
    if (((tags_string == nil) || (tags_string == ""))) do
      []
    else
      nil
    end

    this = tags_string.split(",")

    g_array = []

    g_counter = 0

    (fn loop ->
      if ((g_counter < this.length)) do
            v = Enum.at(this, g_counter)
        g_counter + 1
        g_array ++ [StringTools.trim(v)]
        loop.()
      end
    end).()

    g_array
  end


  @doc "Generated from Haxe get_user_from_session"
  def get_user_from_session(session) do
    temp_number = nil

    temp_number = nil

    if ((session.user_id != nil)), do: temp_number = session.user_id, else: temp_number = 1

    %{id: temp_number, name: "Demo User", email: "demo@example.com", password_hash: "hashed_password", confirmed_at: nil, last_login_at: nil, active: true}
  end


  @doc "Generated from Haxe complete_all_todos"
  def complete_all_todos(socket) do
    temp_array = nil

    this = socket.assigns.todos

    g_array = []
    g_counter = 0
    (fn loop ->
      if ((g_counter < this.length)) do
            v = Enum.at(this, g_counter)
        g_counter + 1
        if (not v.completed), do: g_array ++ [v], else: nil
        loop.()
      end
    end).()
    temp_array = g_array

    g_counter = 0
    (fn loop ->
      if ((g_counter < temp_array.length)) do
            todo = Enum.at(temp_array, g_counter)
        g_counter + 1
        updated_changeset = Todo.toggle_completed(todo)
        g_array = TodoApp.Repo.update(updated_changeset)
        case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          {0, __updated_todo} -> g_array = elem(g2_array, 1)
        nil
          {1, reason} -> g_array = elem(g2_array, 1)
        Log.trace("Failed to complete todo " <> to_string(todo.id) <> ": " <> Std.string(reason), %{fileName: "src_haxe/server/live/TodoLive.hx", lineNumber: 440, className: "server.live.TodoLive", methodName: "complete_all_todos"})
        end
        loop.()
      end
    end).()

    g_array = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.bulk_update(:complete_all))
    case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> nil
      {1, reason} -> g_array = elem(g_array, 1)
    Log.trace("Failed to broadcast bulk complete: " <> reason, %{fileName: "src_haxe/server/live/TodoLive.hx", lineNumber: 449, className: "server.live.TodoLive", methodName: "complete_all_todos"})
    end

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

    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    (fn loop ->
      if ((g_counter < this.length)) do
            v = Enum.at(this, g_counter)
        g_counter + 1
        if v.completed, do: g_array ++ [v], else: nil
        loop.()
      end
    end).()
    temp_array = g_array

    g_counter = 0
    (fn loop ->
      if ((g_counter < temp_array.length)) do
            todo = Enum.at(temp_array, g_counter)
        g_counter + 1
        TodoApp.Repo.delete(todo)
        loop.()
      end
    end).()

    TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.bulk_update(:delete_completed))

    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    (fn loop ->
      if ((g_counter < this.length)) do
            v = Enum.at(this, g_counter)
        g_counter + 1
        if (not v.completed), do: g_array ++ [v], else: nil
        loop.()
      end
    end).()
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
    else
      nil
    end

    changeset_params = TypeSafeConversions.event_params_to_changeset_params(params)

    _changeset = Todo.changeset(todo, changeset_params)

    g_array = TodoApp.Repo.update(_changeset)
    case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, updated_todo} -> g_array = elem(g_array, 1)
    g_array = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_updated(updated_todo))
    case (case g_array do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> nil
      {1, reason} -> g_array = elem(g3_array, 1)
    Log.trace("Failed to broadcast todo save: " <> reason, %{fileName: "src_haxe/server/live/TodoLive.hx", lineNumber: 514, className: "server.live.TodoLive", methodName: "save_edited_todo"})
    end
    updated_socket = TodoAppWeb.TodoLive.update_todo_in_list(updated_todo, socket)
    Phoenix.LiveView.assign(updated_socket, "editing_todo", nil)
      {1, reason} -> g_array = elem(g_array, 1)
    Phoenix.LiveView.put_flash(socket, :error, "Failed to save todo: " <> Std.string(reason))
    end
  end


  @doc "Generated from Haxe handle_bulk_update"
  def handle_bulk_update(action, socket) do
    temp_result = nil

    temp_result = nil

    case (case action do :complete_all -> 0; :delete_completed -> 1; :set_priority -> 2; :add_tag -> 3; :remove_tag -> 4; _ -> -1 end) do
      0 -> updated_todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
    temp_result = Phoenix.LiveView.assign(socket, complete_assigns)
      1 -> updated_todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
    temp_result = Phoenix.LiveView.assign(socket, complete_assigns)
      {2, __priority} -> g_array = elem(action, 1)
    temp_result = socket
      {3, __tag} -> g_array = elem(action, 1)
    temp_result = socket
      {4, __tag} -> g_array = elem(action, 1)
    temp_result = socket
    end

    temp_result
  end


  @doc "Generated from Haxe toggle_tag_filter"
  def toggle_tag_filter(tag, socket) do
    temp_array = nil

    selected_tags = socket.assigns.selected_tags

    if Enum.member?(selected_tags, tag) do
      g_array = []
      g_counter = 0
      g_array = selected_tags
      (fn loop ->
        if ((g_counter < g_array.length)) do
              v = Enum.at(g_array, g_counter)
          g_counter + 1
          if ((v != tag)), do: g_array ++ [v], else: nil
          loop.()
        end
      end).()
      temp_array = g_array
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
