defmodule TodoAppWeb.TodoLive do
  def mount(_params, session, socket) do
    now = DateTime.utc_now()
    Log.trace("Current time: " <> DateTime.to_iso8601(now), %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 109, :class_name => "server.live.TodoLive", :method_name => "mount"})
    g = TodoPubSub.subscribe({:todo_updates})
    case (g) do
      {:ok, value} ->
        nil
      {:error, reason} ->
        reason = g2
        {:error, "Failed to subscribe to updates: " <> reason}
    end
    current_user = TodoAppWeb.TodoLive.get_user_from_session(session)
    todos = TodoAppWeb.TodoLive.load_todos(current_user.id)
    presence_socket = TodoAppWeb.Presence.track_user(socket, current_user)
    assigns = %{:todos => todos, :filter => "all", :sort_by => "created", :current_user => current_user, :editing_todo => nil, :show_form => false, :search_query => "", :selected_tags => [], :total_todos => length(todos), :completed_todos => TodoAppWeb.TodoLive.count_completed(todos), :pending_todos => TodoAppWeb.TodoLive.count_pending(todos), :online_users => %{}}
    updated_socket = assign(presence_socket, assigns)
    {:ok, updated_socket}
  end
  def handle_event(event, socket) do
    temp_socket = nil
    case (event) do
      {:create_todo, params} ->
        params = g
        temp_socket = TodoAppWeb.TodoLive.create_todo_typed(params, socket)
      {:toggle_todo, id} ->
        id = g
        temp_socket = TodoAppWeb.TodoLive.toggle_todo_status(id, socket)
      {:delete_todo, id} ->
        id = g
        temp_socket = TodoAppWeb.TodoLive.delete_todo(id, socket)
      {:edit_todo, id} ->
        id = g
        temp_socket = TodoAppWeb.TodoLive.start_editing(id, socket)
      {:save_todo, params} ->
        params = g
        temp_socket = TodoAppWeb.TodoLive.save_edited_todo_typed(params, socket)
      {:cancel_edit} ->
        presence_socket = TodoAppWeb.Presence.update_user_editing(socket, socket.assigns.current_user, nil)
        temp_socket = SafeAssigns.set_editing_todo(presence_socket, nil)
      {:filter_todos, filter} ->
        filter = g
        temp_socket = SafeAssigns.set_filter(socket, filter)
      {:sort_todos, sort_by} ->
        sort_by = g
        temp_socket = SafeAssigns.set_sort_by(socket, sort_by)
      {:search_todos, query} ->
        query = g
        temp_socket = SafeAssigns.set_search_query(socket, query)
      {:toggle_tag, tag} ->
        tag = g
        temp_socket = TodoAppWeb.TodoLive.toggle_tag_filter(tag, socket)
      {:set_priority, id, priority} ->
        id = g
        priority = g1
        temp_socket = TodoAppWeb.TodoLive.update_todo_priority(id, priority, socket)
      {:toggle_form} ->
        temp_socket = SafeAssigns.set_show_form(socket, not socket.assigns.show_form)
      {:bulk_complete} ->
        temp_socket = TodoAppWeb.TodoLive.complete_all_todos(socket)
      {:bulk_delete_completed} ->
        temp_socket = TodoAppWeb.TodoLive.delete_completed_todos(socket)
    end
    {:no_reply, temp_socket}
  end
  def handle_info(msg, socket) do
    temp_socket = nil
    g = TodoPubSub.parse_message(msg)
    case (g) do
      {:some, parsed_msg} ->
        parsed_msg = g2
        case (parsed_msg) do
          {:todo_created, todo} ->
            g3 = parsed_msg
            todo = g3
            temp_socket = TodoAppWeb.TodoLive.add_todo_to_list(todo, socket)
          {:todo_updated, todo} ->
            g3 = parsed_msg
            todo = g3
            temp_socket = TodoAppWeb.TodoLive.update_todo_in_list(todo, socket)
          {:todo_deleted, id} ->
            id = g3
            temp_socket = TodoAppWeb.TodoLive.remove_todo_from_list(id, socket)
          {:bulk_update, action} ->
            action = g3
            temp_socket = TodoAppWeb.TodoLive.handle_bulk_update(action, socket)
          {:user_online, user_id} ->
            g3 = parsed_msg
            user_id = g3
            temp_socket = socket
          {:user_offline, user_id} ->
            g3 = parsed_msg
            user_id = g3
            temp_socket = socket
          {:system_alert, message, level} ->
            message = g3
            level = g1
            temp_flash_type = nil
            case (level) do
              {:info} ->
                temp_flash_type = {:info}
              {:warning} ->
                temp_flash_type = {:warning}
              {:error} ->
                temp_flash_type = {:error}
              {:critical} ->
                temp_flash_type = {:error}
            end
            flash_type = temp_flash_type
            temp_socket = Phoenix.LiveView.put_flash(socket, flash_type, message)
        end
      {:none} ->
        Log.trace("Received unknown PubSub message: " <> Std.string(msg), %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 254, :class_name => "server.live.TodoLive", :method_name => "handleInfo"})
        temp_socket = socket
    end
    {:no_reply, temp_socket}
  end
  defp create_todo_typed(params, socket) do
    userId = socket.assigns.current_user.id
    changeset = TodoApp.Todo.changeset(%TodoApp.Todo{}, params)
    g = TodoApp.Repo.insert(changeset)
    case (g) do
      {:ok, todo} ->
        todo = g2
        g3 = TodoPubSub.broadcast({:todo_updates}, {:todo_created, todo})
        case (g3) do
          {:ok, value} ->
            nil
          {:error, reason} ->
            reason = g4
            Log.trace("Failed to broadcast todo creation: " <> reason, %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 281, :class_name => "server.live.TodoLive", :method_name => "createTodoTyped"})
        end
        updated_socket = TodoAppWeb.TodoLive.load_and_assign_todos(socket)
        SafeAssigns.set_show_form(updated_socket, false)
      {:error, changeset2} ->
        changeset2 = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to create todo")
    end
  end
  defp create_new_todo(params, socket) do
    temp_maybe_string = nil
    if (params.priority != nil) do
      temp_maybe_string = params.priority
    else
      temp_maybe_string = "medium"
    end
    temp_maybe_date = nil
    if (params.due_date != nil) do
      temp_maybe_date = Date_Impl_.from_string(params.due_date)
    else
      temp_maybe_date = nil
    end
    temp_maybe_array = nil
    if (params.tags != nil) do
      temp_maybe_array = TodoAppWeb.TodoLive.parse_tags(params.tags)
    else
      temp_maybe_array = []
    end
    todo_params = %{:title => params.title, :description => params.description, :completed => false, :priority => temp_maybe_string, :due_date => temp_maybe_date, :tags => temp_maybe_array, :user_id => socket.assigns.current_user.id}
    changeset = TodoApp.Todo.changeset(%TodoApp.Todo{}, todo_params)
    g = TodoApp.Repo.insert(changeset)
    case (g) do
      {:ok, todo} ->
        todo = g2
        g3 = TodoPubSub.broadcast({:todo_updates}, {:todo_created, todo})
        case (g3) do
          {:ok, value} ->
            nil
          {:error, error} ->
            reason = g4
            Log.trace("Failed to broadcast todo creation: " <> reason, %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 318, :class_name => "server.live.TodoLive", :method_name => "createNewTodo"})
        end
        todos = [todo] ++ socket.assigns.todos
        live_socket = socket
        updated_socket = Phoenix.Component.assign([live_socket, todos, false], %{:todos => {1}, :show_form => {2}})
        Phoenix.LiveView.put_flash(updated_socket, {:success}, "Todo created successfully!")
      {:error, reason} ->
        reason = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to create todo: " <> reason.to_string())
    end
  end
  defp toggle_todo_status(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket
    updated_changeset = TodoApp.Todo.toggle_completed(todo)
    temp_todo = nil
    g = TodoApp.Repo.update(updated_changeset)
    case (g) do
      {:ok, u} ->
        u = g2
        temp_todo = u
      {:error, reason} ->
        reason = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to update todo: " <> reason.to_string())
    end
    TodoPubSub.broadcast({:todo_updates}, {:todo_updated, temp_todo})
    TodoAppWeb.TodoLive.update_todo_in_list(temp_todo, socket)
  end
  defp delete_todo(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket
    g = TodoApp.Repo.delete(todo)
    case (g) do
      {:ok, deleted_todo} ->
        deleted_todo = g2
        g3 = TodoPubSub.broadcast({:todo_updates}, {:todo_deleted, id})
        case (g3) do
          {:ok, value} ->
            nil
          {:error, error} ->
            reason = g4
            Log.trace("Failed to broadcast todo deletion: " <> reason, %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 363, :class_name => "server.live.TodoLive", :method_name => "deleteTodo"})
        end
        TodoAppWeb.TodoLive.remove_todo_from_list(id, socket)
      {:error, reason} ->
        reason = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to delete todo: " <> reason.to_string())
    end
  end
  defp update_todo_priority(id, priority, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket
    updated_changeset = TodoApp.Todo.update_priority(todo, priority)
    temp_todo = nil
    g = TodoApp.Repo.update(updated_changeset)
    case (g) do
      {:ok, u} ->
        u = g2
        temp_todo = u
      {:error, reason} ->
        reason = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to update priority: " <> reason.to_string())
    end
    TodoPubSub.broadcast({:todo_updates}, {:todo_updated, temp_todo})
    TodoAppWeb.TodoLive.update_todo_in_list(temp_todo, socket)
  end
  defp add_todo_to_list(todo, socket) do
    if (todo.user_id == socket.assigns.current_user.id), do: socket
    todos = [todo] ++ socket.assigns.todos
    live_socket = socket
    Phoenix.Component.assign([live_socket, todos], %{:todos => {1}})
  end
  defp load_todos(user_id) do
    temp_ecto_query = nil
    temp_ecto_query1 = nil
    temp_ecto_query2 = nil
    query = Ecto.Queryable.to_query(TodoApp.Todo)
    temp_ecto_query2 = query
    this1 = temp_ecto_query2
    new_query = (require Ecto.Query; Ecto.Query.where(this1, [q], field(q, ^String.to_existing_atom(Macro.underscore("userId"))) == ^user_id))
    this2 = new_query
    temp_ecto_query1 = this2
    this1 = temp_ecto_query1
    direction = "asc"
    if (direction == nil) do
      direction = "asc"
    end
    temp_var = nil
    if (direction == "desc") do
      temp_var = (require Ecto.Query; Ecto.Query.order_by(this1, [q], [desc: field(q, ^String.to_existing_atom(Macro.underscore("inserted_at")))]))
    else
      temp_var = (require Ecto.Query; Ecto.Query.order_by(this1, [q], [asc: field(q, ^String.to_existing_atom(Macro.underscore("inserted_at")))]))
    end
    this2 = temp_var
    temp_ecto_query = this2
    TodoApp.Repo.all(temp_ecto_query)
  end
  defp find_todo(id, todos) do
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {todos, g, :ok}, fn _, {acc_todos, acc_g, acc_state} ->
  if (acc_g < length(acc_todos)) do
    todo = acc_todos[acc_g]
    acc_g = acc_g + 1
    if (todo.id == id), do: todo
    {:cont, {acc_todos, acc_g, acc_state}}
  else
    {:halt, {acc_todos, acc_g, acc_state}}
  end
end)
    nil
  end
  defp count_completed(todos) do
    count = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {todos, g, :ok}, fn _, {acc_todos, acc_g, acc_state} ->
  if (acc_g < length(acc_todos)) do
    todo = acc_todos[acc_g]
    acc_g = acc_g + 1
    if (todo.completed) do
      count = count + 1
    end
    {:cont, {acc_todos, acc_g, acc_state}}
  else
    {:halt, {acc_todos, acc_g, acc_state}}
  end
end)
    count
  end
  defp count_pending(todos) do
    count = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {todos, g, :ok}, fn _, {acc_todos, acc_g, acc_state} ->
  if (acc_g < length(acc_todos)) do
    todo = acc_todos[acc_g]
    acc_g = acc_g + 1
    if (not todo.completed) do
      count = count + 1
    end
    {:cont, {acc_todos, acc_g, acc_state}}
  else
    {:halt, {acc_todos, acc_g, acc_state}}
  end
