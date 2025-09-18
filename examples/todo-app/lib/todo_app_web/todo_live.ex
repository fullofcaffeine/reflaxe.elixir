defmodule TodoAppWeb.TodoLive do
  def mount(_params, session, socket) do
    now = DateTime.utc_now()
    Log.trace("Current time: " <> DateTime.to_iso8601(now), %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 109, :class_name => "server.live.TodoLive", :method_name => "mount"})
    g = TodoPubSub.subscribe({:todo_updates})
    case (g) do
      {:ok, g2} ->
        nil
      {:error, _reason} ->
        reason = g2
        {:error, "Failed to subscribe to updates: " <> reason}
    end
    current_user = TodoAppWeb.TodoLive.get_user_from_session(session)
    todos = TodoAppWeb.TodoLive.load_todos(currentUser.id)
    presence_socket = TodoAppWeb.Presence.track_user(socket, currentUser)
    assigns = %{:todos => todos, :filter => "all", :sort_by => "created", :current_user => currentUser, :editing_todo => nil, :show_form => false, :search_query => "", :selected_tags => [], :total_todos => length(todos), :completed_todos => TodoAppWeb.TodoLive.count_completed(todos), :pending_todos => TodoAppWeb.TodoLive.count_pending(todos), :online_users => %{}}
    updated_socket = assign(presenceSocket, assigns)
    {:ok, updatedSocket}
  end
  def handle_event(event, socket) do
    temp_socket = nil
    case (event) do
      {:create_todo, _params} ->
        params = g
        temp_socket = TodoAppWeb.TodoLive.create_todo_typed(params, socket)
      {:toggle_todo, _id} ->
        id = g
        temp_socket = TodoAppWeb.TodoLive.toggle_todo_status(id, socket)
      {:delete_todo, _id} ->
        id = g
        temp_socket = TodoAppWeb.TodoLive.delete_todo(id, socket)
      {:edit_todo, _id} ->
        id = g
        temp_socket = TodoAppWeb.TodoLive.start_editing(id, socket)
      {:save_todo, _params} ->
        params = g
        temp_socket = TodoAppWeb.TodoLive.save_edited_todo_typed(params, socket)
      {:cancel_edit} ->
        presence_socket = TodoAppWeb.Presence.update_user_editing(socket, socket.assigns.current_user, nil)
        :nil
      {:filter_todos, _filter} ->
        filter = g
        :nil
      {:sort_todos, _sortBy} ->
        sort_by = g
        :nil
      {:search_todos, _query} ->
        query = g
        :nil
      {:toggle_tag, _tag} ->
        tag = g
        :nil
      {:set_priority, _id, _priority} ->
        id = g
        priority = g1
        :nil
      {:toggle_form} ->
        :nil
      {:bulk_complete} ->
        :nil
      {:bulk_delete_completed} ->
        :nil
    end
    {:no_reply, :nil}
  end
  def handle_info(msg, socket) do
    temp_socket = nil
    g = TodoPubSub.parse_message(msg)
    case (g) do
      {:some, _parsed_msg} ->
        parsed_msg = g2
        case (parsedMsg) do
          {:todo_created, _todo} ->
            :nil
          {:todo_updated, _todo} ->
            :nil
          {:todo_deleted, _id} ->
            id = g3
            :nil
          {:bulk_update, _action} ->
            action = g3
            :nil
          {:user_online, _user_id} ->
            :nil
          {:user_offline, _user_id} ->
            :nil
          {:system_alert, _message, _level} ->
            message = g3
            level = g1
            temp_flash_type = nil
            case (level) do
              {:info} ->
                :nil
              {:warning} ->
                :nil
              {:error} ->
                :nil
              {:critical} ->
                :nil
            end
            flash_type = :nil
            :nil
        end
      {:none} ->
        Log.trace("Received unknown PubSub message: " <> Std.string(msg), %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 254, :class_name => "server.live.TodoLive", :method_name => "handleInfo"})
        :nil
    end
    {:no_reply, :nil}
  end
  defp create_todo_typed(params, socket) do
    userId = socket.assigns.current_user.id
    changeset = TodoApp.Todo.changeset(%TodoApp.Todo{}, params)
    g = TodoApp.Repo.insert(changeset)
    case (g) do
      {:ok, _todo} ->
        todo = g2
        g3 = TodoPubSub.broadcast({:todo_updates}, {:todo_created, todo})
        case (g3) do
          {:ok, g4} ->
            nil
          {:error, _reason} ->
            reason = g4
            Log.trace("Failed to broadcast todo creation: " <> reason, %{:file_name => :nil, :line_number => :nil, :class_name => :nil, :method_name => :nil})
        end
        updated_socket = TodoAppWeb.TodoLive.load_and_assign_todos(socket)
        SafeAssigns.set_show_form(updatedSocket, false)
      {:error, _changeset2} ->
        changeset2 = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to create todo")
    end
  end
  defp create_new_todo(params, socket) do
    temp_maybe_string = nil
    if (Map.get(params, :priority) != nil) do
      temp_maybe_string = params.priority
    else
      temp_maybe_string = "medium"
    end
    temp_maybe_date = nil
    if (Map.get(params, :due_date) != nil) do
      temp_maybe_date = Date_Impl_.from_string(params.due_date)
    else
      temp_maybe_date = nil
    end
    temp_maybe_array = nil
    if (Map.get(params, :tags) != nil) do
      temp_maybe_array = TodoAppWeb.TodoLive.parse_tags(params.tags)
    else
      temp_maybe_array = []
    end
    todo_params = %{:title => params.title, :description => params.description, :completed => false, :priority => tempMaybeString, :due_date => tempMaybeDate, :tags => tempMaybeArray, :user_id => socket.assigns.current_user.id}
    changeset = TodoApp.Todo.changeset(%TodoApp.Todo{}, todoParams)
    g = TodoApp.Repo.insert(changeset)
    case (g) do
      {:ok, _todo} ->
        todo = g2
        g3 = TodoPubSub.broadcast({:todo_updates}, {:todo_created, todo})
        case (g3) do
          {:ok, g4} ->
            nil
          {:error, g4} ->
            g4 = g3
            reason = g4
            Log.trace("Failed to broadcast todo creation: " <> reason, %{:file_name => :nil, :line_number => :nil, :class_name => :nil, :method_name => :nil})
        end
        todos = [todo] ++ socket.assigns.todos
        live_socket = socket
        updated_socket = :nil
        Phoenix.LiveView.put_flash(updatedSocket, {:success}, "Todo created successfully!")
      {:error, g2} ->
        g2 = g
        reason = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to create todo: " <> Kernel.to_string(reason))
    end
  end
  defp toggle_todo_status(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket
    updated_changeset = TodoApp.Todo.toggle_completed(todo)
    temp_todo = nil
    g = TodoApp.Repo.update(updatedChangeset)
    case (g) do
      {:ok, _u} ->
        u = g2
        temp_todo = u
      {:error, _reason} ->
        reason = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to update todo: " <> Kernel.to_string(reason))
    end
    TodoPubSub.broadcast({:todo_updates}, {:todo_updated, tempTodo})
    TodoAppWeb.TodoLive.update_todo_in_list(tempTodo, socket)
  end
  defp delete_todo(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket
    g = TodoApp.Repo.delete(todo)
    case (g) do
      {:ok, _deleted_todo} ->
        deleted_todo = g2
        g3 = TodoPubSub.broadcast({:todo_updates}, {:todo_deleted, id})
        case (g3) do
          {:ok, g4} ->
            nil
          {:error, g4} ->
            g4 = g3
            reason = g4
            Log.trace("Failed to broadcast todo deletion: " <> reason, %{:file_name => :nil, :line_number => :nil, :class_name => :nil, :method_name => :nil})
        end
        TodoAppWeb.TodoLive.remove_todo_from_list(id, socket)
      {:error, g2} ->
        g2 = g
        reason = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to delete todo: " <> Kernel.to_string(reason))
    end
  end
  defp update_todo_priority(id, priority, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket
    updated_changeset = TodoApp.Todo.update_priority(todo, priority)
    temp_todo = nil
    g = TodoApp.Repo.update(updatedChangeset)
    case (g) do
      {:ok, _u} ->
        u = g2
        temp_todo = u
      {:error, _reason} ->
        reason = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to update priority: " <> Kernel.to_string(reason))
    end
    TodoPubSub.broadcast({:todo_updates}, {:todo_updated, tempTodo})
    TodoAppWeb.TodoLive.update_todo_in_list(tempTodo, socket)
  end
  defp add_todo_to_list(todo, socket) do
    if (todo.user_id == socket.assigns.current_user.id), do: socket
    todos = [todo] ++ socket.assigns.todos
    live_socket = socket
    :nil
  end
  defp load_todos(user_id) do
    temp_ecto_query = nil
    temp_ecto_query1 = nil
    temp_ecto_query2 = nil
    query = Ecto.Queryable.to_query(TodoApp.Todo)
    temp_ecto_query2 = query
    this1 = tempEctoQuery2
    new_query = (require Ecto.Query; Ecto.Query.where(this1, [q], field(q, ^String.to_existing_atom(Macro.underscore("userId"))) == ^userId))
    this2 = newQuery
    temp_ecto_query1 = this2
    this1 = :nil
    direction = "asc"
    if (direction == nil) do
      direction = "asc"
    end
    temp_var = nil
    if (direction == "desc") do
      temp_var = (require Ecto.Query; Ecto.Query.order_by(:nil, [q], [desc: field(q, ^String.to_existing_atom(Macro.underscore("inserted_at")))]))
    else
      temp_var = (require Ecto.Query; Ecto.Query.order_by(:nil, [q], [asc: field(q, ^String.to_existing_atom(Macro.underscore("inserted_at")))]))
    end
    this2 = :nil
    temp_ecto_query = :nil
    TodoApp.Repo.all(:nil)
  end
  defp find_todo(id, todos) do
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {todos, g, :ok}, fn _, {acc_todos, acc_g, acc_state} ->
  if (g < length(acc_todos)) do
    todo = acc_todos[_g]
    g = g + 1
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
  if (g < length(acc_todos)) do
    todo = acc_todos[_g]
    g = g + 1
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
  if (g < length(acc_todos)) do
    todo = acc_todos[_g]
    g = g + 1
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
    if (tagsString == nil || tagsString == ""), do: []
    Enum.map(:nil.split(","), fn t -> :nil.ltrim(:nil.rtrim(t)) end)
  end
  defp get_user_from_session(session) do
    id_val = Map.get(session, String.to_atom("user_id"))
    temp_maybe_number = nil
    if (idVal != nil) do
      temp_maybe_number = idVal
    else
      temp_maybe_number = 1
    end
    uid = tempMaybeNumber
    %{:id => uid, :name => "Demo User", :email => "demo@example.com", :password_hash => "hashed_password", :confirmed_at => nil, :last_login_at => nil, :active => true}
  end
  defp load_and_assign_todos(socket) do
    todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
    live_socket = socket
    :nil
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
  tempResult
end)
)
    :nil
  end
  defp remove_todo_from_list(id, socket) do
    todos = socket.assigns.todos
    updated_todos = Enum.filter(todos, fn t -> t.id != id end)
    :nil
  end
  defp start_editing(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    presence_socket = TodoAppWeb.Presence.update_user_editing(socket, socket.assigns.current_user, id)
    SafeAssigns.set_editing_todo(presenceSocket, todo)
  end
  defp complete_all_todos(socket) do
    pending = Enum.filter(socket.assigns.todos, fn t -> not t.completed end)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {pending, g, :ok}, fn _, {acc_pending, acc_g, acc_state} ->
  if (g < length(acc_pending)) do
    todo = acc_pending[_g]
    g = g + 1
    updated_changeset = TodoApp.Todo.toggle_completed(todo)
    g2 = TodoApp.Repo.update(updatedChangeset)
    case (g2) do
      {:ok, g3} ->
        g3 = g2
        updated_todo = g3
        nil
      {:error, g3} ->
        g3 = g2
        reason = g3
        Log.trace(:nil <> :nil <> Kernel.to_string(reason), %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 516, :class_name => :nil, :method_name => :nil})
    end
    {:cont, {acc_pending, acc_g, acc_state}}
  else
    {:halt, {acc_pending, acc_g, acc_state}}
  end
end)
    g = TodoPubSub.broadcast({:todo_updates}, {:bulk_update, {:complete_all}})
    case (g) do
      {:ok, g2} ->
        nil
      {:error, g2} ->
        g2 = g
        reason = g2
        Log.trace("Failed to broadcast bulk complete: " <> reason, %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 525, :class_name => :nil, :method_name => :nil})
    end
    updated_todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
    current_assigns = socket.assigns
    complete_assigns = %{:todos => updatedTodos, :filter => currentAssigns.filter, :sort_by => currentAssigns.sort_by, :current_user => currentAssigns.current_user, :editing_todo => currentAssigns.editing_todo, :show_form => currentAssigns.show_form, :search_query => currentAssigns.search_query, :selected_tags => currentAssigns.selected_tags, :total_todos => length(updatedTodos), :completed_todos => length(updatedTodos), :pending_todos => 0, :online_users => currentAssigns.online_users}
    updated_socket = assign(socket, completeAssigns)
    Phoenix.LiveView.put_flash(updatedSocket, {:info}, "All todos marked as completed!")
  end
  defp delete_completed_todos(socket) do
    completed = Enum.filter(socket.assigns.todos, fn t -> t.completed end)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {completed, g, :ok}, fn _, {acc_completed, acc_g, acc_state} ->
  if (g < length(acc_completed)) do
    todo = acc_completed[_g]
    g = g + 1
    TodoApp.Repo.delete(todo)
    {:cont, {acc_completed, acc_g, acc_state}}
  else
    {:halt, {acc_completed, acc_g, acc_state}}
  end
