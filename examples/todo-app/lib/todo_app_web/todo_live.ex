defmodule TodoAppWeb.TodoLive do
  use TodoAppWeb, :live_view
  def mount(_params, session, socket) do
    g = {:Subscribe, :todo_updates}
    case (g.elem(0)) do
      0 ->
        g = g.elem(1)
        nil
      1 ->
        g = g.elem(1)
        reason = g
        {:Error, "Failed to subscribe to updates: " <> reason}
    end
    current_user = get_user_from_session(session)
    todos = load_todos(current_user.id)
    assigns = %{:todos => todos, :filter => "all", :sort_by => "created", :current_user => current_user, :editing_todo => nil, :show_form => false, :search_query => "", :selected_tags => [], :total_todos => todos.length, :completed_todos => count_completed(todos), :pending_todos => count_pending(todos)}
    updated_socket = Phoenix.LiveView.assign(socket, assigns)
    {:Ok, updated_socket}
  end
  def handle_event(event, params, socket) do
    result_socket = case (event) do
  "bulk_complete" ->
    complete_all_todos(socket)
  "bulk_delete_completed" ->
    delete_completed_todos(socket)
  "cancel_edit" ->
    SafeAssigns.set_editing_todo(socket, nil)
  "create_todo" ->
    create_new_todo(params, socket)
  "delete_todo" ->
    delete_todo(params.id, socket)
  "edit_todo" ->
    start_editing(params.id, socket)
  "filter_todos" ->
    SafeAssigns.set_filter(socket, params.filter)
  "save_todo" ->
    save_edited_todo(params, socket)
  "search_todos" ->
    SafeAssigns.set_search_query(socket, params.query)
  "set_priority" ->
    update_todo_priority(params.id, params.priority, socket)
  "sort_todos" ->
    SafeAssigns.set_sort_by(socket, params.sort_by)
  "toggle_form" ->
    SafeAssigns.set_show_form(socket, not socket.assigns.show_form)
  "toggle_tag" ->
    toggle_tag_filter(params.tag, socket)
  "toggle_todo" ->
    toggle_todo_status(params.id, socket)
  _ ->
    socket
end
    {:NoReply, result_socket}
  end
  def handle_info(msg, socket) do
    result_socket = g = {:ParseMessage, msg}
case (g.elem(0)) do
  0 ->
    g = g.elem(1)
    parsed_msg = g
    case (parsed_msg.elem(0)) do
      0 ->
        g = parsed_msg.elem(1)
        todo = add_todo_to_list(g, socket)
      1 ->
        g = parsed_msg.elem(1)
        todo = update_todo_in_list(g, socket)
      2 ->
        g = parsed_msg.elem(1)
        id = remove_todo_from_list(g, socket)
      3 ->
        g = parsed_msg.elem(1)
        action = handle_bulk_update(g, socket)
      4 ->
        g = parsed_msg.elem(1)
        user_id = g
        socket
      5 ->
        g = parsed_msg.elem(1)
        user_id = g
        socket
      6 ->
        g = parsed_msg.elem(1)
        g1 = parsed_msg.elem(2)
        message = g
        level = g1
        flash_type = case (level.elem(0)) do
  0 ->
    :info
  1 ->
    :warning
  2 ->
    :error
  3 ->
    :error
end
        Phoenix.LiveView.put_flash(socket, flash_type, message)
    end
  1 ->
    Log.trace("Received unknown PubSub message: " <> Std.string(msg), %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 196, :className => "server.live.TodoLive", :methodName => "handle_info"})
    socket