end)
    count
  end
  defp parse_tags(tags_string) do
    if (tags_string == nil or tags_string == ""), do: []
    Enum.map(tags_string.split(","), fn t -> StringTools.ltrim(StringTools.rtrim(t)) end)
  end
  defp get_user_from_session(session) do
    id_val = Map.get(session, String.to_atom("user_id"))
    temp_maybe_number = nil
    if (id_val != nil) do
      temp_maybe_number = id_val
    else
      temp_maybe_number = 1
    end
    uid = temp_maybe_number
    %{:id => uid, :name => "Demo User", :email => "demo@example.com", :password_hash => "hashed_password", :confirmed_at => nil, :last_login_at => nil, :active => true}
  end
  defp load_and_assign_todos(socket) do
    todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
    live_socket = socket
    Phoenix.Component.assign([live_socket, todos, todos.length, TodoAppWeb.TodoLive.count_completed(todos), TodoAppWeb.TodoLive.count_pending(todos)], %{:todos => {1}, :total_todos => {2}, :completed_todos => {3}, :pending_todos => {4}})
  end
  defp update_todo_in_list(todo, socket) do
    todos = socket.assigns.todos
    updated_todos = (
Enum.map(todos, fn t ->
  temp_result = nil
  if (t.id == todo.id) do
    temp_result = todo
  else
    temp_result = t
  end
  temp_result
end)
)
    Phoenix.Component.assign([socket, updated_todos, updated_todos.length, TodoAppWeb.TodoLive.count_completed(updated_todos), TodoAppWeb.TodoLive.count_pending(updated_todos)], %{:todos => {1}, :total_todos => {2}, :completed_todos => {3}, :pending_todos => {4}})
  end
  defp remove_todo_from_list(id, socket) do
    todos = socket.assigns.todos
    updated_todos = Enum.filter(todos, fn t -> t.id != id end)
    Phoenix.Component.assign([socket, updated_todos, updated_todos.length, TodoAppWeb.TodoLive.count_completed(updated_todos), TodoAppWeb.TodoLive.count_pending(updated_todos)], %{:todos => {1}, :total_todos => {2}, :completed_todos => {3}, :pending_todos => {4}})
  end
  defp start_editing(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    presence_socket = TodoAppWeb.Presence.update_user_editing(socket, socket.assigns.current_user, id)
    SafeAssigns.set_editing_todo(presence_socket, todo)
  end
  defp complete_all_todos(socket) do
    pending = Enum.filter(socket.assigns.todos, fn t -> not t.completed end)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {pending, g, :ok}, fn _, {acc_pending, acc_g, acc_state} ->
  if (acc_g < length(acc_pending)) do
    todo = acc_pending[acc_g]
    acc_g = acc_g + 1
    updated_changeset = TodoApp.Todo.toggle_completed(todo)
    g2 = TodoApp.Repo.update(updated_changeset)
    case (g2) do
      {:ok, value} ->
        g3 = elem(g2, 1)
        updated_todo = g3
        nil
      {:error, reason} ->
        g3 = elem(g2, 1)
        reason = g3
        Log.trace("Failed to complete todo " <> todo.id.to_string() <> ": " <> reason.to_string(), %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 516, :class_name => "server.live.TodoLive", :method_name => "completeAllTodos"})
    end
    {:cont, {acc_pending, acc_g, acc_state}}
  else
    {:halt, {acc_pending, acc_g, acc_state}}
  end