end)
    TodoPubSub.broadcast({:todo_updates}, {:bulk_update, {:delete_completed}})
    remaining = Enum.filter(socket.assigns.todos, fn t -> not t.completed end)
    current_assigns = socket.assigns
    complete_assigns = %{:todos => remaining, :filter => currentAssigns.filter, :sort_by => currentAssigns.sort_by, :current_user => currentAssigns.current_user, :editing_todo => currentAssigns.editing_todo, :show_form => currentAssigns.show_form, :search_query => currentAssigns.search_query, :selected_tags => currentAssigns.selected_tags, :total_todos => length(remaining), :completed_todos => 0, :pending_todos => length(remaining), :online_users => currentAssigns.online_users}
    updated_socket = assign(socket, completeAssigns)
    Phoenix.LiveView.put_flash(updatedSocket, {:info}, "Completed todos deleted!")
  end
  defp start_editing_old(id, socket) do
    todo = TodoAppWeb.TodoLive.find_todo(id, socket.assigns.todos)
    SafeAssigns.set_editing_todo(socket, todo)
  end
  defp save_edited_todo_typed(params, socket) do
    if (Map.get(socket.assigns, :editing_todo) == nil), do: socket
    todo = socket.assigns.editing_todo
    changeset = TodoApp.Todo.changeset(todo, params)
    g = TodoApp.Repo.update(changeset)
    case (g) do
      {:ok, _updated_todo} ->
        updated_todo = g2
        g3 = TodoPubSub.broadcast({:todo_updates}, {:todo_updated, updatedTodo})
        case (g3) do
          {:ok, g4} ->
            nil
          {:error, _reason} ->
            reason = g4
            Log.trace("Failed to broadcast todo update: " <> reason, %{:file_name => :nil, :line_number => :nil, :class_name => :nil, :method_name => :nil})
        end
        presence_socket = TodoAppWeb.Presence.update_user_editing(socket, socket.assigns.current_user, nil)
        updated_socket = SafeAssigns.set_editing_todo(presenceSocket, nil)
        TodoAppWeb.TodoLive.load_and_assign_todos(updatedSocket)
      {:error, _changeset2} ->
        changeset2 = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to update todo")
    end
  end
  defp save_edited_todo(params, socket) do
    todo = socket.assigns.editing_todo
    if (todo == nil), do: socket
    temp_maybe_date = nil
    if (Map.get(params, :due_date) != nil) do
      temp_maybe_date = Date_Impl_.from_string(params.due_date)
    else
      temp_maybe_date = nil
    end
    temp_maybe_array = nil
    if (Map.get(params, :tags) != nil) do
      temp_maybe_array = TodoAppWeb.TodoLive.parse_tags(params.tags)
    else
      temp_maybe_array = nil
    end
    todo_params = %{:title => params.title, :description => params.description, :priority => params.priority, :due_date => tempMaybeDate, :tags => tempMaybeArray, :completed => params.completed}
    changeset = TodoApp.Todo.changeset(todo, todoParams)
    g = TodoApp.Repo.update(changeset)
    case (g) do
      {:ok, _updated_todo} ->
        updated_todo = g2
        g3 = TodoPubSub.broadcast({:todo_updates}, {:todo_updated, updatedTodo})
        case (g3) do
          {:ok, g4} ->
            nil
          {:error, g4} ->
            g4 = g3
            reason = g4
            Log.trace("Failed to broadcast todo save: " <> reason, %{:file_name => :nil, :line_number => :nil, :class_name => :nil, :method_name => :nil})
        end
        updated_socket = TodoAppWeb.TodoLive.update_todo_in_list(updatedTodo, socket)
        live_socket = updatedSocket
        :nil
      {:error, g2} ->
        g2 = g
        reason = g2
        Phoenix.LiveView.put_flash(socket, {:error}, "Failed to save todo: " <> Kernel.to_string(reason))
    end
  end
  defp handle_bulk_update(action, socket) do
    temp_result = nil
    case (action) do
      {:complete_all} ->
        updated_todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
        live_socket = socket
        :nil
      {:delete_completed} ->
        updated_todos = TodoAppWeb.TodoLive.load_todos(socket.assigns.current_user.id)
        live_socket = socket
        :nil
      {:set_priority, _priority} ->
        priority = g
        temp_result = socket
      {:add_tag, _tag} ->
        tag = g
        temp_result = socket
      {:remove_tag, _tag} ->
        tag = g
        temp_result = socket
    end
    :nil
  end
  defp toggle_tag_filter(tag, socket) do
    selected_tags = socket.assigns.selected_tags
    temp_array = nil
    if (Enum.member?(selectedTags, tag)) do
      temp_array = Enum.filter(selectedTags, fn t -> :nil != :nil end)
    else
      temp_array = selectedTags ++ [tag]
    end
    SafeAssigns.set_selected_tags(socket, tempArray)
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
    temp_result = (:nil <> :nil <> TodoAppWeb.TodoLive.render_todo_list(assigns) <> "\n\t\t\t\t\t</div>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t")
    tempResult
  end
  defp render_presence_panel(assigns) do
    online_count = 0
    online_users_list = []
    editing_indicators = []
    this1 = assigns.online_users
    temp_key_value_iterator = this1.key_value_iterator()
    g = :nil
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, temp_string, :ok}, fn _, {acc_g, acc_temp_string, acc_state} ->
  if (:nil.has_next()) do
    g2 = :nil.next()
    user_id = :nil
    entry = :nil
    onlineCount = onlineCount + 1
    nil
    {:cont, {acc_g, acc_temp_string, acc_state}}
  else
    {:halt, {acc_g, acc_temp_string, acc_state}}
  end
