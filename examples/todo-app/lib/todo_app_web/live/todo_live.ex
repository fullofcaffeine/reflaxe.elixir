defmodule TodoLive do
  use Phoenix.LiveView
  
  import Phoenix.LiveView.Helpers
  import Ecto.Query
  alias TodoApp.Repo
  
  use Phoenix.Component
  # Note: CoreComponents not imported - using default Phoenix components
  
  @impl true
  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    Phoenix.PubSub.subscribe(TodoApp.PubSub, "todo:updates")
    current_user = TodoLive.get_user_from_session(session)
    todos = TodoLive.load_todos(current_user.id)
    socket.assign(%{"todos" => todos, "filter" => "all", "sort_by" => "created", "current_user" => current_user, "editing_todo" => nil, "show_form" => false, "search_query" => "", "selected_tags" => [], "total_todos" => length(todos), "completed_todos" => TodoLive.count_completed(todos), "pending_todos" => TodoLive.count_pending(todos)})
  end

  @impl true
  @doc "Generated from Haxe handle_event"
  def handle_event(event, params, socket) do
    temp_result = nil
    case (event) do
      "bulk_complete" ->
        temp_result = TodoLive.complete_all_todos(socket)
      "bulk_delete_completed" ->
        temp_result = TodoLive.delete_completed_todos(socket)
      "cancel_edit" ->
        temp_result = socket.assign(%{"editing_todo" => nil})
      "create_todo" ->
        temp_result = TodoLive.create_new_todo(params, socket)
      "delete_todo" ->
        temp_result = TodoLive.delete_todo(params.id, socket)
      "edit_todo" ->
        temp_result = TodoLive.start_editing(params.id, socket)
      "filter_todos" ->
        temp_result = socket.assign(%{"filter" => params.filter})
      "save_todo" ->
        temp_result = TodoLive.save_edited_todo(params, socket)
      "search_todos" ->
        temp_result = socket.assign(%{"search_query" => params.query})
      "set_priority" ->
        temp_result = TodoLive.update_todo_priority(params.id, params.priority, socket)
      "sort_todos" ->
        temp_result = socket.assign(%{"sort_by" => params.sort_by})
      "toggle_form" ->
        temp_result = socket.assign(%{"show_form" => !socket.assigns.show_form})
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
    case (_g) do
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
    todo_params = %{"title" => params.title, "description" => params.description, "completed" => false, "priority" => temp_maybe_string, "due_date" => params.due_date, "tags" => TodoLive.parse_tags(params.tags), "user_id" => socket.assigns.current_user.id}
    changeset = Todo.changeset(Server.Schemas.Todo.new(), todo_params)
    result = Repo.insert(changeset)
    if (result.success) do
      todo = result.data
      Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_created", "todo" => todo})
      todos = [todo] ++ socket.assigns.todos
      socket.assign(%{"todos" => todos, "show_form" => false, "total_todos" => length(todos), "pending_todos" => socket.assigns.pending_todos + 1}).put_flash("info", "server.schemas.Todo created successfully!")
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
      todo = result.data
      Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_updated", "todo" => todo})
      TodoLive.update_todo_in_list(todo, socket)
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
      Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_deleted", "id" => id})
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
      todo = result.data
      Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_updated", "todo" => todo})
      TodoLive.update_todo_in_list(todo, socket)
    else
      socket.put_flash("error", "Failed to update priority")
    end
  end

  @doc "Generated from Haxe add_todo_to_list"
  def add_todo_to_list(todo, socket) do
    if (todo.user_id == socket.assigns.current_user.id), do: socket, else: nil
    todos = [todo] ++ socket.assigns.todos
    socket.assign(%{"todos" => todos, "total_todos" => length(todos), "pending_todos" => TodoLive.count_pending(todos), "completed_todos" => TodoLive.count_completed(todos)})
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
    socket.assign(%{"todos" => _g, "completed_todos" => TodoLive.count_completed(_g), "pending_todos" => TodoLive.count_pending(_g)})
  end

  @doc "Generated from Haxe remove_todo_from_list"
  def remove_todo_from_list(id, socket) do
    _this = socket.assigns.todos
    _g = []
    _g = 0
    Enum.filter(_this, fn item -> (item.id != id) end)
    socket.assign(%{"todos" => _g, "total_todos" => length(_g), "completed_todos" => TodoLive.count_completed(_g), "pending_todos" => TodoLive.count_pending(_g)})
  end

  @doc "Generated from Haxe load_todos"
  def load_todos(user_id) do
    query = Query.from(Todo)
    query = Query.where(query, %{"user_id" => user_id})
    query = Query.order_by(query, "inserted_at")
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
    %{"id" => 1, "name" => "Demo User", "email" => "demo@example.com"}
  end

  @doc "Generated from Haxe complete_all_todos"
  def complete_all_todos(socket) do
    temp_array = nil
    _this = socket.assigns.todos
    _g = []
    _g = 0
    Enum.filter(_this, fn item -> (!v.completed) end)
    temp_array = _g
    _g = 0
    Enum.map(temp_array, fn item -> todo = Enum.at(temp_array, _g)
    _g = _g + 1
    updated = Todo.toggle_completed(todo)
    Repo.update(updated) end)
    Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "bulk_update", "action" => "complete_all"})
    socket.assign(%{"todos" => TodoLive.load_todos(socket.assigns.current_user.id), "completed_todos" => socket.assigns.total_todos, "pending_todos" => 0}).put_flash("info", "All todos marked as completed!")
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
    Enum.filter(_this, fn item -> (!v.completed) end)
    temp_array1 = _g
    socket.assign(%{"todos" => temp_array1, "total_todos" => length(temp_array1), "completed_todos" => 0, "pending_todos" => length(temp_array1)}).put_flash("info", "Completed todos deleted!")
  end

  @doc "Generated from Haxe start_editing"
  def start_editing(id, socket) do
    todo = TodoLive.find_todo(id, socket.assigns.todos)
    socket.assign(%{"editing_todo" => todo})
  end

  @doc "Generated from Haxe save_edited_todo"
  def save_edited_todo(params, socket) do
    todo = socket.assigns.editing_todo
    if (todo == nil), do: socket, else: nil
    changeset = Todo.changeset(todo, params)
    result = Repo.update(changeset)
    if (result.success) do
      updated_todo = result.data
      Phoenix.PubSub.broadcast(TodoApp.PubSub, "todo:updates", %{"type" => "todo_updated", "todo" => updated_todo})
      TodoLive.update_todo_in_list(updated_todo, socket).assign(%{"editing_todo" => nil})
    else
      socket.put_flash("error", "Failed to save todo")
    end
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
    socket.assign(%{"selected_tags" => temp_array})
  end

end