end
    {:NoReply, result_socket}
  end
  defp create_new_todo(params, socket) do
    todo_params_user_id = nil
    todo_params_title = nil
    todo_params_tags = nil
    todo_params_priority = nil
    todo_params_due_date = nil
    todo_params_description = nil
    todo_params_completed = nil
    todo_params_title = params.title
    todo_params_description = params.description
    todo_params_completed = false
    todo_params_priority = if (params.priority != nil), do: params.priority, else: "medium"
    todo_params_due_date = params.due_date
    todo_params_tags = parse_tags(params.tags)
    todo_params_user_id = socket.assigns.current_user.id
    changeset_params = TypeSafeConversions.event_params_to_changeset_params(params)
    changeset = Todo.changeset(Todo.new(), changeset_params)
    g = {:Insert, changeset}
    case (g.elem(0)) do
      0 ->
        g = g.elem(1)
        todo = g
        g = {:Broadcast, :todo_updates, {:TodoCreated, todo}}
        case (g.elem(0)) do
          0 ->
            g = g.elem(1)
            nil
          1 ->
            g = g.elem(1)
            reason = g
            Log.trace("Failed to broadcast todo creation: " <> reason, %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 227, :className => "server.live.TodoLive", :methodName => "create_new_todo"})
        end
        todos = [todo] ++ socket.assigns.todos
        current_assigns = socket.assigns
        complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, todos, nil, nil, nil, nil, false, nil, nil)
        updated_socket = Phoenix.LiveView.assign(socket, complete_assigns)
        Phoenix.LiveView.put_flash(updated_socket, :success, "Todo created successfully!")
      1 ->
        g = g.elem(1)
        reason = g
        Phoenix.LiveView.put_flash(socket, :error, "Failed to create todo: " <> Std.string(reason))
    end
  end
  defp toggle_todo_status(id, socket) do
    todo = find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket
    updated_changeset = Todo.toggle_completed(todo)
    g = {:Update, updated_changeset}
    case (g.elem(0)) do
      0 ->
        g = g.elem(1)
        updated_todo = g
        g = {:Broadcast, :todo_updates, {:TodoUpdated, updated_todo}}
        case (g.elem(0)) do
          0 ->
            g = g.elem(1)
            nil
          1 ->
            g = g.elem(1)
            reason = g
            Log.trace("Failed to broadcast todo update: " <> reason, %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 266, :className => "server.live.TodoLive", :methodName => "toggle_todo_status"})
        end
        update_todo_in_list(updated_todo, socket)
      1 ->
        g = g.elem(1)
        reason = g
        Phoenix.LiveView.put_flash(socket, :error, "Failed to update todo: " <> Std.string(reason))
    end
  end
  defp delete_todo(id, socket) do
    todo = find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket
    g = {:Delete, todo}
    case (g.elem(0)) do
      0 ->
        g = g.elem(1)
        deleted_todo = g
        g = {:Broadcast, :todo_updates, {:TodoDeleted, id}}
        case (g.elem(0)) do
          0 ->
            g = g.elem(1)
            nil
          1 ->
            g = g.elem(1)
            reason = g
            Log.trace("Failed to broadcast todo deletion: " <> reason, %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 288, :className => "server.live.TodoLive", :methodName => "delete_todo"})
        end
        remove_todo_from_list(id, socket)
      1 ->
        g = g.elem(1)
        reason = g
        Phoenix.LiveView.put_flash(socket, :error, "Failed to delete todo: " <> Std.string(reason))
    end
  end
  defp update_todo_priority(id, priority, socket) do
    todo = find_todo(id, socket.assigns.todos)
    if (todo == nil), do: socket
    updated_changeset = Todo.update_priority(todo, priority)
    g = {:Update, updated_changeset}
    case (g.elem(0)) do
      0 ->
        g = g.elem(1)
        updated_todo = g
        g = {:Broadcast, :todo_updates, {:TodoUpdated, updated_todo}}
        case (g.elem(0)) do
          0 ->
            g = g.elem(1)
            nil
          1 ->
            g = g.elem(1)
            reason = g
            Log.trace("Failed to broadcast todo priority update: " <> reason, %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 312, :className => "server.live.TodoLive", :methodName => "update_todo_priority"})
        end
        update_todo_in_list(updated_todo, socket)
      1 ->
        g = g.elem(1)
        reason = g
        Phoenix.LiveView.put_flash(socket, :error, "Failed to update priority: " <> Std.string(reason))
    end
  end
  defp add_todo_to_list(todo, socket) do
    if (todo.user_id == socket.assigns.current_user.id), do: socket
    todos = [todo] ++ socket.assigns.todos
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, todos)
    Phoenix.LiveView.assign(socket, complete_assigns)
  end
  defp update_todo_in_list(updated_todo, socket) do
    todos = Enum.map(socket.assigns.todos, fn t -> if (t.id == updated_todo.id), do: updated_todo, else: t end)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, todos)
    Phoenix.LiveView.assign(socket, complete_assigns)
  end
  defp remove_todo_from_list(id, socket) do
    todos = Enum.filter(socket.assigns.todos, fn t -> t.id != id end)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, todos)
    Phoenix.LiveView.assign(socket, complete_assigns)
  end
  defp load_todos(user_id) do
    query = EctoQuery_Impl_.order_by(EctoQuery_Impl_.where(Query.from(Todo), "user_id", user_id), "inserted_at", "asc")
    TodoApp.Repo.all(query)
  end
  defp find_todo(id, todos) do
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (g < todos.length) do
    todo = todos[g]
    g = g + 1
    if (todo.id == id), do: todo
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    nil
  end
  defp count_completed(todos) do
    count = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (g < todos.length) do
    todo = todos[g]
    g = g + 1
    if (todo.completed), do: count = count + 1
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    count
  end
  defp count_pending(todos) do
    count = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (g < todos.length) do
    todo = todos[g]
    g = g + 1
    if (not todo.completed), do: count = count + 1
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    count
  end
  defp parse_tags(tags_string) do
    if (tags_string == nil || tags_string == ""), do: []
    Enum.map(tags_string.split(","), fn t -> StringTools.trim(t) end)
  end
  defp get_user_from_session(session) do
    %{:id => (if (session.user_id != nil), do: session.user_id, else: 1), :name => "Demo User", :email => "demo@example.com", :password_hash => "hashed_password", :confirmed_at => nil, :last_login_at => nil, :active => true}
  end
  defp complete_all_todos(socket) do
    pending = Enum.filter(socket.assigns.todos, fn t -> not t.completed end)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (g < pending.length) do
    todo = pending[g]
    g = g + 1
    updated_changeset = Todo.toggle_completed(todo)
    g = {:Update, updated_changeset}
    case (g.elem(0)) do
      0 ->
        g = g.elem(1)
        updated_todo = g
        nil
      1 ->
        g = g.elem(1)
        reason = g
        Log.trace("Failed to complete todo " <> todo.id <> ": " <> Std.string(reason), %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 432, :className => "server.live.TodoLive", :methodName => "complete_all_todos"})
    end
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    g = {:Broadcast, :todo_updates, {:BulkUpdate, :complete_all}}
    case (g.elem(0)) do
      0 ->
        g = g.elem(1)
        nil
      1 ->
        g = g.elem(1)
        reason = g
        Log.trace("Failed to broadcast bulk complete: " <> reason, %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 441, :className => "server.live.TodoLive", :methodName => "complete_all_todos"})
    end
    updated_todos = load_todos(socket.assigns.current_user.id)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
    completed_todos = complete_assigns.total_todos
    pending_todos = 0
    updated_socket = Phoenix.LiveView.assign(socket, complete_assigns)
    Phoenix.LiveView.put_flash(updated_socket, :info, "All todos marked as completed!")
  end
  defp delete_completed_todos(socket) do
    completed = Enum.filter(socket.assigns.todos, fn t -> t.completed end)
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (g < completed.length) do
    todo = completed[g]
    g = g + 1
    {:Delete, todo}
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    {:Broadcast, :todo_updates, {:BulkUpdate, :delete_completed}}
    remaining = Enum.filter(socket.assigns.todos, fn t -> not t.completed end)
    current_assigns = socket.assigns
    complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, remaining)
    completed_todos = 0
    pending_todos = remaining.length
    updated_socket = Phoenix.LiveView.assign(socket, complete_assigns)
    Phoenix.LiveView.put_flash(updated_socket, :info, "Completed todos deleted!")
  end
  defp start_editing(id, socket) do
    todo = find_todo(id, socket.assigns.todos)
    SafeAssigns.set_editing_todo(socket, todo)
  end
  defp save_edited_todo(params, socket) do
    todo = socket.assigns.editing_todo
    if (todo == nil), do: socket
    changeset_params = TypeSafeConversions.event_params_to_changeset_params(params)
    changeset = Todo.changeset(todo, changeset_params)
    g = {:Update, changeset}
    case (g.elem(0)) do
      0 ->
        g = g.elem(1)
        updated_todo = g
        g = {:Broadcast, :todo_updates, {:TodoUpdated, updated_todo}}
        case (g.elem(0)) do
          0 ->
            g = g.elem(1)
            nil
          1 ->
            g = g.elem(1)
            reason = g
            Log.trace("Failed to broadcast todo save: " <> reason, %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 506, :className => "server.live.TodoLive", :methodName => "save_edited_todo"})
        end
        updated_socket = update_todo_in_list(updated_todo, socket)
        Phoenix.LiveView.assign(updated_socket, "editing_todo", nil)
      1 ->
        g = g.elem(1)
        reason = g
        Phoenix.LiveView.put_flash(socket, :error, "Failed to save todo: " <> Std.string(reason))
    end
  end
  defp handle_bulk_update(action, socket) do
    case (action.elem(0)) do
      0 ->
        updated_todos = load_todos(socket.assigns.current_user.id)
        current_assigns = socket.assigns
        complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
        Phoenix.LiveView.assign(socket, complete_assigns)
      1 ->
        updated_todos = load_todos(socket.assigns.current_user.id)
        current_assigns = socket.assigns
        complete_assigns = TypeSafeConversions.create_complete_assigns(current_assigns, updated_todos)
        Phoenix.LiveView.assign(socket, complete_assigns)
      2 ->
        g = action.elem(1)
        priority = g
        socket
      3 ->
        g = action.elem(1)
        tag = g
        socket
      4 ->
        g = action.elem(1)
        tag = g
        socket
    end
  end
  defp toggle_tag_filter(tag, socket) do
    selected_tags = socket.assigns.selected_tags
    updated_tags = if (Enum.member?(selected_tags, tag)) do
  Enum.filter(selected_tags, fn t -> t != tag end)