end)
    g = TodoPubSub.broadcast({:todo_updates}, {:bulk_update, {:complete_all}})
    case (g) do
      {:ok, value} ->
        nil
      {:error, error} ->
        reason = g2
        Log.trace("Failed to broadcast bulk complete: " <> reason, %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 525, :class_name => "server.live.TodoLive", :method_name => "completeAllTodos"})
    end
    updated_todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
    current_assigns = socket.assigns
    complete_assigns = %{:todos => updated_todos, :filter => current_assigns.filter, :sort_by => current_assigns.sort_by, :current_user => current_assigns.current_user, :editing_todo => current_assigns.editing_todo, :show_form => current_assigns.show_form, :search_query => current_assigns.search_query, :selected_tags => current_assigns.selected_tags, :total_todos => length(updated_todos), :completed_todos => length(updated_todos), :pending_todos => 0, :online_users => current_assigns.online_users}
    updated_socket = assign(socket, complete_assigns)
    Phoenix.LiveView.put_flash(updated_socket, {:info}, "All todos marked as completed!")
  end
  defp delete_completed_todos(socket) do
    completed = Enum.filter(socket.assigns.todos, fn t -> t.completed end)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {completed, g, :ok}, fn _, {acc_completed, acc_g, acc_state} ->
  if (acc_g < length(acc_completed)) do
    todo = acc_completed[acc_g]
    acc_g = acc_g + 1
    TodoApp.Repo.delete(todo)
    {:cont, {acc_completed, acc_g, acc_state}}
  else
    {:halt, {acc_completed, acc_g, acc_state}}
  end
