defmodule TodoLive do
  use Phoenix.LiveView
  
  import Phoenix.LiveView.Helpers
  import Ecto.Query
  alias TodoApp.Repo
  
  @impl true
  @doc "Generated from Haxe mount"
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(App.PubSub, "todo:updates")
    current_user2 = TodoLive.get_user_from_session(session)
    todos2 = TodoLive.load_todos(current_user2.id)
    socket.assign(%{todos: todos2, filter: "all", sort_by: "created", current_user: current_user2, editing_todo: nil, show_form: false, search_query: "", selected_tags: [], total_todos: length(todos2), completed_todos: TodoLive.count_completed(todos2), pending_todos: TodoLive.count_pending(todos2)})
  end

  @impl true
  @doc "Generated from Haxe handle_event"
  def handle_event(event, params, socket) do
    temp_result = nil
    case ((event)) do
      "bulk_complete" ->
        temp_result = TodoLive.complete_all_todos(socket)
      "bulk_delete_completed" ->
        temp_result = TodoLive.delete_completed_todos(socket)
      "cancel_edit" ->
        temp_result = socket.assign(%{editing_todo: nil})
      "create_todo" ->
        temp_result = TodoLive.create_new_todo(params, socket)
      "delete_todo" ->
        temp_result = TodoLive.delete_todo(params.id, socket)
      "edit_todo" ->
        temp_result = TodoLive.start_editing(params.id, socket)
      "filter_todos" ->
        temp_result = socket.assign(%{filter: params.filter})
      "save_todo" ->
        temp_result = TodoLive.save_edited_todo(params, socket)
      "search_todos" ->
        temp_result = socket.assign(%{search_query: params.query})
      "set_priority" ->
        temp_result = TodoLive.update_todo_priority(params.id, params.priority, socket)
      "sort_todos" ->
        temp_result = socket.assign(%{sort_by: params.sort_by})
      "toggle_form" ->
        temp_result = socket.assign(%{show_form: !socket.assigns.show_form})
      "toggle_tag" ->
        temp_result = TodoLive.toggle_tag_filter(params.tag, socket)
      "toggle_todo" ->
        temp_result = TodoLive.toggle_todo_status(params.id, socket)
      _ ->
        temp_result = socket
    end
    temp_result
  end

  @impl true
  @doc "Generated from Haxe handle_info"
  def handle_info(msg, socket) do
    temp_result = nil
    _g = msg.type
    case ((_g)) do
      "todo_created" ->
        temp_result = TodoLive.add_todo_to_list(msg.todo, socket)
      "todo_deleted" ->
        temp_result = TodoLive.remove_todo_from_list(msg.id, socket)
      "todo_updated" ->
        temp_result = TodoLive.update_todo_in_list(msg.todo, socket)
      _ ->
        temp_result = socket
    end
    temp_result
  end

  @doc "Generated from Haxe create_new_todo"
  def create_new_todo(params, socket) do
    temp_maybe_string = nil
    if (params.priority != nil), do: temp_maybe_string = params.priority, else: temp_maybe_string = "medium"
    todo_params = %{title: params.title, description: params.description, completed: false, priority: temp_maybe_string, due_date: params.due_date, tags: TodoLive.parse_tags(params.tags), user_id: socket.assigns.current_user.id}
    changeset = Todo.changeset(Schemas.Todo.new(), todo_params)
    result = Repo.insert(changeset)
    if (result.success) do
      todo = result.data
      Phoenix.PubSub.broadcast(App.PubSub, "todo:updates", %{type: "todo_created", todo: todo})
      todos2 = [todo] ++ socket.assigns.todos
      socket.assign(%{todos: todos2, show_form: false, total_todos: length(todos2), pending_todos: socket.assigns.pending_todos + 1}).put_flash("info", "Todo created successfully!")
    else
      socket.put_flash("error", "Failed to create todo")
    end
  end

  @doc "Generated from Haxe toggle_todo_status"
  def toggle_todo_status(id, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket, else: nil
    updated_todo = Todo.toggle_completed(todo)
    result = Repo.update(updated_todo)
    if (result.success) do
      todo2 = result.data
      Phoenix.PubSub.broadcast(App.PubSub, "todo:updates", %{type: "todo_updated", todo: todo2})
      TodoLive.update_todo_in_list(todo2, socket)
    else
      socket.put_flash("error", "Failed to update todo")
    end
  end

  @doc "Generated from Haxe delete_todo"
  def delete_todo(id, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket, else: nil
    result = Repo.delete(todo)
    if (result.success) do
      Phoenix.PubSub.broadcast(App.PubSub, "todo:updates", %{type: "todo_deleted", id: id})
      TodoLive.remove_todo_from_list(id, socket)
    else
      socket.put_flash("error", "Failed to delete todo")
    end
  end

  @doc "Generated from Haxe update_todo_priority"
  def update_todo_priority(id, priority, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket, else: nil
    updated_todo = Todo.update_priority(todo, priority)
    result = Repo.update(updated_todo)
    if (result.success) do
      todo2 = result.data
      Phoenix.PubSub.broadcast(App.PubSub, "todo:updates", %{type: "todo_updated", todo: todo2})
      TodoLive.update_todo_in_list(todo2, socket)
    else
      socket.put_flash("error", "Failed to update priority")
    end
  end

  @doc "Generated from Haxe add_todo_to_list"
  def add_todo_to_list(todo, socket) do
    if (todo.user_id == socket.assigns.current_user.id), do: socket, else: nil
    todos2 = [todo] ++ socket.assigns.todos
    socket.assign(%{todos: todos2, total_todos: length(todos2), pending_todos: TodoLive.count_pending(todos2), completed_todos: TodoLive.count_completed(todos2)})
  end

  @doc "Generated from Haxe update_todo_in_list"
  def update_todo_in_list(updated_todo, socket) do
    temp_array = nil
    _this = socket.assigns.todos
    _g = []
    _g1 = 0
    _g2 = _this
    (fn loop_fn ->
      if (_g1 < length(_g2)) do
        v = Enum.at(_g2, _g1)
    _g1 = _g1 + 1
    temp_todo = nil
    if (v.id == updated_todo.id), do: temp_todo = updated_todo, else: temp_todo = v
    _g ++ [temp_todo]
        loop_fn.(loop_fn)
      end
    end).(fn f -> f.(f) end)
    temp_array = _g
    todos2 = temp_array
    socket.assign(%{todos: todos2, completed_todos: TodoLive.count_completed(todos2), pending_todos: TodoLive.count_pending(todos2)})
  end

  @doc "Generated from Haxe remove_todo_from_list"
  def remove_todo_from_list(id, socket) do
    temp_array = nil
    _this = socket.assigns.todos
    _g = []
    _g1 = 0
    _g2 = _this
    (fn loop_fn ->
      if (_g1 < length(_g2)) do
        v = Enum.at(_g2, _g1)
    _g1 = _g1 + 1
    if (v.id != id), do: _g ++ [v], else: nil
        loop_fn.(loop_fn)
      end
    end).(fn f -> f.(f) end)
    temp_array = _g
    todos2 = temp_array
    socket.assign(%{todos: todos2, total_todos: length(todos2), completed_todos: TodoLive.count_completed(todos2), pending_todos: TodoLive.count_pending(todos2)})
  end

  @doc "Generated from Haxe load_todos"
  def load_todos(user_id) do
    query = Query.from(Todo)
    query = Query.where(query, %{user_id: user_id})
    query = Query.order_by(query, "inserted_at")
    Repo.all(query)
  end

  @doc "Generated from Haxe find_todo"
  def find_todo(id, todos) do
    _g = 0
    (fn loop_fn ->
      if (_g < length(todos)) do
        todo = Enum.at(todos, _g)
    _g = _g + 1
    if (todo.id == id), do: todo, else: nil
        loop_fn.(loop_fn)
      end
    end).(fn f -> f.(f) end)
    nil
  end

  @doc "Generated from Haxe count_completed"
  def count_completed(todos) do
    count = 0
    _g = 0
    (fn loop_fn ->
      if (_g < length(todos)) do
        todo = Enum.at(todos, _g)
    _g = _g + 1
    if (todo.completed), do: count = count + 1, else: nil
        loop_fn.(loop_fn)
      end
    end).(fn f -> f.(f) end)
    count
  end

  @doc "Generated from Haxe count_pending"
  def count_pending(todos) do
    count = 0
    _g = 0
    (fn loop_fn ->
      if (_g < length(todos)) do
        todo = Enum.at(todos, _g)
    _g = _g + 1
    if (!todo.completed), do: count = count + 1, else: nil
        loop_fn.(loop_fn)
      end
    end).(fn f -> f.(f) end)
    count
  end

  @doc "Generated from Haxe parse_tags"
  def parse_tags(tags_string) do
    if (tags_string == nil || tags_string == ""), do: [], else: nil
    temp_result = nil
    _this = String.split(tags_string, ",")
    _g = []
    _g1 = 0
    _g2 = _this
    (fn loop_fn ->
      if (_g1 < length(_g2)) do
        v = Enum.at(_g2, _g1)
    _g1 = _g1 + 1
    _g ++ [StringTools.trim(v)]
        loop_fn.(loop_fn)
      end
    end).(fn f -> f.(f) end)
    temp_result = _g
    temp_result
  end

  @doc "Generated from Haxe get_user_from_session"
  def get_user_from_session(session) do
    %{id: 1, name: "Demo User", email: "demo@example.com"}
  end

  @doc "Generated from Haxe complete_all_todos"
  def complete_all_todos(socket) do
    temp_array = nil
    _this = socket.assigns.todos
    _g = []
    _g1 = 0
    _g2 = _this
    (fn loop_fn ->
      if (_g1 < length(_g2)) do
        v = Enum.at(_g2, _g1)
    _g1 = _g1 + 1
    if (!v.completed), do: _g ++ [v], else: nil
        loop_fn.(loop_fn)
      end
    end).(fn f -> f.(f) end)
    temp_array = _g
    pending = temp_array
    _g = 0
    (fn loop_fn ->
      if (_g < length(pending)) do
        todo = Enum.at(pending, _g)
    _g = _g + 1
    updated = Todo.toggle_completed(todo)
    Repo.update(updated)
        loop_fn.(loop_fn)
      end
    end).(fn f -> f.(f) end)
    Phoenix.PubSub.broadcast(App.PubSub, "todo:updates", %{type: "bulk_update", action: "complete_all"})
    socket.assign(%{todos: TodoLive.load_todos(socket.assigns.current_user.id), completed_todos: socket.assigns.total_todos, pending_todos: 0}).put_flash("info", "All todos marked as completed!")
  end

  @doc "Generated from Haxe delete_completed_todos"
  def delete_completed_todos(socket) do
    temp_array = nil
    _this = socket.assigns.todos
    _g = []
    _g1 = 0
    _g2 = _this
    (fn loop_fn ->
      if (_g1 < length(_g2)) do
        v = Enum.at(_g2, _g1)
    _g1 = _g1 + 1
    if (v.completed), do: _g ++ [v], else: nil
        loop_fn.(loop_fn)
      end
    end).(fn f -> f.(f) end)
    temp_array = _g
    completed = temp_array
    _g = 0
    (fn loop_fn ->
      if (_g < length(completed)) do
        todo = Enum.at(completed, _g)
    _g = _g + 1
    Repo.delete(todo)
        loop_fn.(loop_fn)
      end
    end).(fn f -> f.(f) end)
    Phoenix.PubSub.broadcast(App.PubSub, "todo:updates", %{type: "bulk_delete", action: "delete_completed"})
    temp_array1 = nil
    _this = socket.assigns.todos
    _g = []
    _g1 = 0
    _g2 = _this
    (fn loop_fn ->
      if (_g1 < length(_g2)) do
        v = Enum.at(_g2, _g1)
    _g1 = _g1 + 1
    if (!v.completed), do: _g ++ [v], else: nil
        loop_fn.(loop_fn)
      end
    end).(fn f -> f.(f) end)
    temp_array1 = _g
    remaining = temp_array1
    socket.assign(%{todos: remaining, total_todos: length(remaining), completed_todos: 0, pending_todos: length(remaining)}).put_flash("info", "Completed todos deleted!")
  end

  @doc "Generated from Haxe start_editing"
  def start_editing(id, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    socket.assign(%{editing_todo: todo})
  end

  @doc "Generated from Haxe save_edited_todo"
  def save_edited_todo(params, socket) do
    todo = socket.assigns.editing_todo
    if (todo == nil), do: socket, else: nil
    changeset = Todo.changeset(todo, params)
    result = Repo.update(changeset)
    if (result.success) do
      updated_todo = result.data
      Phoenix.PubSub.broadcast(App.PubSub, "todo:updates", %{type: "todo_updated", todo: updated_todo})
      TodoLive.update_todo_in_list(updated_todo, socket).assign(%{editing_todo: nil})
    else
      socket.put_flash("error", "Failed to save todo")
    end
  end

  @doc "Generated from Haxe toggle_tag_filter"
  def toggle_tag_filter(tag, socket) do
    selected_tags2 = socket.assigns.selected_tags
    temp_array = nil
    if (Enum.member?(selected_tags2, tag)) do
      _g = []
      _g1 = 0
      _g2 = selected_tags2
      (fn loop_fn ->
        if (_g1 < length(_g2)) do
          v = Enum.at(_g2, _g1)
      _g1 = _g1 + 1
      if (v != tag), do: _g ++ [v], else: nil
          loop_fn.(loop_fn)
        end
      end).(fn f -> f.(f) end)
      temp_array = _g
    else
      temp_array = selected_tags2 ++ [tag]
    end
    updated_tags = temp_array
    socket.assign(%{selected_tags: updated_tags})
  end

end