else
  selected_tags ++ [tag]
end
    SafeAssigns.set_selected_tags(socket, updated_tags)
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
    HXX.hxx("\n\t\t\t<div class=\"min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900\">\n\t\t\t\t<div class=\"container mx-auto px-4 py-8 max-w-6xl\">\n\t\t\t\t\t\n\t\t\t\t\t<!-- Header -->\n\t\t\t\t\t<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 mb-8\">\n\t\t\t\t\t\t<div class=\"flex justify-between items-center mb-6\">\n\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t<h1 class=\"text-4xl font-bold text-gray-800 dark:text-white mb-2\">\n\t\t\t\t\t\t\t\t\t📝 Todo Manager\n\t\t\t\t\t\t\t\t</h1>\n\t\t\t\t\t\t\t\t<p class=\"text-gray-600 dark:text-gray-400\">\n\t\t\t\t\t\t\t\t\tWelcome, <%= @current_user.name %>!\n\t\t\t\t\t\t\t\t</p>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t<!-- Statistics -->\n\t\t\t\t\t\t\t<div class=\"flex space-x-6\">\n\t\t\t\t\t\t\t\t<div class=\"text-center\">\n\t\t\t\t\t\t\t\t\t<div class=\"text-3xl font-bold text-blue-600 dark:text-blue-400\">\n\t\t\t\t\t\t\t\t\t\t<%= @total_todos %>\n\t\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\t<div class=\"text-sm text-gray-600 dark:text-gray-400\">Total</div>\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t<div class=\"text-center\">\n\t\t\t\t\t\t\t\t\t<div class=\"text-3xl font-bold text-green-600 dark:text-green-400\">\n\t\t\t\t\t\t\t\t\t\t<%= @completed_todos %>\n\t\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\t<div class=\"text-sm text-gray-600 dark:text-gray-400\">Completed</div>\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t<div class=\"text-center\">\n\t\t\t\t\t\t\t\t\t<div class=\"text-3xl font-bold text-amber-600 dark:text-amber-400\">\n\t\t\t\t\t\t\t\t\t\t<%= @pending_todos %>\n\t\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\t<div class=\"text-sm text-gray-600 dark:text-gray-400\">Pending</div>\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\n\t\t\t\t\t\t<!-- Add Todo Button -->\n\t\t\t\t\t\t<button phx-click=\"toggle_form\" class=\"w-full py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-medium rounded-lg hover:from-blue-600 hover:to-indigo-700 transition-all duration-200 shadow-md\">\n\t\t\t\t\t\t\t<%= if @show_form, do: \"✖ Cancel\", else: \"➕ Add New Todo\" %>\n\t\t\t\t\t\t</button>\n\t\t\t\t\t</div>\n\t\t\t\t\t\n\t\t\t\t\t<!-- New Todo Form -->\n\t\t\t\t\t<%= if @show_form do %>\n\t\t\t\t\t\t<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8 border-l-4 border-blue-500\">\n\t\t\t\t\t\t\t<form phx-submit=\"create_todo\" class=\"space-y-4\">\n\t\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t\t<label class=\"block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2\">\n\t\t\t\t\t\t\t\t\t\tTitle *\n\t\t\t\t\t\t\t\t\t</label>\n\t\t\t\t\t\t\t\t\t<input type=\"text\" name=\"title\" required\n\t\t\t\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\"\n\t\t\t\t\t\t\t\t\t\tplaceholder=\"What needs to be done?\" />\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t\t<label class=\"block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2\">\n\t\t\t\t\t\t\t\t\t\tDescription\n\t\t\t\t\t\t\t\t\t</label>\n\t\t\t\t\t\t\t\t\t<textarea name=\"description\" rows=\"3\"\n\t\t\t\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\"\n\t\t\t\t\t\t\t\t\t\tplaceholder=\"Add more details...\"></textarea>\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t\t<div class=\"grid grid-cols-2 gap-4\">\n\t\t\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t\t\t<label class=\"block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2\">\n\t\t\t\t\t\t\t\t\t\t\tPriority\n\t\t\t\t\t\t\t\t\t\t</label>\n\t\t\t\t\t\t\t\t\t\t<select name=\"priority\"\n\t\t\t\t\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\">\n\t\t\t\t\t\t\t\t\t\t\t<option value=\"low\">Low</option>\n\t\t\t\t\t\t\t\t\t\t\t<option value=\"medium\" selected>Medium</option>\n\t\t\t\t\t\t\t\t\t\t\t<option value=\"high\">High</option>\n\t\t\t\t\t\t\t\t\t\t</select>\n\t\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t\t\t<label class=\"block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2\">\n\t\t\t\t\t\t\t\t\t\t\tDue Date\n\t\t\t\t\t\t\t\t\t\t</label>\n\t\t\t\t\t\t\t\t\t\t<input type=\"date\" name=\"due_date\"\n\t\t\t\t\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\" />\n\t\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t\t<label class=\"block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2\">\n\t\t\t\t\t\t\t\t\t\tTags (comma-separated)\n\t\t\t\t\t\t\t\t\t</label>\n\t\t\t\t\t\t\t\t\t<input type=\"text\" name=\"tags\"\n\t\t\t\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\"\n\t\t\t\t\t\t\t\t\t\tplaceholder=\"work, personal, urgent\" />\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t\t<button type=\"submit\"\n\t\t\t\t\t\t\t\t\tclass=\"w-full py-3 bg-green-500 text-white font-medium rounded-lg hover:bg-green-600 transition-colors shadow-md\">\n\t\t\t\t\t\t\t\t\t✅ Create Todo\n\t\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t</form>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t<% end %>\n\t\t\t\t\t\n\t\t\t\t\t<!-- Filters and Search -->\n\t\t\t\t\t<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8\">\n\t\t\t\t\t\t<div class=\"flex flex-wrap gap-4\">\n\t\t\t\t\t\t\t<!-- Search -->\n\t\t\t\t\t\t\t<div class=\"flex-1 min-w-[300px]\">\n\t\t\t\t\t\t\t\t<form phx-change=\"search_todos\" class=\"relative\">\n\t\t\t\t\t\t\t\t\t<input type=\"search\" name=\"query\" value={@search_query}\n\t\t\t\t\t\t\t\t\t\tclass=\"w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\"\n\t\t\t\t\t\t\t\t\t\tplaceholder=\"Search todos...\" />\n\t\t\t\t\t\t\t\t\t<span class=\"absolute left-3 top-2.5 text-gray-400\">🔍</span>\n\t\t\t\t\t\t\t\t</form>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t<!-- Filter Buttons -->\n\t\t\t\t\t\t\t<div class=\"flex space-x-2\">\n\t\t\t\t\t\t\t\t<button phx-click=\"filter_todos\" phx-value-filter=\"all\"\n\t\t\t\t\t\t\t\t\tclass={\"px-4 py-2 rounded-lg font-medium transition-colors \" <> if @filter == \"all\", do: \"bg-blue-500 text-white\", else: \"bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300\"}>\n\t\t\t\t\t\t\t\t\tAll\n\t\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t\t<button phx-click=\"filter_todos\" phx-value-filter=\"active\"\n\t\t\t\t\t\t\t\t\tclass={\"px-4 py-2 rounded-lg font-medium transition-colors \" <> if @filter == \"active\", do: \"bg-blue-500 text-white\", else: \"bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300\"}>\n\t\t\t\t\t\t\t\t\tActive\n\t\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t\t<button phx-click=\"filter_todos\" phx-value-filter=\"completed\"\n\t\t\t\t\t\t\t\t\tclass={\"px-4 py-2 rounded-lg font-medium transition-colors \" <> if @filter == \"completed\", do: \"bg-blue-500 text-white\", else: \"bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300\"}>\n\t\t\t\t\t\t\t\t\tCompleted\n\t\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t<!-- Sort Dropdown -->\n\t\t\t\t\t\t\t<div>\n\t\t\t\t\t\t\t\t<select phx-change=\"sort_todos\" name=\"sort_by\"\n\t\t\t\t\t\t\t\t\tclass=\"px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\">\n\t\t\t\t\t\t\t\t\t<option value=\"created\" selected={@sort_by == \"created\"}>Sort by Date</option>\n\t\t\t\t\t\t\t\t\t<option value=\"priority\" selected={@sort_by == \"priority\"}>Sort by Priority</option>\n\t\t\t\t\t\t\t\t\t<option value=\"due_date\" selected={@sort_by == \"due_date\"}>Sort by Due Date</option>\n\t\t\t\t\t\t\t\t</select>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t</div>\n\t\t\t\t\t\n\t\t\t\t\t<!-- Bulk Actions -->\n\t\t\t\t\t" <> render_bulk_actions(assigns) <> "\n\t\t\t\t\t\n\t\t\t\t\t<!-- Todo List -->\n\t\t\t\t\t<div class=\"space-y-4\">\n\t\t\t\t\t\t" <> render_todo_list(assigns) <> "\n\t\t\t\t\t</div>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t")
  end
  defp render_bulk_actions(assigns) do
    if (assigns.todos.length == 0), do: ""
    filtered_count = filter_todos(assigns.todos, assigns.filter, assigns.search_query).length
    "<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 mb-6 flex justify-between items-center\">\n\t\t\t\t<div class=\"text-sm text-gray-600 dark:text-gray-400\">\n\t\t\t\t\tShowing " <> filtered_count <> " of " <> assigns.total_todos <> " todos\n\t\t\t\t</div>\n\t\t\t\t<div class=\"flex space-x-2\">\n\t\t\t\t\t<button phx-click=\"bulk_complete\"\n\t\t\t\t\t\tclass=\"px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors text-sm\">\n\t\t\t\t\t\t✅ Complete All\n\t\t\t\t\t</button>\n\t\t\t\t\t<button phx-click=\"bulk_delete_completed\" \n\t\t\t\t\t\tdata-confirm=\"Are you sure you want to delete all completed todos?\"\n\t\t\t\t\t\tclass=\"px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm\">\n\t\t\t\t\t\t🗑️ Delete Completed\n\t\t\t\t\t</button>\n\t\t\t\t</div>\n\t\t\t</div>"
  end
  defp render_todo_list(assigns) do
    if (assigns.todos.length == 0) do
      ~H"""

				<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-16 text-center">
					<div class="text-6xl mb-4">📋</div>
					<h3 class="text-xl font-semibold text-gray-800 dark:text-white mb-2">
						No todos yet!
					</h3>
					<p class="text-gray-600 dark:text-gray-400">
						Click "Add New Todo" to get started.
					</p>
				</div>
			
"""
    end
    filtered_todos = filter_and_sort_todos(assigns.todos, assigns.filter, assigns.sort_by, assigns.search_query)
    todo_items = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (g < filtered_todos.length) do
    todo = filtered_todos[g]
    g = g + 1
    todo_items.push(render_todo_item(todo, assigns.editing_todo))
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    Enum.join(todo_items, "\n")
  end
  defp render_todo_item(todo, editing_todo) do
    is_editing = editing_todo != nil && editing_todo.id == todo.id
    priority_color = g = todo.priority