end)
    TodoPubSub.broadcast({:todo_updates}, {:bulk_update, {:delete_completed}})
    remaining = Enum.filter(socket.assigns.todos, fn t -> not t.completed end)
    current_assigns = socket.assigns
    complete_assigns = %{:todos => remaining, :filter => current_assigns.filter, :sort_by => current_assigns.sort_by, :current_user => current_assigns.current_user, :editing_todo => current_assigns.editing_todo, :show_form => current_assigns.show_form, :search_query => current_assigns.search_query, :selected_tags => current_assigns.selected_tags, :total_todos => length(remaining), :completed_todos => 0, :pending_todos => length(remaining), :online_users => current_assigns.online_users}
    updated_socket = assign(socket, complete_assigns)
    Phoenix.LiveView.put_flash(updated_socket, {:info}, "Completed todos deleted!")
  end
  defp start_editing_old(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    SafeAssigns.set_editing_todo(socket, todo)
  end
  defp save_edited_todo_typed(params, socket) do
    if (socket.assigns.editing_todo == nil), do: socket
    todo = socket.assigns.editing_todo
    changeset = TodoApp.Todo.changeset(todo, params)
    g = TodoApp.Repo.update(changeset)
    case (g) do
      {:ok, updated_todo} ->
        updated_todo = g2
        g3 = TodoPubSub.broadcast({:todo_updates}, {:todo_updated, updated_todo})
        case (g3) do
          {:ok, value} ->
            nil
          {:error, reason} ->
            reason = g4
            Log.trace("Failed to broadcast todo update: " <> reason, %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 606, :class_name => "server.live.TodoLive", :method_name => "saveEditedTodoTyped"})
        end
        presence_socket = TodoAppWeb.Presence.update_user_editing(socket, socket.assigns.current_user, nil)
        updated_socket = SafeAssigns.set_editing_todo(presence_socket, nil)
        TodoAppWeb.TodoLive.load_and_assign_todos(updated_socket)
      {:error, changeset2} ->
        changeset2 = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to update todo")
    end
  end
  defp save_edited_todo(params, socket) do
    todo = socket.assigns.editing_todo
    if (todo == nil), do: socket
    temp_maybe_date = nil
    if (params.due_date != nil) do
      temp_maybe_date = Date_Impl_.from_string(params.due_date)
    else
      temp_maybe_date = nil
    end
    temp_maybe_array = nil
    if (params.tags != nil) do
      temp_maybe_array = TodoAppWeb.TodoLive.parse_tags(params.tags)
    else
      temp_maybe_array = nil
    end
    todo_params = %{:title => params.title, :description => params.description, :priority => params.priority, :due_date => temp_maybe_date, :tags => temp_maybe_array, :completed => params.completed}
    changeset = TodoApp.Todo.changeset(todo, todo_params)
    g = TodoApp.Repo.update(changeset)
    case (g) do
      {:ok, updated_todo} ->
        updated_todo = g2
        g3 = TodoPubSub.broadcast({:todo_updates}, {:todo_updated, updated_todo})
        case (g3) do
          {:ok, value} ->
            nil
          {:error, error} ->
            reason = g4
            Log.trace("Failed to broadcast todo save: " <> reason, %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 643, :class_name => "server.live.TodoLive", :method_name => "saveEditedTodo"})
        end
        updated_socket = TodoAppWeb.TodoLive.update_todo_in_list(updated_todo, socket)
        live_socket = updated_socket
        Phoenix.Component.assign(live_socket, :editing_todo, nil)
      {:error, reason} ->
        reason = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to save todo: " <> reason.to_string())
    end
  end
  defp handle_bulk_update(action, socket) do
    temp_result = nil
    case (action) do
      {:complete_all} ->
        updated_todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
        live_socket = socket
        Phoenix.Component.assign([live_socket, updated_todos, updated_todos.length, TodoAppWeb.TodoLive.count_completed(updated_todos), TodoAppWeb.TodoLive.count_pending(updated_todos)], %{:todos => {1}, :total_todos => {2}, :completed_todos => {3}, :pending_todos => {4}})
      {:delete_completed} ->
        updated_todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
        live_socket = socket
        Phoenix.Component.assign([live_socket, updated_todos, updated_todos.length, TodoAppWeb.TodoLive.count_completed(updated_todos), TodoAppWeb.TodoLive.count_pending(updated_todos)], %{:todos => {1}, :total_todos => {2}, :completed_todos => {3}, :pending_todos => {4}})
      {:set_priority, priority} ->
        priority = g
        temp_result = socket
      {:add_tag, tag} ->
        tag = g
        temp_result = socket
      {:remove_tag, tag} ->
        tag = g
        temp_result = socket
    end
    temp_result
  end
  defp toggle_tag_filter(tag, socket) do
    selected_tags = socket.assigns.selected_tags
    temp_array = nil
    if (Enum.member?(selected_tags, tag)) do
      temp_array = Enum.filter(selected_tags, fn t -> t != tag end)
    else
      temp_array = selected_tags ++ [tag]
    end
    SafeAssigns.set_selected_tags(socket, temp_array)
  end
  def index() do
    "index"
  end
  def show() do
    "show"
  end
  def edit() do
    "edit"
  end
  def render(assigns) do
    (("\n\t\t\t<div class=\"min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900\">\n\t\t\t\t<div class=\"container mx-auto px-4 py-8 max-w-6xl\">\n\t\t\t\t\t\n\t\t\t\t\t<!-- Header -->\n\t\t\t\t\t<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 mb-8\">\n\t\t\t\t\t\t<div class=\"flex justify-between items-center mb-6\">\n\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t<h1 class=\"text-4xl font-bold text-gray-800 dark:text-white mb-2\">\n\t\t\t\t\t\t\t\t\t📝 Todo Manager\n\t\t\t\t\t\t\t\t</h1>\n\t\t\t\t\t\t\t\t<p class=\"text-gray-600 dark:text-gray-400\">\n\t\t\t\t\t\t\t\t\tWelcome, <%= @currentUser.name %>!\n\t\t\t\t\t\t\t\t</p>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t<!-- Statistics -->\n\t\t\t\t\t\t\t<div class=\"flex space-x-6\">\n\t\t\t\t\t\t\t\t<div class=\"text-center\">\n\t\t\t\t\t\t\t\t\t<div class=\"text-3xl font-bold text-blue-600 dark:text-blue-400\">\n\t\t\t\t\t\t\t\t\t\t<%= @totalTodos %>\n\t\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\t<div class=\"text-sm text-gray-600 dark:text-gray-400\">Total</div>\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t<div class=\"text-center\">\n\t\t\t\t\t\t\t\t\t<div class=\"text-3xl font-bold text-green-600 dark:text-green-400\">\n\t\t\t\t\t\t\t\t\t\t<%= @completedTodos %>\n\t\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\t<div class=\"text-sm text-gray-600 dark:text-gray-400\">Completed</div>\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t<div class=\"text-center\">\n\t\t\t\t\t\t\t\t\t<div class=\"text-3xl font-bold text-amber-600 dark:text-amber-400\">\n\t\t\t\t\t\t\t\t\t\t<%= @pendingTodos %>\n\t\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\t<div class=\"text-sm text-gray-600 dark:text-gray-400\">Pending</div>\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\n\t\t\t\t\t\t<!-- Add Todo Button -->\n\t\t\t\t\t\t<button phx-click=\"toggle_form\" class=\"w-full py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-medium rounded-lg hover:from-blue-600 hover:to-indigo-700 transition-all duration-200 shadow-md\">\n\t\t\t\t\t\t\t<%= if @showForm, do: \"✖ Cancel\", else: \"➕ Add New Todo\" %>\n\t\t\t\t\t\t</button>\n\t\t\t\t\t</div>\n\t\t\t\t\t\n\t\t\t\t\t<!-- New Todo Form -->\n\t\t\t\t\t<%= if @showForm do %>\n\t\t\t\t\t\t<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8 border-l-4 border-blue-500\">\n\t\t\t\t\t\t\t<form phx-submit=\"create_todo\" class=\"space-y-4\">\n\t\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t\t<label class=\"block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2\">\n\t\t\t\t\t\t\t\t\t\tTitle *\n\t\t\t\t\t\t\t\t\t</label>\n\t\t\t\t\t\t\t\t\t<input type=\"text\" name=\"title\" required\n\t\t\t\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\"\n\t\t\t\t\t\t\t\t\t\tplaceholder=\"What needs to be done?\" />\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t\t<label class=\"block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2\">\n\t\t\t\t\t\t\t\t\t\tDescription\n\t\t\t\t\t\t\t\t\t</label>\n\t\t\t\t\t\t\t\t\t<textarea name=\"description\" rows=\"3\"\n\t\t\t\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\"\n\t\t\t\t\t\t\t\t\t\tplaceholder=\"Add more details...\"></textarea>\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t\t<div class=\"grid grid-cols-2 gap-4\">\n\t\t\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t\t\t<label class=\"block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2\">\n\t\t\t\t\t\t\t\t\t\t\tPriority\n\t\t\t\t\t\t\t\t\t\t</label>\n\t\t\t\t\t\t\t\t\t\t<select name=\"priority\"\n\t\t\t\t\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\">\n\t\t\t\t\t\t\t\t\t\t\t<option value=\"low\">Low</option>\n\t\t\t\t\t\t\t\t\t\t\t<option value=\"medium\" selected>Medium</option>\n\t\t\t\t\t\t\t\t\t\t\t<option value=\"high\">High</option>\n\t\t\t\t\t\t\t\t\t\t</select>\n\t\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t\t\t<label class=\"block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2\">\n\t\t\t\t\t\t\t\t\t\t\tDue Date\n\t\t\t\t\t\t\t\t\t\t</label>\n\t\t\t\t\t\t\t\t\t\t<input type=\"date\" name=\"dueDate\"\n\t\t\t\t\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\" />\n\t\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t\t<label class=\"block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2\">\n\t\t\t\t\t\t\t\t\t\tTags (comma-separated)\n\t\t\t\t\t\t\t\t\t</label>\n\t\t\t\t\t\t\t\t\t<input type=\"text\" name=\"tags\"\n\t\t\t\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\"\n\t\t\t\t\t\t\t\t\t\tplaceholder=\"work, personal, urgent\" />\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t\t<button type=\"submit\"\n\t\t\t\t\t\t\t\t\tclass=\"w-full py-3 bg-green-500 text-white font-medium rounded-lg hover:bg-green-600 transition-colors shadow-md\">\n\t\t\t\t\t\t\t\t\t✅ Create Todo\n\t\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t</form>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t<% end %>\n\t\t\t\t\t\n\t\t\t\t\t<!-- Filters and Search -->\n\t\t\t\t\t<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8\">\n\t\t\t\t\t\t<div class=\"flex flex-wrap gap-4\">\n\t\t\t\t\t\t\t<!-- Search -->\n\t\t\t\t\t\t\t<div class=\"flex-1 min-w-[300px]\">\n\t\t\t\t\t\t\t\t<form phx-change=\"SearchTodos\" class=\"relative\">\n\t\t\t\t\t\t\t\t\t<input type=\"search\" name=\"query\" value={@searchQuery}\n\t\t\t\t\t\t\t\t\t\tclass=\"w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\"\n\t\t\t\t\t\t\t\t\t\tplaceholder=\"Search todos...\" />\n\t\t\t\t\t\t\t\t\t<span class=\"absolute left-3 top-2.5 text-gray-400\">🔍</span>\n\t\t\t\t\t\t\t\t</form>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t<!-- Filter Buttons -->\n\t\t\t\t\t\t\t<div class=\"flex space-x-2\">\n\t\t\t\t\t\t\t\t<button phx-click=\"FilterTodos\" phx-value-filter=\"all\"\n\t\t\t\t\t\t\t\t\tclass={\"px-4 py-2 rounded-lg font-medium transition-colors \" <> if @filter == \"all\", do: \"bg-blue-500 text-white\", else: \"bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300\"}>\n\t\t\t\t\t\t\t\t\tAll\n\t\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t\t<button phx-click=\"FilterTodos\" phx-value-filter=\"active\"\n\t\t\t\t\t\t\t\t\tclass={\"px-4 py-2 rounded-lg font-medium transition-colors \" <> if @filter == \"active\", do: \"bg-blue-500 text-white\", else: \"bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300\"}>\n\t\t\t\t\t\t\t\t\tActive\n\t\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t\t<button phx-click=\"FilterTodos\" phx-value-filter=\"completed\"\n\t\t\t\t\t\t\t\t\tclass={\"px-4 py-2 rounded-lg font-medium transition-colors \" <> if @filter == \"completed\", do: \"bg-blue-500 text-white\", else: \"bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300\"}>\n\t\t\t\t\t\t\t\t\tCompleted\n\t\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t<!-- Sort Dropdown -->\n\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t<select phx-change=\"sort_todos\" name=\"sortBy\"\n\t\t\t\t\t\t\t\t\tclass=\"px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\">\n\t\t\t\t\t\t\t\t\t<option value=\"created\" selected={@sortBy == \"created\"}>Sort by Date</option>\n\t\t\t\t\t\t\t\t\t<option value=\"priority\" selected={@sortBy == \"priority\"}>Sort by Priority</option>\n\t\t\t\t\t\t\t\t\t<option value=\"dueDate\" selected={@sortBy == \"dueDate\"}>Sort by Due Date</option>\n\t\t\t\t\t\t\t\t</select>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t</div>\n\t\t\t\t\t\n\t\t\t\t\t<!-- Online Users Panel -->\n\t\t\t\t\t" <> TodoAppWeb.TodoLive.render_presence_panel(assigns) <> "\n\t\t\t\t\t\n\t\t\t\t\t<!-- Bulk Actions -->\n\t\t\t\t\t" <> TodoAppWeb.TodoLive.render_bulk_actions(assigns) <> "\n\t\t\t\t\t\n\t\t\t\t\t<!-- Todo List -->\n\t\t\t\t\t<div class=\"space-y-4\">\n\t\t\t\t\t\t" <> TodoAppWeb.TodoLive.render_todo_list(assigns) <> "\n\t\t\t\t\t</div>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t"))
  end
  defp render_presence_panel(assigns) do
    online_count = 0
    online_users_list = []
    editing_indicators = []
    this1 = assigns.online_users
    temp_key_value_iterator = this1.key_value_iterator()
    g = temp_key_value_iterator
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, temp_string, :ok}, fn _, {acc_g, acc_temp_string, acc_state} ->
  if (acc_g.has_next()) do
    g2 = acc_g.next()
    user_id = g2.key
    entry = g2.value
    online_count = online_count + 1
    nil
    {:cont, {acc_g, acc_temp_string, acc_state}}
  else
    {:halt, {acc_g, acc_temp_string, acc_state}}
  end