end)
    if (onlineCount == 0), do: ""
    temp_string1 = nil
    if (length(editingIndicators) > 0) do
      temp_string1 = :nil <> :nil
    else
      temp_string1 = ""
    end
    :nil <> :nil <> (tempString1) <> "\n\t\t</div>"
  end
  defp render_bulk_actions(assigns) do
    if (length(assigns.todos) == 0), do: ""
    filtered_count = length(TodoAppWeb.TodoLive.filter_todos(assigns.todos, assigns.filter, assigns.search_query))
    :nil <> " todos\n\t\t\t\t</div>\n\t\t\t\t<div class=\"flex space-x-2\">\n\t\t\t\t\t<button phx-click=\"bulk_complete\"\n\t\t\t\t\t\tclass=\"px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors text-sm\">\n\t\t\t\t\t\t✅ Complete All\n\t\t\t\t\t</button>\n\t\t\t\t\t<button phx-click=\"bulk_delete_completed\" \n\t\t\t\t\t\tdata-confirm=\"Are you sure you want to delete all completed todos?\"\n\t\t\t\t\t\tclass=\"px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm\">\n\t\t\t\t\t\t🗑️ Delete Completed\n\t\t\t\t\t</button>\n\t\t\t\t</div>\n\t\t\t</div>"
  end
  defp render_todo_list(assigns) do
    if (length(assigns.todos) == 0), do: "\n\t\t\t\t<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-16 text-center\">\n\t\t\t\t\t<div class=\"text-6xl mb-4\">📋</div>\n\t\t\t\t\t<h3 class=\"text-xl font-semibold text-gray-800 dark:text-white mb-2\">\n\t\t\t\t\t\tNo todos yet!\n\t\t\t\t\t</h3>\n\t\t\t\t\t<p class=\"text-gray-600 dark:text-gray-400\">\n\t\t\t\t\t\tClick \"Add New Todo\" to get started.\n\t\t\t\t\t</p>\n\t\t\t\t</div>\n\t\t\t"
    filtered_todos = TodoAppWeb.TodoLive.filter_and_sort_todos(assigns.todos, assigns.filter, assigns.sort_by, assigns.search_query)
    todo_items = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {filtered_todos, g, :ok}, fn _, {acc_filtered_todos, acc_g, acc_state} ->
  if (g < length(filteredTodos)) do
    todo = filteredTodos[_g]
    g = g + 1
    todoItems = todoItems ++ [TodoAppWeb.TodoLive.render_todo_item(todo, assigns.editing_todo)]
    {:cont, {acc_filtered_todos, acc_g, acc_state}}
  else
    {:halt, {acc_filtered_todos, acc_g, acc_state}}
  end
