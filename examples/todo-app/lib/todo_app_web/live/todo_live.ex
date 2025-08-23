defmodule TodoLive do
  use AppWeb, :live_view

  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    (
          g = TodoPubSub.subscribe(:todo_updates)
          case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      1 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          reason = g_counter
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
    case (event) do
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
    temp_socket = nil
    (
          g = TodoPubSub.parse_message(msg)
          case (case g_counter do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 -> (
          g = case g_counter do {:ok, value} -> value; :error -> nil; _ -> nil end
          parsed_msg = g_counter
          case (elem(parsed_msg, 0)) do
      0 -> (
          g = elem(parsed_msg, 1)
          (
          todo = g_counter
          temp_socket = TodoLive.add_todo_to_list(todo, socket)
        )
        )
      1 -> (
          g = elem(parsed_msg, 1)
          (
          todo = g_counter
          temp_socket = TodoLive.update_todo_in_list(todo, socket)
        )
        )
      2 -> (
          g = elem(parsed_msg, 1)
          id = g_counter
          temp_socket = TodoLive.remove_todo_from_list(id, socket)
        )
      3 -> (
          g = elem(parsed_msg, 1)
          action = g_counter
          temp_socket = TodoLive.handle_bulk_update(action, socket)
        )
      4 -> (
          elem(parsed_msg, 1)
          (
          g_counter
          temp_socket = socket
        )
        )
      5 -> (
          elem(parsed_msg, 1)
          (
          g_counter
          temp_socket = socket
        )
        )
      6 -> g = elem(parsed_msg, 1)
    g = elem(parsed_msg, 2)
    message = g_counter
    level = g_counter
    temp_flash_type = nil
    case (elem(level, 0)) do
      0 -> temp_flash_type = :info
      1 -> temp_flash_type = :warning
      2 -> temp_flash_type = :error
      3 -> temp_flash_type = :error
    end
    flash_type = temp_flash_type
    temp_socket = LiveView.put_flash(socket, flash_type, message)
    end
        )
      1 -> (
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
          case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    todo = g_counter
    (
          g = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_created(todo))
          case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      1 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          (
          reason = g_counter
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
      1 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          (
          reason = g_counter
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
          case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          updated_todo = g_counter
          (
          g = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_updated(updated_todo))
          case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      1 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          (
          reason = g_counter
          Log.trace("Failed to broadcast todo update: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 267, "className" => "server.live.TodoLive", "methodName" => "toggle_todo_status"})
        )
        )
    end
        )
          TodoLive.update_todo_in_list(updated_todo, socket)
        )
      1 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          (
          reason = g_counter
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
          case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> (
          case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          g_counter
          (
          g = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_deleted", "id" => id})
          case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      1 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          (
          reason = g_counter
          Log.trace("Failed to broadcast todo deletion: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 292, "className" => "server.live.TodoLive", "methodName" => "delete_todo"})
        )
        )
    end
        )
          TodoLive.remove_todo_from_list(id, socket)
        )
      1 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          (
          reason = g_counter
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
          case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          updated_todo = g_counter
          (
          g = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_updated", "todo" => updated_todo})
          case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      1 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          (
          reason = g_counter
          Log.trace("Failed to broadcast todo priority update: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 319, "className" => "server.live.TodoLive", "methodName" => "update_todo_priority"})
        )
        )
    end
        )
          TodoLive.update_todo_in_list(updated_todo, socket)
        )
      1 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          (
          reason = g_counter
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
    loop_helper = fn loop_fn, {v, g1, temp_todo} ->
      if ((g_counter < this.length)) do
        v = Enum.at(this, g_counter)
        g1 = g1 + 1
        temp_todo = nil
        if ((v.id == updated_todo.id)) do
              temp_todo = updated_todo
            else
              temp_todo = v
            end
        g_counter ++ [temp_todo]
        loop_fn.(loop_fn, {v, g1, temp_todo})
      else
        {v, g1, temp_todo}
      end
    end

    {v, g1, temp_todo} = loop_helper.(loop_helper, {v, g1, temp_todo})
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, g_counter)
    LiveView.assign_multiple(socket, complete_assigns)
  end


  @doc "Generated from Haxe remove_todo_from_list"
  def remove_todo_from_list(id, socket) do
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    loop_helper = fn loop_fn, {v, g1} ->
      if ((g_counter < this.length)) do
        v = Enum.at(this, g_counter)
        g1 = g1 + 1
        if ((v.id != id)) do
              g_counter ++ [v]
            end
        loop_fn.(loop_fn, {v, g1})
      else
        {v, g1}
      end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, g_counter)
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
    loop_helper = fn loop_fn, {todo, g} ->
      if ((g_counter < todos.length)) do
        todo = Enum.at(todos, g_counter)
        g = g + 1
        if ((todo.id == id)) do
              todo
            end
        loop_fn.(loop_fn, {todo, g})
      else
        {todo, g}
      end
    end

    {todo, g} = loop_helper.(loop_helper, {todo, g})
    nil
  end


  @doc "Generated from Haxe count_completed"
  def count_completed(todos) do
    count = 0
    g_counter = 0
    loop_helper = fn loop_fn, {todo, g, count} ->
      if ((g_counter < todos.length)) do
        todo = Enum.at(todos, g_counter)
        g = g + 1
        if (todo.completed) do
              count + 1
            end
        loop_fn.(loop_fn, {todo, g, count})
      else
        {todo, g, count}
      end
    end

    {todo, g, count} = loop_helper.(loop_helper, {todo, g, count})
    count
  end


  @doc "Generated from Haxe count_pending"
  def count_pending(todos) do
    count = 0
    g_counter = 0
    loop_helper = fn loop_fn, {todo, g, count} ->
      if ((g_counter < todos.length)) do
        todo = Enum.at(todos, g_counter)
        g = g + 1
        if (not todo.completed) do
              count + 1
            end
        loop_fn.(loop_fn, {todo, g, count})
      else
        {todo, g, count}
      end
    end

    {todo, g, count} = loop_helper.(loop_helper, {todo, g, count})
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
    loop_helper = fn loop_fn, {v, g1} ->
      if ((g_counter < this.length)) do
        v = Enum.at(this, g_counter)
        g1 = g1 + 1
        g_counter ++ [StringTools.trim(v)]
        loop_fn.(loop_fn, {v, g1})
      else
        {v, g1}
      end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
    g_counter
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
    temp_array = nil
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    loop_helper = fn loop_fn, {v, g1} ->
      if ((g_counter < this.length)) do
        v = Enum.at(this, g_counter)
        g1 = g1 + 1
        if (not v.completed) do
              g_counter ++ [v]
            end
        loop_fn.(loop_fn, {v, g1})
      else
        {v, g1}
      end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
    temp_array = g_counter
    g_counter = 0
    loop_helper = fn loop_fn, {todo, g, updated_changeset} ->
      if ((g_counter < temp_array.length)) do
        todo = Enum.at(temp_array, g_counter)
        g = g + 1
        updated_changeset = Todo.toggle_completed(todo)
        (
              g = Repo.update(updated_changeset)
              case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 -> (
              case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
              (
              g_counter
              nil
            )
            )
          1 -> (
              g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
              (
              reason = g_counter
              Log.trace("Failed to complete todo " <> to_string(todo.id) <> ": " <> Std.string(reason), %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 446, "className" => "server.live.TodoLive", "methodName" => "complete_all_todos"})
            )
            )
        end
            )
        loop_fn.(loop_fn, {todo, g, updated_changeset})
      else
        {todo, g, updated_changeset}
      end
    end

    {todo, g, updated_changeset} = loop_helper.(loop_helper, {todo, g, updated_changeset})
    (
          g = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "bulk_update", "action" => "complete_all"})
          case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      1 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          (
          reason = g_counter
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
    temp_array = nil
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    loop_helper = fn loop_fn, {v, g1} ->
      if ((g_counter < this.length)) do
        v = Enum.at(this, g_counter)
        g1 = g1 + 1
        if (v.completed) do
              g_counter ++ [v]
            end
        loop_fn.(loop_fn, {v, g1})
      else
        {v, g1}
      end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
    temp_array = g_counter
    g_counter = 0
    loop_helper = fn loop_fn, {todo, g} ->
      if ((g_counter < temp_array.length)) do
        todo = Enum.at(temp_array, g_counter)
        g = g + 1
        Repo.delete(todo)
        loop_fn.(loop_fn, {todo, g})
      else
        {todo, g}
      end
    end

    {todo, g} = loop_helper.(loop_helper, {todo, g})
    Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "bulk_delete", "action" => "delete_completed"})
    temp_array1 = nil
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    loop_helper = fn loop_fn, {v, g1} ->
      if ((g_counter < this.length)) do
        v = Enum.at(this, g_counter)
        g1 = g1 + 1
        if (not v.completed) do
              g_counter ++ [v]
            end
        loop_fn.(loop_fn, {v, g1})
      else
        {v, g1}
      end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
    temp_array1 = g_counter
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
          case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          updated_todo = g_counter
          (
          g = TodoPubSub.broadcast(:todo_updates, TodoPubSubMessage.todo_updated(updated_todo))
          case (case g_counter do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      1 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          (
          reason = g_counter
          Log.trace("Failed to broadcast todo save: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 526, "className" => "server.live.TodoLive", "methodName" => "save_edited_todo"})
        )
        )
    end
        )
          updated_socket = TodoLive.update_todo_in_list(updated_todo, socket)
          LiveView.assign(updated_socket, "editing_todo", nil)
        )
      1 -> (
          g = case g_counter do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          (
          reason = g_counter
          LiveView.put_flash(socket, :error, "Failed to save todo: " <> Std.string(reason))
        )
        )
    end
        )
  end


  @doc "Generated from Haxe handle_bulk_update"
  def handle_bulk_update(action, socket) do
    temp_result = nil
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
      2 -> (
          elem(action, 1)
          g_counter
          temp_result = socket
        )
      3 -> (
          elem(action, 1)
          (
          g_counter
          temp_result = socket
        )
        )
      4 -> (
          elem(action, 1)
          (
          g_counter
          temp_result = socket
        )
        )
    end
    temp_result
  end


  @doc "Generated from Haxe toggle_tag_filter"
  def toggle_tag_filter(tag, socket) do
    selected_tags = socket.assigns.selected_tags
    temp_array = nil
    if (Enum.member?(selected_tags, tag)) do
          (
          g_array = []
          g_counter = 0
          g = selected_tags
          loop_helper = fn loop_fn, {v, g1} ->
      if ((g_counter < g_counter.length)) do
        v = Enum.at(g_counter, g_counter)
        g1 = g1 + 1
        if ((v != tag)) do
              g_counter ++ [v]
            end
        loop_fn.(loop_fn, {v, g1})
      else
        {v, g1}
      end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
          temp_array = g_counter
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
