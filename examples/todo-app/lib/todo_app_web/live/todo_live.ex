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
    g = TodoPubSub.subscribe(:todo_updates)
    case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      1 ->
        g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = g
        {:error, "Failed to subscribe to updates: " <> reason}
    end
    current_user = TodoLive.get_user_from_session(session)
    todos = TodoLive.load_todos(current_user.id)
    assigns = %{"todos" => todos, "filter" => "all", "sort_by" => "created", "current_user" => current_user, "editing_todo" => nil, "show_form" => false, "search_query" => "", "selected_tags" => [], "total_todos" => todos.length, "completed_todos" => TodoLive.count_completed(todos), "pending_todos" => TodoLive.count_pending(todos)}
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
        temp_socket = SafeAssigns.set_editing_todo(socket, nil)
      "create_todo" ->
        temp_socket = TodoLive.create_new_todo(params, socket)
      "delete_todo" ->
        temp_socket = TodoLive.delete_todo(params.id, socket)
      "edit_todo" ->
        temp_socket = TodoLive.start_editing(params.id, socket)
      "filter_todos" ->
        temp_socket = SafeAssigns.set_filter(socket, params.filter)
      "save_todo" ->
        temp_socket = TodoLive.save_edited_todo(params, socket)
      "search_todos" ->
        temp_socket = SafeAssigns.set_search_query(socket, params.query)
      "set_priority" ->
        temp_socket = TodoLive.update_todo_priority(params.id, params.priority, socket)
      "sort_todos" ->
        temp_socket = SafeAssigns.set_sort_by(socket, params.sort_by)
      "toggle_form" ->
        temp_socket = SafeAssigns.set_show_form(socket, !socket.assigns.show_form)
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
    g = TodoPubSub.parse_message(msg)
    case (case g do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 ->
        g = case g do {:ok, value} -> value; :error -> nil; _ -> nil end
        parsed_msg = g
        case (elem(parsed_msg, 0)) do
          0 ->
            g = elem(parsed_msg, 1)
            todo = g
            temp_socket = TodoLive.add_todo_to_list(todo, socket)
          1 ->
            g = elem(parsed_msg, 1)
            todo = g
            temp_socket = TodoLive.update_todo_in_list(todo, socket)
          2 ->
            g = elem(parsed_msg, 1)
            id = g
            temp_socket = TodoLive.remove_todo_from_list(id, socket)
          3 ->
            g = elem(parsed_msg, 1)
            action = g
            temp_socket = TodoLive.handle_bulk_update(action, socket)
          4 ->
            elem(parsed_msg, 1)
            temp_socket = socket
          5 ->
            elem(parsed_msg, 1)
            temp_socket = socket
          6 ->
            _g_1 = elem(parsed_msg, 1)
            _g_1 = elem(parsed_msg, 2)
            message = _g_1
            level = _g_1
            tempFlashType = nil
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
    changeset_params = TypeSafeConversions.event_params_to_changeset_params(params)
    changeset = Todo.changeset(Server.Schemas.Todo.new(), changeset_params)
    g = Repo.insert(changeset)
    case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        todo = g
        g = TodoPubSub.broadcast(:todo_updates, {:todo_created, todo})
        case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          1 ->
            g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = g
            Log.trace("Failed to broadcast todo creation: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 228, "className" => "server.live.TodoLive", "methodName" => "create_new_todo"})
        end
        todos = [todo] ++ socket.assigns.todos
        current_assigns = socket.assigns
        complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, todos, nil, nil, nil, nil, false, nil, nil)
        updated_socket = LiveView.assign_multiple(socket, complete_assigns)
        LiveView.put_flash(updated_socket, :success, "Todo created successfully!")
      1 ->
        g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = g
        LiveView.put_flash(socket, :error, "Failed to create todo: " <> Std.string(reason))
    end
  end

  @doc "Generated from Haxe toggle_todo_status"
  def toggle_todo_status(id, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket, else: nil
    updated_changeset = Todo.toggle_completed(todo)
    g = Repo.update(updated_changeset)
    case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        updated_todo = g
        g = TodoPubSub.broadcast(:todo_updates, {:todo_updated, updated_todo})
        case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          1 ->
            g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = g
            Log.trace("Failed to broadcast todo update: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 267, "className" => "server.live.TodoLive", "methodName" => "toggle_todo_status"})
        end
        TodoLive.update_todo_in_list(updated_todo, socket)
      1 ->
        g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = g
        LiveView.put_flash(socket, :error, "Failed to update todo: " <> Std.string(reason))
    end
  end

  @doc "Generated from Haxe delete_todo"
  def delete_todo(id, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket, else: nil
    g = Repo.delete(todo)
    case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        g
        g = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_deleted", "id" => id})
        case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          1 ->
            g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = g
            Log.trace("Failed to broadcast todo deletion: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 292, "className" => "server.live.TodoLive", "methodName" => "delete_todo"})
        end
        TodoLive.remove_todo_from_list(id, socket)
      1 ->
        g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = g
        LiveView.put_flash(socket, :error, "Failed to delete todo: " <> Std.string(reason))
    end
  end

  @doc "Generated from Haxe update_todo_priority"
  def update_todo_priority(id, priority, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket, else: nil
    updated_changeset = Todo.update_priority(todo, priority)
    g = Repo.update(updated_changeset)
    case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        updated_todo = g
        g = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_updated", "todo" => updated_todo})
        case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          1 ->
            g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = g
            Log.trace("Failed to broadcast todo priority update: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 319, "className" => "server.live.TodoLive", "methodName" => "update_todo_priority"})
        end
        TodoLive.update_todo_in_list(updated_todo, socket)
      1 ->
        g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = g
        LiveView.put_flash(socket, :error, "Failed to update priority: " <> Std.string(reason))
    end
  end

  @doc "Generated from Haxe add_todo_to_list"
  def add_todo_to_list(todo, socket) do
    if (todo.user_id == socket.assigns.current_user.id), do: socket, else: nil
    todos = [todo] ++ socket.assigns.todos
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, todos)
    LiveView.assign_multiple(socket, complete_assigns)
  end

  @doc "Generated from Haxe update_todo_in_list"
  def update_todo_in_list(updated_todo, socket) do
    this = socket.assigns.todos
    _g_array = []
    _g_counter = 0
    (
      loop_helper = fn loop_fn, {g_counter, temp_todo} ->
        if (g < this.length) do
          try do
            v = Enum.at(this, g)
    g = g + 1
    tempTodo = nil
    if (v.id == updated_todo.id), do: temp_todo = updated_todo, else: temp_todo = v
    _g_counter.push(temp_todo)
            loop_fn.(loop_fn, {g_counter, temp_todo})
          catch
            :break -> {g_counter, temp_todo}
            :continue -> loop_fn.(loop_fn, {g_counter, temp_todo})
          end
        else
          {g_counter, temp_todo}
        end
      end
      {g_counter, temp_todo} = try do
        loop_helper.(loop_helper, {nil, nil})
      catch
        :break -> {nil, nil}
      end
    )
    currentAssigns = socket.assigns
    completeAssigns = TypeSafeConversions.createCompleteAssigns(current_assigns, _g_counter)
    LiveView.assign_multiple(socket, complete_assigns)
  end

  @doc "Generated from Haxe remove_todo_from_list"
  def remove_todo_from_list(id, socket) do
    this = socket.assigns.todos
    _g_array = []
    _g_counter = 0
    (
      loop_helper = fn loop_fn, {g_counter} ->
        if (g < this.length) do
          try do
            v = Enum.at(this, g)
    g = g + 1
    if (v.id != id), do: _g_counter.push(v), else: nil
            loop_fn.(loop_fn, {g_counter})
          catch
            :break -> {g_counter}
            :continue -> loop_fn.(loop_fn, {g_counter})
          end
        else
          {g_counter}
        end
      end
      {g_counter} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    currentAssigns = socket.assigns
    completeAssigns = TypeSafeConversions.createCompleteAssigns(current_assigns, _g_counter)
    LiveView.assign_multiple(socket, complete_assigns)
  end

  @doc "Generated from Haxe load_todos"
  def load_todos(user_id) do
    query = Query.from(Todo, "t")
    where_conditions = %{}
    value = {:integer, user_id}
    Map.put(where_conditions, "user_id", value)
    conditions = %{"where" => where_conditions}
    query = Query.where(query, conditions)
    Repo.all(query)
  end

  @doc "Generated from Haxe find_todo"
  def find_todo(id, todos) do
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < todos.length) do
          try do
            todo = Enum.at(todos, g)
          g = g + 1
          if (todo.id == id), do: todo, else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    nil
  end

  @doc "Generated from Haxe count_completed"
  def count_completed(todos) do
    count = 0
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g, count} ->
        if (g < todos.length) do
          try do
            todo = Enum.at(todos, g)
          g = g + 1
          if (todo.completed), do: count = count + 1, else: nil
          loop_fn.({g + 1, count})
            loop_fn.(loop_fn, {g, count})
          catch
            :break -> {g, count}
            :continue -> loop_fn.(loop_fn, {g, count})
          end
        else
          {g, count}
        end
      end
      {g, count} = try do
        loop_helper.(loop_helper, {nil, nil})
      catch
        :break -> {nil, nil}
      end
    )
    count
  end

  @doc "Generated from Haxe count_pending"
  def count_pending(todos) do
    count = 0
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g, count} ->
        if (g < todos.length) do
          try do
            todo = Enum.at(todos, g)
          g = g + 1
          if (!todo.completed), do: count = count + 1, else: nil
          loop_fn.({g + 1, count})
            loop_fn.(loop_fn, {g, count})
          catch
            :break -> {g, count}
            :continue -> loop_fn.(loop_fn, {g, count})
          end
        else
          {g, count}
        end
      end
      {g, count} = try do
        loop_helper.(loop_helper, {nil, nil})
      catch
        :break -> {nil, nil}
      end
    )
    count
  end

  @doc "Generated from Haxe parse_tags"
  def parse_tags(tags_string) do
    if (tags_string == nil || tags_string == ""), do: [], else: nil
    this = String.split(tags_string, ",")
    _g_array = []
    _g_counter = 0
    (
      loop_helper = fn loop_fn, {g_counter} ->
        if (g < this.length) do
          try do
            v = Enum.at(this, g)
    g = g + 1
    _g_counter.push(StringTools.trim(v))
            loop_fn.(loop_fn, {g_counter})
          catch
            :break -> {g_counter}
            :continue -> loop_fn.(loop_fn, {g_counter})
          end
        else
          {g_counter}
        end
      end
      {g_counter} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    g
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
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < this.length) do
          try do
            v = Enum.at(this, g)
          g = g + 1
          if (!v.completed), do: g ++ [v], else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array = g
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < temp_array.length) do
          try do
            todo = Enum.at(temp_array, g)
          g = g + 1
          updated_changeset = Todo.toggle_completed(todo)
          g = Repo.update(updated_changeset)
    case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        g
        nil
      1 ->
        g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = g
        Log.trace("Failed to complete todo " <> Integer.to_string(todo.id) <> ": " <> Std.string(reason), %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 446, "className" => "server.live.TodoLive", "methodName" => "complete_all_todos"})
    end
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    g = Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "bulk_update", "action" => "complete_all"})
    case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      1 ->
        g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = g
        Log.trace("Failed to broadcast bulk complete: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 458, "className" => "server.live.TodoLive", "methodName" => "complete_all_todos"})
    end
    updated_todos = TodoLive.load_todos(socket.assigns.current_user.id)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
    complete_assigns = %{complete_assigns | completed_todos: complete_assigns.total_todos}
    complete_assigns = %{complete_assigns | pending_todos: 0}
    updated_socket = LiveView.assign_multiple(socket, complete_assigns)
    LiveView.put_flash(updated_socket, :info, "All todos marked as completed!")
  end

  @doc "Generated from Haxe delete_completed_todos"
  def delete_completed_todos(socket) do
    temp_array = nil
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < this.length) do
          try do
            v = Enum.at(this, g)
          g = g + 1
          if (v.completed), do: g ++ [v], else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array = g
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < temp_array.length) do
          try do
            todo = Enum.at(temp_array, g)
          g = g + 1
          Repo.delete(todo)
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "bulk_delete", "action" => "delete_completed"})
    temp_array1 = nil
    this = socket.assigns.todos
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < this.length) do
          try do
            v = Enum.at(this, g)
          g = g + 1
          if (!v.completed), do: g ++ [v], else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array1 = g
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, temp_array1)
    complete_assigns = %{complete_assigns | completed_todos: 0}
    complete_assigns = %{complete_assigns | pending_todos: temp_array1.length}
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
    if (todo == nil), do: socket, else: nil
    changeset_params = TypeSafeConversions.event_params_to_changeset_params(params)
    changeset = Todo.changeset(todo, changeset_params)
    g = Repo.update(changeset)
    case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        updated_todo = g
        g = TodoPubSub.broadcast(:todo_updates, {:todo_updated, updated_todo})
        case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          1 ->
            g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = g
            Log.trace("Failed to broadcast todo save: " <> reason, %{"fileName" => "src_haxe/server/live/TodoLive.hx", "lineNumber" => 526, "className" => "server.live.TodoLive", "methodName" => "save_edited_todo"})
        end
        updated_socket = TodoLive.update_todo_in_list(updated_todo, socket)
        LiveView.assign(updated_socket, "editing_todo", nil)
      1 ->
        g = case g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = g
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
        complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
        temp_result = LiveView.assign_multiple(socket, complete_assigns)
      1 ->
        updated_todos = TodoLive.load_todos(socket.assigns.current_user.id)
        current_assigns = socket.assigns
        complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
        temp_result = LiveView.assign_multiple(socket, complete_assigns)
      2 ->
        elem(action, 1)
        temp_result = socket
      3 ->
        elem(action, 1)
        temp_result = socket
      4 ->
        elem(action, 1)
        temp_result = socket
    end
    temp_result
  end

  @doc "Generated from Haxe toggle_tag_filter"
  def toggle_tag_filter(tag, socket) do
    selected_tags = socket.assigns.selected_tags
    temp_array = nil
    if (Enum.member?(selected_tags, tag)) do
      _g_array = []
      _g_counter = 0
      _g_2 = selected_tags
      (
        loop_helper = fn loop_fn, {g_2} ->
          if (g < g.length) do
            try do
              v = Enum.at(g, g)
      g = g + 1
      if (v != tag), do: _g_2.push(v), else: nil
              loop_fn.(loop_fn, {g_2})
            catch
              :break -> {g_2}
              :continue -> loop_fn.(loop_fn, {g_2})
            end
          else
            {g_2}
          end
        end
        {g_2} = try do
          loop_helper.(loop_helper, {nil})
        catch
          :break -> {nil}
        end
      )
      temp_array = _g_2
    else
      temp_array = selected_tags ++ [tag]
    end
    SafeAssigns.set_selected_tags(socket, temp_array)
  end

end