end)
    Enum.join(todoItems, "\n")
  end
  defp render_todo_item(todo, editing_todo) do
    is_editing = editingTodo != nil && editingTodo.id == todo.id
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
    if isEditing do
      :nil <> todo.description <> "</textarea>\n\t\t\t\t\t\t<div class=\"flex space-x-2\">\n\t\t\t\t\t\t\t<button type=\"submit\" class=\"px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600\">\n\t\t\t\t\t\t\t\tSave\n\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t<button type=\"button\" phx-click=\"cancel_edit\" class=\"px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400\">\n\t\t\t\t\t\t\t\tCancel\n\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t</form>\n\t\t\t\t</div>"
    else
      temp_string1 = nil
      if (todo.completed) do
        temp_string1 = "opacity-60"
      else
        temp_string1 = ""
      end
      completed_class = tempString1
      temp_string2 = nil
      if (todo.completed) do
        temp_string2 = "line-through"
      else
        temp_string2 = ""
      end
      text_decoration = tempString2
      temp_string3 = nil
      if (todo.completed) do
        temp_string3 = "<span class=\"text-green-500\">✓</span>"
      else
        temp_string3 = ""
      end
      checkmark = tempString3
      temp_string4 = nil
      :nil
      temp_string5 = nil
      :nil
      :nil <> :nil <> Kernel.to_string(todo.id) <> "\"\n\t\t\t\t\t\t\t\tdata-confirm=\"Are you sure?\"\n\t\t\t\t\t\t\t\tclass=\"p-2 text-red-600 hover:bg-red-100 rounded-lg transition-colors\">\n\t\t\t\t\t\t\t\t🗑️\n\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t</div>\n\t\t\t\t</div>"
    end
  end
  defp render_tags(tags) do
    if (tags == nil || length(tags) == 0), do: ""
    tag_elements = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {tags, g, :ok}, fn _, {acc_tags, acc_g, acc_state} ->
  if (g < length(acc_tags)) do
    tag = acc_tags[_g]
    g = g + 1
    tagElements = tagElements ++ [:nil <> :nil <> tag <> "</button>"]
    {:cont, {acc_tags, acc_g, acc_state}}
  else
    {:halt, {acc_tags, acc_g, acc_state}}
  end
end)
    Enum.join(tagElements, "")
  end
  defp filter_todos(todos, filter, search_query) do
    temp_right = nil
    case (filter) do
      "active" ->
        temp_right = Enum.filter(todos, fn t -> not t.completed end)
      "completed" ->
        temp_right = Enum.filter(:nil, fn t -> t.completed end)
      _ ->
        temp_right = :nil
    end
    todos = tempRight
    if (searchQuery != nil && searchQuery != "") do
      query = searchQuery.to_lower_case()
      todos = Enum.filter(:nil, fn t -> :nil || :nil end)
    end
    :nil
  end
  defp filter_and_sort_todos(todos, filter, sort_by, search_query) do
    (TodoAppWeb.TodoLive.filter_todos(todos, filter, searchQuery))
  end
end