end)
    if (online_count == 0), do: ""
    temp_string1 = nil
    if (length(editing_indicators) > 0) do
      temp_string1 = "<div class=\"mt-3 pt-3 border-t border-gray-200 dark:border-gray-700 space-y-1\">" <> Enum.join(editing_indicators, "") <> "</div>"
    else
      temp_string1 = ""
    end
    "<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 mb-6\">\n\t\t\t<div class=\"flex items-center justify-between mb-2\">\n\t\t\t\t<h3 class=\"text-sm font-semibold text-gray-700 dark:text-gray-300\">\n\t\t\t\t\t👥 Online Users (" <> online_count.to_string() <> ")\n\t\t\t\t</h3>\n\t\t\t</div>\n\t\t\t<div class=\"grid grid-cols-2 md:grid-cols-4 gap-2\">\n\t\t\t\t" <> Enum.join(online_users_list, "") <> "\n\t\t\t</div>\n\t\t\t" <> (temp_string1) <> "\n\t\t</div>"
  end
  defp render_bulk_actions(assigns) do
    if (length(assigns.todos) == 0), do: ""
    filtered_count = length(TodoAppWeb.TodoLive.filter_todos(assigns.todos, assigns.filter, assigns.search_query))
    "<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 mb-6 flex justify-between items-center\">\n\t\t\t\t<div class=\"text-sm text-gray-600 dark:text-gray-400\">\n\t\t\t\t\tShowing " <> filtered_count.to_string() <> " of " <> assigns.total_todos.to_string() <> " todos\n\t\t\t\t</div>\n\t\t\t\t<div class=\"flex space-x-2\">\n\t\t\t\t\t<button phx-click=\"bulk_complete\"\n\t\t\t\t\t\tclass=\"px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors text-sm\">\n\t\t\t\t\t\t✅ Complete All\n\t\t\t\t\t</button>\n\t\t\t\t\t<button phx-click=\"bulk_delete_completed\" \n\t\t\t\t\t\tdata-confirm=\"Are you sure you want to delete all completed todos?\"\n\t\t\t\t\t\tclass=\"px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm\">\n\t\t\t\t\t\t🗑️ Delete Completed\n\t\t\t\t\t</button>\n\t\t\t\t</div>\n\t\t\t</div>"
  end
  defp render_todo_list(assigns) do
    if (length(assigns.todos) == 0), do: "\n\t\t\t\t<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-16 text-center\">\n\t\t\t\t\t<div class=\"text-6xl mb-4\">📋</div>\n\t\t\t\t\t<h3 class=\"text-xl font-semibold text-gray-800 dark:text-white mb-2\">\n\t\t\t\t\t\tNo todos yet!\n\t\t\t\t\t</h3>\n\t\t\t\t\t<p class=\"text-gray-600 dark:text-gray-400\">\n\t\t\t\t\t\tClick \"Add New Todo\" to get started.\n\t\t\t\t\t</p>\n\t\t\t\t</div>\n\t\t\t"
    filtered_todos = TodoAppWeb.TodoLive.filter_and_sort_todos(assigns.todos, assigns.filter, assigns.sort_by, assigns.search_query)
    todo_items = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {filtered_todos, g, :ok}, fn _, {acc_filtered_todos, acc_g, acc_state} ->
  if (acc_g < length(acc_filtered_todos)) do
    todo = acc_filtered_todos[acc_g]
    acc_g = acc_g + 1
    todo_items = todo_items ++ [TodoAppWeb.TodoLive.render_todo_item(todo, assigns.editing_todo)]
    {:cont, {acc_filtered_todos, acc_g, acc_state}}
  else
    {:halt, {acc_filtered_todos, acc_g, acc_state}}
  end