case (g) do
  "high" ->
    "border-red-500"
  "low" ->
    "border-green-500"
  "medium" ->
    "border-yellow-500"
  _ ->
    "border-gray-300"
end
    if is_editing do
      "<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 " <> priority_color <> "\">\n\t\t\t\t\t<form phx-submit=\"save_todo\" class=\"space-y-4\">\n\t\t\t\t\t\t<input type=\"hidden\" name=\"id\" value=\"" <> todo.id <> "\" />\n\t\t\t\t\t\t<input type=\"text\" name=\"title\" value=\"" <> todo.title <> "\" required\n\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\" />\n\t\t\t\t\t\t<textarea name=\"description\" rows=\"2\"\n\t\t\t\t\t\t\tclass=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\">" <> todo.description <> "</textarea>\n\t\t\t\t\t\t<div class=\"flex space-x-2\">\n\t\t\t\t\t\t\t<button type=\"submit\" class=\"px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600\">\n\t\t\t\t\t\t\t\tSave\n\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t<button type=\"button\" phx-click=\"cancel_edit\" class=\"px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400\">\n\t\t\t\t\t\t\t\tCancel\n\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t</form>\n\t\t\t\t</div>"
    else
      completed_class = if (todo.completed), do: "opacity-60", else: ""
      text_decoration = if (todo.completed), do: "line-through", else: ""
      checkmark = if (todo.completed), do: "<span class=\"text-green-500\">✓</span>", else: ""
      "<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 " <> priority_color <> " " <> completed_class <> " transition-all hover:shadow-xl\">\n\t\t\t\t\t<div class=\"flex items-start space-x-4\">\n\t\t\t\t\t\t<!-- Checkbox -->\n\t\t\t\t\t\t<button phx-click=\"toggle_todo\" phx-value-id=\"" <> todo.id <> "\"\n\t\t\t\t\t\t\tclass=\"mt-1 w-6 h-6 rounded border-2 border-gray-300 dark:border-gray-600 flex items-center justify-center hover:border-blue-500 transition-colors\">\n\t\t\t\t\t\t\t" <> checkmark <> "\n\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\n\t\t\t\t\t\t<!-- Content -->\n\t\t\t\t\t\t<div class=\"flex-1\">\n\t\t\t\t\t\t\t<h3 class=\"text-lg font-semibold text-gray-800 dark:text-white " <> text_decoration <> "\">\n\t\t\t\t\t\t\t\t" <> todo.title <> "\n\t\t\t\t\t\t\t</h3>\n\t\t\t\t\t\t\t" <> (if (todo.description != nil && todo.description != ""), do: "<p class=\"text-gray-600 dark:text-gray-400 mt-1 " <> text_decoration <> "\">" <> todo.description <> "</p>", else: "") <> "\n\t\t\t\t\t\t\t\n\t\t\t\t\t\t\t<!-- Meta info -->\n\t\t\t\t\t\t\t<div class=\"flex flex-wrap gap-2 mt-3\">\n\t\t\t\t\t\t\t\t<span class=\"px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs\">\n\t\t\t\t\t\t\t\t\tPriority: " <> todo.priority <> "\n\t\t\t\t\t\t\t\t</span>\n\t\t\t\t\t\t\t\t" <> (if (todo.due_date != nil) do
  "<span class=\"px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs\">Due: " <> Std.string(todo.due_date) <> "</span>"
else
  ""
end) <> "\n\t\t\t\t\t\t\t\t" <> render_tags(todo.tags) <> "\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\n\t\t\t\t\t\t<!-- Actions -->\n\t\t\t\t\t\t<div class=\"flex space-x-2\">\n\t\t\t\t\t\t\t<button phx-click=\"edit_todo\" phx-value-id=\"" <> todo.id <> "\"\n\t\t\t\t\t\t\t\tclass=\"p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition-colors\">\n\t\t\t\t\t\t\t\t✏️\n\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t\t<button phx-click=\"delete_todo\" phx-value-id=\"" <> todo.id <> "\"\n\t\t\t\t\t\t\t\tdata-confirm=\"Are you sure?\"\n\t\t\t\t\t\t\t\tclass=\"p-2 text-red-600 hover:bg-red-100 rounded-lg transition-colors\">\n\t\t\t\t\t\t\t\t🗑️\n\t\t\t\t\t\t\t</button>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t</div>\n\t\t\t\t</div>"
    end
  end
  defp render_tags(tags) do
    if (tags == nil || tags.length == 0), do: ""
    tag_elements = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (g < tags.length) do
    tag = tags[g]
    g = g + 1
    tag_elements.push("<button phx-click=\"toggle_tag\" phx-value-tag=\"" <> tag <> "\" class=\"px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400 rounded text-xs hover:bg-blue-200\">#" <> tag <> "</button>")
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    Enum.join(tag_elements, "")
  end
  defp filter_todos(todos, filter, search_query) do
    filtered = todos
    filtered = case (filter) do
  "active" ->
    Enum.filter(filtered, fn t -> not t.completed end)
  "completed" ->
    Enum.filter(filtered, fn t -> t.completed end)
  _ ->
    filtered
end
    if (search_query != nil && search_query != "") do
      query = search_query.toLowerCase()
      filtered = Enum.filter(filtered, fn t -> t.title.toLowerCase().indexOf(query) >= 0 || t.description != nil && t.description.toLowerCase().indexOf(query) >= 0 end)
    end
    filtered
  end
  defp filter_and_sort_todos(todos, filter, sort_by, search_query) do
    filtered = filter_todos(todos, filter, search_query)
    filtered
  end
end