end)
    Enum.join(todo_items, "\n")
  end
  defp render_todo_item(todo, editing_todo) do
    is_editing = editing_todo != nil and editing_todo.id == todo.id
    temp_string = nil
    g = todo.priority
    case (g) do
      "high" ->
        temp_string = "border-red-500"
      "low" ->
        temp_string = "border-green-500"
      "medium" ->
        temp_string = "border-yellow-500"
      _ ->
        temp_string = "border-gray-300"
    end
    if is_editing do
      "<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 " <> temp_string <> "\">\n\t\t\t\t\t<form phx-submit=\"save_todo\" class=\"space-y-4\">\n\t\t\t\t\t\t<input type=\"hidden\" name=\"id\" value=\"" <> todo.id.to_string() <> "\" />\n\t\t\t\t\t\t<input type=\"text\" name=\"title\" value=\"" <> todo.title <> "\" required\n\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\" />\n\t\t\t\t\t\t<textarea name=\"description\" rows=\"2\"\n\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\">" <> todo.description <> "</textarea>\n\t\t\t\t\t\t<div class=\"flex space-x-2\">\n\t\t\t\t\t\t\t<button type=\"submit\" class=\"px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600\">\n\t\t\t\t\t\t\t\tSave\n\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t<button type=\"button\" phx-click=\"cancel_edit\" class=\"px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400\">\n\t\t\t\t\t\t\t\tCancel\n\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t</form>\n\t\t\t\t</div>"
    else
      temp_string1 = nil
      if (todo.completed) do
        temp_string1 = "opacity-60"
      else
        temp_string1 = ""
      end
      completed_class = temp_string1
      temp_string2 = nil
      if (todo.completed) do
        temp_string2 = "line-through"
      else
        temp_string2 = ""
      end
      text_decoration = temp_string2
      temp_string3 = nil
      if (todo.completed) do
        temp_string3 = "<span class=\"text-green-500\">✓</span>"
      else
        temp_string3 = ""
      end
      checkmark = temp_string3
      temp_string4 = nil
      if (todo.description != nil and todo.description != "") do
        temp_string4 = "<p class=\"text-gray-600 dark:text-gray-400 mt-1 " <> text_decoration <> "\">" <> todo.description <> "</p>"
      else
        temp_string4 = ""
      end
      temp_string5 = nil
      if (todo.due_date != nil) do
        temp_string6 = nil
        if (todo.due_date == nil) do
          temp_string6 = "null"
        else
          this1 = todo.due_date
          temp_string6 = DateTime.to_iso8601(this1)
        end
        temp_string5 = "<span class=\"px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs\">Due: " <> (temp_string6) <> "</span>"
      else
        temp_string5 = ""
      end
      "<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 " <> temp_string <> " " <> completed_class <> " transition-all hover:shadow-xl\">\n\t\t\t\t\t<div class=\"flex items-start space-x-4\">\n\t\t\t\t\t\t<!-- Checkbox -->\n\t\t\t\t\t\t<button phx-click=\"toggle_todo\" phx-value-id=\"" <> todo.id.to_string() <> "\"\n\t\t\t\t\t\t\tclass=\"mt-1 w-6 h-6 rounded border-2 border-gray-300 dark:border-gray-600 flex items-center justify-center hover:border-blue-500 transition-colors\">\n\t\t\t\t\t\t\t" <> checkmark <> "\n\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\n\t\t\t\t\t\t<!-- Content -->\n\t\t\t\t\t\t<div class=\"flex-1\">\n\t\t\t\t\t\t\t<h3 class=\"text-lg font-semibold text-gray-800 dark:text-white " <> text_decoration <> "\">\n\t\t\t\t\t\t\t\t" <> todo.title <> "\n\t\t\t\t\t\t\t</h3>\n\t\t\t\t\t\t\t" <> (temp_string4) <> "\n\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t<!-- Meta info -->\n\t\t\t\t\t\t\t<div class=\"flex flex-wrap gap-2 mt-3\">\n\t\t\t\t\t\t\t\t<span class=\"px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs\">\n\t\t\t\t\t\t\t\t\tPriority: " <> todo.priority <> "\n\t\t\t\t\t\t\t\t</span>\n\t\t\t\t\t\t\t\t" <> (temp_string5) <> "\n\t\t\t\t\t\t\t\t" <> TodoAppWeb.TodoLive.render_tags(todo.tags) <> "\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\n\t\t\t\t\t\t<!-- Actions -->\n\t\t\t\t\t\t<div class=\"flex space-x-2\">\n\t\t\t\t\t\t\t<button phx-click=\"edit_todo\" phx-value-id=\"" <> todo.id.to_string() <> "\"\n\t\t\t\t\t\t\t\tclass=\"p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition-colors\">\n\t\t\t\t\t\t\t\t✏️\n\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t<button phx-click=\"delete_todo\" phx-value-id=\"" <> todo.id.to_string() <> "\"\n\t\t\t\t\t\t\t\tdata-confirm=\"Are you sure?\"\n\t\t\t\t\t\t\t\tclass=\"p-2 text-red-600 hover:bg-red-100 rounded-lg transition-colors\">\n\t\t\t\t\t\t\t\t🗑️\n\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t</div>\n\t\t\t\t</div>"
    end
  end
  defp render_tags(tags) do
    if (tags == nil or length(tags) == 0), do: ""
    tag_elements = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {tags, g, :ok}, fn _, {acc_tags, acc_g, acc_state} ->
  if (acc_g < length(acc_tags)) do
    tag = acc_tags[acc_g]
    acc_g = acc_g + 1
    tag_elements = tag_elements ++ ["<button phx-click=\"toggle_tag\" phx-value-tag=\"" <> tag <> "\" class=\"px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400 rounded text-xs hover:bg-blue-200\">#" <> tag <> "</button>"]
    {:cont, {acc_tags, acc_g, acc_state}}
  else
    {:halt, {acc_tags, acc_g, acc_state}}
  end
end)
    Enum.join(tag_elements, "")
  end
  defp filter_todos(todos, filter, search_query) do
    temp_right = nil
    case (filter) do
      "active" ->
        temp_right = Enum.filter(todos, fn t -> not t.completed end)
      "completed" ->
        temp_right = Enum.filter(todos, fn t -> t.completed end)
      _ ->
        temp_right = todos
    end
    todos = temp_right
    if (search_query != nil and search_query != "") do
      query = search_query.to_lower_case()
      todos = Enum.filter(todos, fn t -> t.title.to_lower_case().index_of(query) >= 0 or t.description != nil and t.description.to_lower_case().index_of(query) >= 0 end)
    end
    todos
  end
  defp filter_and_sort_todos(todos, filter, sort_by, search_query) do
    (TodoAppWeb.TodoLive.filter_todos(todos, filter, search_query))
  end
end