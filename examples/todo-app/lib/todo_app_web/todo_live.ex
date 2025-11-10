defmodule TodoAppWeb.TodoLive do
  use Phoenix.Component
  use TodoAppWeb, :live_view
  require Ecto.Query
  def mount(_params, session, socket) do
    sock = socket
    current_user = get_user_from_session(session)
    todos = load_todos(current_user.id)
    assigns = %{:todos => todos, :filter => {:all}, :sort_by => {:created}, :current_user => current_user, :editing_todo => nil, :show_form => false, :search_query => "", :selected_tags => [], :optimistic_toggle_ids => [], :visible_todos => [], :visible_count => 0, :filter_btn_all_class => "px-4 py-2 rounded-lg font-medium transition-colors bg-blue-500 text-white", :filter_btn_active_class => "px-4 py-2 rounded-lg font-medium transition-colors bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300", :filter_btn_completed_class => "px-4 py-2 rounded-lg font-medium transition-colors bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300", :sort_selected_created => true, :sort_selected_priority => false, :sort_selected_due_date => false, :total_todos => length(todos), :completed_todos => count_completed(todos), :pending_todos => count_pending(todos), :online_users => %{}}
    sock = Phoenix.Component.assign(sock, assigns)
    ls = recompute_visible(sock)
    {:ok, ls}
  end
  def handle_info(msg, socket) do
    (case TodoPubSub.parse_message(msg) do
      {:some, payload} ->
        value = payload
        (case payload do
          {:todo_created, _value} -> {:noreply, recompute_visible(Phoenix.Component.assign(socket, %{:todos => load_todos(socket.assigns.current_user.id)}))}
          {:todo_updated, value} -> {:noreply, recompute_visible(update_todo_in_list(value, value))}
          {:todo_deleted, value} -> {:noreply, recompute_visible(remove_todo_from_list(value, value))}
          {:bulk_update, {:complete_all}} -> {:noreply, recompute_visible(Phoenix.Component.assign(socket, %{:todos => load_todos(socket.assigns.current_user.id), :total_todos => length(load_todos(socket.assigns.current_user.id)), :completed_todos => count_completed(load_todos(socket.assigns.current_user.id)), :pending_todos => count_pending(load_todos(socket.assigns.current_user.id))}))}
          {:bulk_update, {:set_priority, value}} -> {:noreply, payload}
          {:bulk_update, {:add_tag, value}} -> {:noreply, payload}
          {:bulk_update, {:remove_tag, value}} -> {:noreply, payload}
          {:user_online, value} -> {:noreply, value}
          {:user_offline, value} -> {:noreply, value}
          {:system_alert, _message, _flash_type} -> {:noreply, payload}
        end)
      {:none} ->
        Log.trace("Received unknown PubSub message: #{(fn -> inspect(msg) end).()}", %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 309, :class_name => "server.live.TodoLive", :method_name => "handleInfo"})
        {:noreply, socket}
    end)
  end
  defp create_todo(params, socket) do
    raw_title = Map.get(params, "title")
    raw_desc = Map.get(params, "description")
    raw_priority = Map.get(params, "priority")
    raw_due = Map.get(params, "due_date")
    raw_tags = Map.get(params, "tags")
    title = if (not Kernel.is_nil(raw_title)), do: raw_title, else: ""
    description = if (not Kernel.is_nil(raw_desc)), do: raw_desc, else: ""
    priority = if (not Kernel.is_nil(raw_priority) and raw_priority != ""), do: raw_priority, else: "medium"
    tags_arr = if (not Kernel.is_nil(raw_tags) and raw_tags != ""), do: parse_tags(raw_tags), else: []
    _raw_params_completed = false
    _raw_params_due_date = if (not Kernel.is_nil(raw_due) and raw_due != ""), do: raw_due, else: nil
    _raw_params_user_id = socket.assigns.current_user.id
    todo_struct = %TodoApp.Todo{}
    permitted = ["title", "description", "completed", "priority", "due_date", "tags", "user_id"]
    cast_params = %{:title => title, :description => description, :completed => false, :priority => priority, :due_date => (if (not Kernel.is_nil(raw_due) and raw_due != "") do
  if (case :binary.match(raw_due, ":") do
                {pos, _} -> pos
                :nomatch -> -1
            end == -1) do
    Kernel.to_string(raw_due) <> " 00:00:00"
  else
    raw_due
  end
else
  nil
end), :tags => tags_arr, :user_id => socket.assigns.current_user.id}
    cs = Ecto.Changeset.cast(todo_struct, cast_params, Enum.map(permitted, &String.to_atom/1))
    (case TodoApp.Repo.insert(cs) do
      {:ok, value} ->
        TodoPubSub.broadcast({:todo_updates}, {:todo_created, value})
        todos = [value] ++ socket.assigns.todos
        updated = assigns = %{:todos => todos, :show_form => false, :total_todos => socket.assigns.total_todos + 1, :pending_todos => socket.assigns.pending_todos + (if (value.completed), do: 0, else: 1), :completed_todos => socket.assigns.completed_todos + (if (value.completed), do: 1, else: 0)}
        Phoenix.Component.assign(socket, assigns)
        ls_created = recompute_visible(updated)
        Phoenix.LiveView.put_flash(ls_created, String.to_atom(FlashTypeTools.to_phoenix_key({:success})), "Todo created successfully!")
      {:error, _reason} -> Phoenix.LiveView.put_flash(socket, String.to_atom(FlashTypeTools.to_phoenix_key({:error})), "Failed to create todo")
    end)
  end
  defp toggle_todo_status(id, socket) do
    s = socket
    ids = s.assigns.optimistic_toggle_ids
    contains = (

                case Enum.find_index(ids, fn item -> item == id end) do
                    nil -> -1
                    idx -> idx
                end
            
) != -1
    computed_ids = if (contains), do: Enum.filter(ids, fn x -> x != id end), else: [id] ++ ids
    s_optimistic = Phoenix.Component.assign(s, :optimistic_toggle_ids, computed_ids)
    local = find_todo(id, s.assigns.todos)
    if (not Kernel.is_nil(local)) do
      toggled = local
      toggled = Map.put(toggled, "completed", not local.completed)
      s_optimistic = update_todo_in_list(toggled, s_optimistic)
    end
    db = TodoApp.Repo.get(TodoApp.Todo, id)
    if (not Kernel.is_nil(db)) do
      update_result = TodoApp.Repo.update(TodoApp.Todo.toggle_completed(db))
      (case update_result do
        {:ok, value} ->
          todo_updates = value
          todo_updated = value
          broadcast = value
          TodoPubSub.broadcast({:todo_updates}, {:todo_updated, value})
        {:error, db} ->
          TodoPubSub.broadcast({:todo_updates}, {:todo_updated, db})
      end)
    end
    recompute_visible(s_optimistic)
  end
  defp delete_todo(id, socket) do
    Log.trace("[TodoLive] deleteTodo id=#{(fn -> Kernel.to_string(id) end).()}, before_count=#{(fn -> Kernel.to_string(length(socket.assigns.todos)) end).()}", %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 455, :class_name => "server.live.TodoLive", :method_name => "deleteTodo"})
    todo = find_todo(id, socket.assigns.todos)
    if (Kernel.is_nil(todo)), do: socket
    (case TodoApp.Repo.delete(todo) do
      {:ok, _g} -> nil
      {:error, _reason} -> Phoenix.LiveView.put_flash(socket, String.to_atom(FlashTypeTools.to_phoenix_key({:error})), "Failed to delete todo")
    end)
    updated = remove_todo_from_list(id, socket)
    TodoPubSub.broadcast({:todo_updates}, {:todo_deleted, id})
    recompute_visible(updated)
  end
  defp update_todo_priority(id, priority, socket) do
    todo = find_todo(id, socket.assigns.todos)
    if (Kernel.is_nil(todo)), do: socket
    (case TodoApp.Repo.update(TodoApp.Todo.update_priority(todo, priority)) do
      {:ok, _g} -> nil
      {:error, _reason} -> Phoenix.LiveView.put_flash(socket, String.to_atom(FlashTypeTools.to_phoenix_key({:error})), "Failed to update priority")
    end)
    refreshed = TodoApp.Repo.get(TodoApp.Todo, id)
    if (not Kernel.is_nil(refreshed)) do
      TodoPubSub.broadcast({:todo_updates}, {:todo_updated, refreshed})
      s1 = update_todo_in_list(refreshed, socket)
      recompute_visible(s1)
    end
    socket
  end
  defp load_todos(user_id) do
    TodoApp.Repo.all((fn ->
      query = Ecto.Query.where((fn -> query2 = Ecto.Query.from(t in TodoApp.Todo, [])
      this1 = nil
      this1 = query2
      this1 end).(), [t], t.user_id == ^(user_id))
      this1 = nil
      this1 = query
      this1
    end).())
  end
  defp find_todo(id, todos) do
    Enum.find(todos, fn item -> item.id == id end)
  end
  defp count_completed(todos) do
    length(Enum.filter(todos, fn t -> t.completed end))
  end
  defp count_pending(todos) do
    length(Enum.filter(todos, fn t -> not t.completed end))
  end
  defp parse_tags(tags_string) do
    if (Kernel.is_nil(tags_string) or tags_string == ""), do: {:some, []}
    Enum.map(String.split(tags_string, ","), fn t -> StringTools.ltrim(StringTools.rtrim(t)) end)
  end
  defp get_user_from_session(session) do
    uid = if (Kernel.is_nil(session)) do
      1
    else
      id_val = Map.get(session, "user_id")
      if (not Kernel.is_nil(id_val)), do: id_val, else: 1
    end
    %{:id => uid, :name => "Demo User", :email => "demo@example.com", :password_hash => "hashed_password", :confirmed_at => nil, :last_login_at => nil, :active => true}
  end
  defp update_todo_in_list(todo, socket) do
    new_todos = Enum.map(socket.assigns.todos, (fn -> fn t ->
        if (t.id == todo.id), do: todo, else: t
      end end).())
    Phoenix.Component.assign(socket, %{:todos => new_todos, :total_todos => length(new_todos), :completed_todos => count_completed(new_todos), :pending_todos => count_pending(new_todos)})
  end
  defp build_visible_todos(a) do
    base = filter_and_sort_todos(a.todos, a.filter, a.sort_by, a.search_query, a.selected_tags)
    optimistic = if (not Kernel.is_nil(a.optimistic_toggle_ids)), do: a.optimistic_toggle_ids, else: []
    Enum.map(base, (fn -> fn todo_item ->
        flipped = Enum.member?(optimistic, todo_item.id)
        completed_for_view = if (flipped) do
          not todo_item.completed
        else
          todo_item.completed
        end
        border = ((case todo_item.priority do
  "high" -> "border-red-500"
  "low" -> "border-green-500"
  "medium" -> "border-yellow-500"
  _ -> "border-gray-300"
end))
        container_class = "bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 " <> border <> (if (completed_for_view), do: " opacity-60", else: "") <> " transition-all hover:shadow-xl"
        has_due = not Kernel.is_nil(todo_item.due_date)
        due_display = if (has_due) do
          d = todo_item.due_date
          if (Kernel.is_nil(d)), do: "", else: inspect(d)
        else
          ""
        end
        has_tags = not Kernel.is_nil(todo_item.tags) and length(todo_item.tags) > 0
        has_description = not Kernel.is_nil(todo_item.description) and todo_item.description != ""
        is_editing = not Kernel.is_nil(a.editing_todo) and a.editing_todo.id == todo_item.id
        %{:id => todo_item.id, :title => todo_item.title, :description => todo_item.description, :completed_for_view => completed_for_view, :completed_str => (if (completed_for_view), do: "true", else: "false"), :dom_id => "todo-" <> inspect(todo_item.id), :container_class => container_class, :title_class => "text-lg font-semibold text-gray-800 dark:text-white" <> (if (completed_for_view), do: " line-through", else: ""), :desc_class => "text-gray-600 dark:text-gray-400 mt-1" <> (if (completed_for_view), do: " line-through", else: ""), :priority => todo_item.priority, :has_due => has_due, :due_display => due_display, :has_tags => has_tags, :has_description => has_description, :is_editing => is_editing, :tags => (if (not Kernel.is_nil(todo_item.tags)), do: todo_item.tags, else: [])}
      end end).())
  end
  defp recompute_visible(socket) do
    ls = socket
    rows = build_visible_todos(ls.assigns)
    selected = ls.assigns.sort_by
    filter = ls.assigns.filter
    Phoenix.Component.assign(ls, %{:visible_todos => rows, :visible_count => length(rows), :filter_btn_all_class => "px-4 py-2 rounded-lg font-medium transition-colors" <> (if (filter == {:all}), do: " bg-blue-500 text-white", else: " bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300"), :filter_btn_active_class => "px-4 py-2 rounded-lg font-medium transition-colors" <> (if (filter == {:active}), do: " bg-blue-500 text-white", else: " bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300"), :filter_btn_completed_class => "px-4 py-2 rounded-lg font-medium transition-colors" <> (if (filter == {:completed}), do: " bg-blue-500 text-white", else: " bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300"), :sort_selected_created => selected == {:created}, :sort_selected_priority => selected == {:priority}, :sort_selected_due_date => selected == {:due_date}})
  end
  defp remove_todo_from_list(id, socket) do
    Phoenix.Component.assign(socket, %{:todos => Enum.filter(socket.assigns.todos, fn t -> t.id != id end), :total_todos => length(Enum.filter(socket.assigns.todos, fn t -> t.id != id end)), :completed_todos => count_completed(Enum.filter(socket.assigns.todos, fn t -> t.id != id end)), :pending_todos => count_pending(Enum.filter(socket.assigns.todos, fn t -> t.id != id end))})
  end
  defp start_editing(id, socket) do
    s1 = SafeAssigns.set_editing_todo(socket, find_todo(id, socket.assigns.todos))
    recompute_visible(s1)
  end
  defp complete_all_todos(socket) do
    list = socket.assigns.todos
    Enum.each(list, (fn -> fn item ->
            if (not item.completed) do
        cs = TodoApp.Todo.toggle_completed(item)
        (case TodoApp.Repo.update(cs) do
          {:ok, value} -> nil
          {:error, reason} -> nil
        end)
      end
    end end).())
    TodoPubSub.broadcast({:todo_updates}, {:bulk_update, {:complete_all}})
    ls = Phoenix.Component.assign(socket, %{:todos => load_todos(socket.assigns.current_user.id), :filter => socket.assigns.filter, :sort_by => socket.assigns.sort_by, :current_user => socket.assigns.current_user, :editing_todo => socket.assigns.editing_todo, :show_form => socket.assigns.show_form, :search_query => socket.assigns.search_query, :selected_tags => socket.assigns.selected_tags, :total_todos => length(load_todos(socket.assigns.current_user.id)), :completed_todos => length(load_todos(socket.assigns.current_user.id)), :pending_todos => 0, :online_users => socket.assigns.online_users})
    ls_vis = recompute_visible(ls)
    Phoenix.LiveView.put_flash(ls_vis, String.to_atom(FlashTypeTools.to_phoenix_key({:info})), "All todos marked as completed!")
  end
  defp delete_completed_todos(socket) do
    list = socket.assigns.todos
    Enum.each(list, (fn -> fn item ->
            if (item.completed) do
        TodoApp.Repo.delete(item)
      end
    end end).())
    TodoPubSub.broadcast({:todo_updates}, {:bulk_update, {:delete_completed}})
    ls2 = Phoenix.Component.assign(socket, %{:todos => Enum.filter(socket.assigns.todos, fn t -> not t.completed end), :filter => socket.assigns.filter, :sort_by => socket.assigns.sort_by, :current_user => socket.assigns.current_user, :editing_todo => socket.assigns.editing_todo, :show_form => socket.assigns.show_form, :search_query => socket.assigns.search_query, :selected_tags => socket.assigns.selected_tags, :total_todos => length(Enum.filter(socket.assigns.todos, fn t -> not t.completed end)), :completed_todos => 0, :pending_todos => length(Enum.filter(socket.assigns.todos, fn t -> not t.completed end)), :online_users => socket.assigns.online_users})
    ls2_vis = recompute_visible(ls2)
    Phoenix.LiveView.put_flash(ls2_vis, String.to_atom(FlashTypeTools.to_phoenix_key({:info})), "Completed todos deleted!")
  end
  defp save_edited_todo_typed(params, socket) do
    if (Kernel.is_nil(socket.assigns.editing_todo)), do: socket
    todo = socket.assigns.editing_todo
    (case TodoApp.Repo.update((fn -> TodoApp.Todo.changeset(todo, (fn -> %{:title => if (Map.get(params, "title") != nil) do
  Map.get(params, "title")
else
  todo.title
end} end).()) end).()) do
      {:ok, value} ->
        ls = update_todo_in_list(value, value)
        TodoPubSub.broadcast({:todo_updates}, {:todo_updated, value})
        ls = Phoenix.Component.assign(ls, :editing_todo, nil)
        ls = recompute_visible(ls)
        ls
      {:error, _g} -> Phoenix.LiveView.put_flash(socket, String.to_atom(FlashTypeTools.to_phoenix_key({:error})), "Failed to update todo")
    end)
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
    ~H"""
			<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
				<div id="root" class="container mx-auto px-4 py-8 max-w-6xl" phx-hook="Ping">
					
					<!-- Header -->
					<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 mb-8">
						<div class="flex justify-between items-center mb-6">
							<div>
								<h1 class="text-4xl font-bold text-gray-800 dark:text-white mb-2">
									📝 Todo Manager
								</h1>
								<p class="text-gray-600 dark:text-gray-400">
									Welcome, <%= @current_user.name %>!
								</p>
							</div>
							
							<!-- Statistics -->
							<div class="flex space-x-6">
								<div class="text-center">
									<div class="text-3xl font-bold text-blue-600 dark:text-blue-400">
										<%= Kernel.to_string(@total_todos) %>
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Total</div>
								</div>
								<div class="text-center">
									<div class="text-3xl font-bold text-green-600 dark:text-green-400">
										<%= Kernel.to_string(@completed_todos) %>
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Completed</div>
								</div>
								<div class="text-center">
									<div class="text-3xl font-bold text-amber-600 dark:text-amber-400">
										<%= Kernel.to_string(@pending_todos) %>
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Pending</div>
								</div>
							</div>
						</div>
						
						<!-- Add Todo Button -->
						<button phx-click="toggle_form" data-testid="btn-new-todo" class="w-full py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-medium rounded-lg hover:from-blue-600 hover:to-indigo-700 transition-all duration-200 shadow-md">
							<%= if (@show_form), do: "✖ Cancel", else: "➕ Add New Todo" %>
						</button>
					</div>
					
					<!-- New Todo Form -->
					<%= if @show_form do %>
						<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8 border-l-4 border-blue-500">
							<form phx-submit="create_todo" class="space-y-4">
								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Title *
									</label>
									<input type="text" name="title" required data-testid="input-title"
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="What needs to be done?" />
								</div>

								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Description
									</label>
									<textarea name="description" rows="3"
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="Add more details..."></textarea>
								</div>

								<div class="grid grid-cols-2 gap-4">
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Priority
										</label>
										<select name="priority"
											class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
											<option value="low">Low</option>
											<option value="medium" selected>Medium</option>
											<option value="high">High</option>
										</select>
									</div>

									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Due Date
										</label>
                            <input type="date" name="due_date"
                                placeholder="YYYY-MM-DD"
                                class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
									</div>
								</div>

								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Tags (comma-separated)
									</label>
									<input type="text" name="tags"
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="work, personal, urgent" />
								</div>

									<button type="submit" data-testid="btn-create-todo"
									class="w-full py-3 bg-green-500 text-white font-medium rounded-lg hover:bg-green-600 transition-colors shadow-md">
									✅ Create Todo
								</button>
							</form>
						</div>
					<% end %>
					
					<!-- Filters and Search -->
					<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8">
						<div class="flex flex-wrap gap-4">
							<!-- Search -->
							<div class="flex-1 min-w-[300px]">
                            <form phx-change="search_todos" class="relative">
									<input type="search" name="query" value={@search_query}
										class="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="Search todos..." />
									<span class="absolute left-3 top-2.5 text-gray-400">🔍</span>
								</form>
							</div>
							
                        <!-- Filter Buttons -->
                        <div class="flex space-x-2">
                            <button phx-click="filter_todos" phx-value-filter="all" data-testid="btn-filter-all"
                                class={@filter_btn_all_class}>All</button>
                            <button phx-click="filter_todos" phx-value-filter="active" data-testid="btn-filter-active"
                                class={@filter_btn_active_class}>Active</button>
                            <button phx-click="filter_todos" phx-value-filter="completed" data-testid="btn-filter-completed"
                                class={@filter_btn_completed_class}>Completed</button>
                        </div>
							
							<!-- Sort Dropdown -->
							<div>
                            <select phx-change="sort_todos" name="sort_by"
                                class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
                                <option value="created" selected={@sort_selected_created}>Sort by Date</option>
                                <option value="priority" selected={@sort_selected_priority}>Sort by Priority</option>
                                <option value="due_date" selected={@sort_selected_due_date}>Sort by Due Date</option>
                            </select>
							</div>
						</div>
					</div>
					
					<!-- Online Users Panel -->
                    <!-- Presence panel (optional) -->
					
					<!-- Bulk Actions -->
                    <!-- Bulk Actions (typed HXX) -->
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 mb-6 flex justify-between items-center">
                        <div class="text-sm text-gray-600 dark:text-gray-400">
                            Showing <%= @visible_count %> of <%= @total_todos %> todos
                        </div>
                        <div class="flex space-x-2">
                            <button phx-click="bulk_complete"
                                class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors text-sm">✅ Complete All</button>
                            <button phx-click="bulk_delete_completed" data-confirm="Are you sure you want to delete all completed todos?"
                                class="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm">🗑️ Delete Completed</button>
                        </div>
                    </div>
					
					<!-- Todo List -->
                    <div id="todo-list" class="space-y-4">
                        <%= for v <- @visible_todos do %>
                            <%= if v.is_editing do %>
                                <div id={v.dom_id} data-testid="todo-card" data-completed={v.completed_str}
                                    class={v.container_class}>
                                    <form phx-submit="save_todo" class="space-y-4">
                                        <input type="text" name="title" value={v.title} required data-testid="input-title"
                                            class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
                                        <textarea name="description" rows="2"
                                            class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"><%= v.description %></textarea>
                                        <div class="flex space-x-2">
                                            <button type="submit" class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600">Save</button>
                                            <button type="button" phx-click="cancel_edit" class="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400">Cancel</button>
                                        </div>
                                    </form>
                                </div>
                            <% else %>
                                <div id={v.dom_id} data-testid="todo-card" data-completed={v.completed_str}
                                    class={v.container_class}>
                                    <div class="flex items-start space-x-4">
                                        <!-- Checkbox -->
                                        <button type="button" phx-click="toggle_todo" phx-value-id={v.id} data-testid="btn-toggle-todo"
                                            class="mt-1 w-6 h-6 rounded border-2 border-gray-300 dark:border-gray-600 flex items-center justify-center hover:border-blue-500 transition-colors">
                                            <%= if v.completed_for_view do %>
                                                <span class="text-green-500">✓</span>
                                            <% end %>
                                        </button>

                                        <!-- Content -->
                                        <div class="flex-1">
                                            <h3 class={v.title_class}>
                                                <%= v.title %>
                                            </h3>
                                            <%= if v.has_description do %>
                                                <p class={v.desc_class}>
                                                    <%= v.description %>
                                                </p>
                                            <% end %>

                                            <!-- Meta info -->
                                            <div class="flex flex-wrap gap-2 mt-3">
                                                <span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">
                                                    Priority: <%= v.priority %>
                                                </span>
                                                <%= if v.has_due do %>
                                                    <span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">
                                                        Due: <%= v.due_display %>
                                                    </span>
                                                <% end %>
                                                <%= if v.has_tags do %>
                                                    <%= for tag <- v.tags do %>
                                                        <button phx-click="search_todos" phx-value-query={tag}
                                                            class="px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400 rounded text-xs hover:bg-blue-200"><%= tag %></button>
                                                    <% end %>
                                                <% end %>
                                            </div>
                                        </div>

                                        <!-- Actions -->
                                        <div class="flex space-x-2">
                                            <button type="button" phx-click="edit_todo" phx-value-id={v.id} data-testid="btn-edit-todo"
                                                class="p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition-colors">✏️</button>
                                            <button type="button" phx-click="delete_todo" phx-value-id={v.id} data-testid="btn-delete-todo"
                                                class="p-2 text-red-600 hover:bg-red-100 rounded-lg transition-colors">🗑️</button>
                                        </div>
                                    </div>
                                </div>
                            <% end %>
                        <% end %>
                    </div>
                </div>
            </div>
"""
  end
  def render_presence_panel(online_users) do
    ""
  end
  def render_bulk_actions(assigns) do
    if (length(assigns.todos) == 0), do: ""
    filtered_count = length(filter_todos(assigns.todos, assigns.filter, assigns.search_query))
    (
"<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 mb-6 flex justify-between items-center\">
				<div class=\"text-sm text-gray-600 dark:text-gray-400\">
					Showing #{(fn -> Kernel.to_string(filtered_count) end).()} of #{(fn -> Kernel.to_string(assigns.total_todos) end).()} todos
				</div>
				<div class=\"flex space-x-2\">
					<button phx-click=\"bulk_complete\"
						class=\"px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors text-sm\">
						✅ Complete All
					</button>
					<button phx-click=\"bulk_delete_completed\" 
						data-confirm=\"Are you sure you want to delete all completed todos?\"
						class=\"px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm\">
						🗑️ Delete Completed
					</button>
				</div>
			</div>"
)
  end
  def render_todo_list(assigns) do
    if (length(assigns.todos) == 0), do: "\n\t\t\t\t<div class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-16 text-center\">\n\t\t\t\t\t<div class=\"text-6xl mb-4\">📋</div>\n\t\t\t\t\t<h3 class=\"text-xl font-semibold text-gray-800 dark:text-white mb-2\">\n\t\t\t\t\t\tNo todos yet!\n\t\t\t\t\t</h3>\n\t\t\t\t\t<p class=\"text-gray-600 dark:text-gray-400\">\n\t\t\t\t\t\tClick \"Add New Todo\" to get started.\n\t\t\t\t\t</p>\n\t\t\t\t</div>\n\t\t\t"
    filtered_todos = filter_and_sort_todos(assigns.todos, assigns.filter, assigns.sort_by, assigns.search_query, assigns.selected_tags)
    todo_items = Enum.map(filtered_todos, fn assigns -> render_todo_item(assigns, assigns.editing_todo) end)
    Enum.join((fn -> "\n" end).())
  end
  defp render_todo_item(todo, editing_todo) do
    is_editing = not Kernel.is_nil(editing_todo) and editing_todo.id == todo.id
    priority_color = _g = todo.priority
    (case priority_color do
      "high" -> "border-red-500"
      "low" -> "border-green-500"
      "medium" -> "border-yellow-500"
      _ -> "border-gray-300"
    end)
    if (is_editing) do
      (
"<div id=\"todo-#{(fn -> Kernel.to_string(todo.id) end).()}\" data-testid=\"todo-card\" data-completed=\"#{(fn -> inspect(todo.completed) end).()}\" class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 #{(fn -> priority_color end).()}\">
					<form phx-submit=\"save_todo\" class=\"space-y-4\">
						<input type=\"text\" name=\"title\" value=\"#{(fn -> todo.title end).()}\" required data-testid=\"input-title\"
							class=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\" />
						<textarea name=\"description\" rows=\"2\"
							class=\"w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white\">#{(fn -> todo.description end).()}</textarea>
						<div class=\"flex space-x-2\">
							<button type=\"submit\" class=\"px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600\">
								Save
							</button>
							<button type=\"button\" phx-click=\"cancel_edit\" class=\"px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400\">
								Cancel
							</button>
						</div>
					</form>
				</div>"
)
    else
      completed_class = if (todo.completed), do: "opacity-60", else: ""
      text_decoration = if (todo.completed), do: "line-through", else: ""
      checkmark = if (todo.completed), do: "<span class=\"text-green-500\">✓</span>", else: ""
      (
"<div id=\"todo-#{(fn -> Kernel.to_string(todo.id) end).()}\" data-testid=\"todo-card\" data-completed=\"#{(fn -> inspect(todo.completed) end).()}\" class=\"bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 #{(fn -> priority_color end).()} #{(fn -> completed_class end).()} transition-all hover:shadow-xl\">
					<div class=\"flex items-start space-x-4\">
                        <!-- Checkbox -->
                            <button type=\"button\" phx-click=\"toggle_todo\" phx-value-id=\"#{(fn -> Kernel.to_string(todo.id) end).()}\" data-testid=\"btn-toggle-todo\"
                                class=\"mt-1 w-6 h-6 rounded border-2 border-gray-300 dark:border-gray-600 flex items-center justify-center hover:border-blue-500 transition-colors\">
                                #{(fn -> checkmark end).()}
                            </button>
						
						<!-- Content -->
						<div class=\"flex-1\">
							<h3 class=\"text-lg font-semibold text-gray-800 dark:text-white #{(fn -> text_decoration end).()}\">
								#{(fn -> todo.title end).()}
							</h3>
							#{(fn -> if (todo.description != nil and todo.description != "") do
  "<p class=\"text-gray-600 dark:text-gray-400 mt-1 #{(fn -> text_decoration end).()}\">#{(fn -> todo.description end).()}</p>"
else
  ""
end end).()}
							
							<!-- Meta info -->
							<div class=\"flex flex-wrap gap-2 mt-3\">
								<span class=\"px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs\">
									Priority: #{(fn -> todo.priority end).()}
								</span>
                                #{(fn -> if (todo.due_date != nil) do
  (
"<span class=\"px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs\">Due: #{(fn -> d = todo.due_date
if (d == nil), do: "", else: inspect(d) end).()}</span>"
)
else
  ""
end end).()}
								#{(fn -> render_tags(todo.tags) end).()}
							</div>
						</div>
						
						<!-- Actions -->
						<div class=\"flex space-x-2\">
                                            <button type=\"button\" phx-click=\"edit_todo\" phx-value-id=\"#{(fn -> Kernel.to_string(todo.id) end).()}\" data-testid=\"btn-edit-todo\"
                                    class=\"p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition-colors\">
                                    ✏️
                                </button>
                                            <button type=\"button\" phx-click=\"delete_todo\" phx-value-id=\"#{(fn -> Kernel.to_string(todo.id) end).()}\" data-testid=\"btn-delete-todo\"
                                    class=\"p-2 text-red-600 hover:bg-red-100 rounded-lg transition-colors\">
                                    🗑️
                                </button>
						</div>
					</div>
				</div>"
)
    end
  end
  defp render_tags(tags) do
    if (Kernel.is_nil(tags) or length(tags) == 0), do: ""
    tags_norm = if (not Kernel.is_nil(tags)), do: tags, else: []
    tag_elements = Enum.map(tags_norm, fn tag -> "<button phx-click=\"search_todos\" phx-value-query=\"" <> tag <> "\" class=\"px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400 rounded text-xs hover:bg-blue-200\">#" <> tag <> "</button>" end)
    Enum.join((fn -> "" end).())
  end
  defp filter_todos(todos, filter, search_query) do
    base = ((case filter do
  {:all} -> todos
  {:active} ->
    Enum.filter(todos, fn t -> not t.completed end)
  {:completed} ->
    Enum.filter(todos, fn t -> t.completed end)
end))
    ql_opt = if (not Kernel.is_nil(search_query) and search_query != "") do
      String.downcase(search_query)
    else
      nil
    end
    if (Kernel.is_nil(ql_opt)), do: base, else: Enum.filter(base, (fn -> fn t ->
    title = if (not Kernel.is_nil(t.title)) do
      _this = t.title
      String.downcase(_this)
    else
      ""
    end
    desc = if (not Kernel.is_nil(t.description)) do
      _this = t.description
      String.downcase(_this)
    else
      ""
    end
    case :binary.match(title, ql_opt) do
                {pos, _} -> pos
                :nomatch -> -1
            end >= 0 or case :binary.match(desc, ql_opt) do
                {pos, _} -> pos
                :nomatch -> -1
            end >= 0
  end end).())
  end
  def filter_and_sort_todos(todos, filter, sort_by, search_query, selected_tags) do
    filtered = filter_todos(todos, filter, search_query)
    filtered = if (not Kernel.is_nil(selected_tags) and length(selected_tags) > 0), do: Enum.filter(filtered, (fn -> fn t ->
    tags = if (not Kernel.is_nil(t.tags)), do: t.tags, else: []
    _g = 0
    Enum.each(0..(length(selected_tags) - 1), (fn -> fn todo_priority ->
      sel = selected_tags[todo_priority]
      todo_priority + 1
      if ((

                case Enum.find_index(tags, fn item -> item == sel end) do
                    nil -> -1
                    idx -> idx
                end
            
) != -1), do: true
    end end).())
    false
  end end).()), else: filtered
    TodoApp.Sorting.by((fn -> ((case sort_by do
      {:created} -> "created"
      {:priority} -> "priority"
      {:due_date} -> "due_date"
    end)) end).(), filtered)
  end
  def handle_event("create_todo", params, socket) do
    {:noreply, create_todo((fn -> if (Kernel.is_binary((fn -> Map.get(params, "value", (fn -> if (Kernel.is_binary(Map.get(params, "id", params))) do
  String.to_integer(Map.get(params, "id", params))
else
  Map.get(params, "id", params)
end end).()) end).())) do
    URI.decode_query((fn -> Map.get(params, "value", (fn -> if (Kernel.is_binary(Map.get(params, "id", params))) do
      String.to_integer(Map.get(params, "id", params))
    else
      Map.get(params, "id", params)
    end end).()) end).())
  else
    Map.get(params, "value", (fn -> if (Kernel.is_binary(Map.get(params, "id", params))) do
      String.to_integer(Map.get(params, "id", params))
    else
      Map.get(params, "id", params)
    end end).())
  end end).(), socket)}
  end
  def handle_event("toggle_todo", params, socket) do
    {:noreply, toggle_todo_status((fn -> if (Kernel.is_binary((fn -> if (Kernel.is_map(Map.get(params, "value"))) do
  Map.get(Map.get(params, "value"), "id", Map.get(params, "id", params))
else
  if (Kernel.is_binary(Map.get(params, "value"))) do
    Map.get(URI.decode_query(Map.get(params, "value")), "id", Map.get(params, "id", params))
  else
    Map.get(params, "id", params)
  end
end end).())) do
    String.to_integer((fn -> if (Kernel.is_map(Map.get(params, "value"))) do
      Map.get(Map.get(params, "value"), "id", Map.get(params, "id", params))
    else
      if (Kernel.is_binary(Map.get(params, "value"))) do
        Map.get(URI.decode_query(Map.get(params, "value")), "id", Map.get(params, "id", params))
      else
        Map.get(params, "id", params)
      end
    end end).())
  else
    if (Kernel.is_map((fn -> if (Kernel.is_binary(Map.get(params, "value"))) do
  URI.decode_query(Map.get(params, "value"))
else
  Map.get(params, "value")
end end).())) do
      Map.get((fn -> if (Kernel.is_binary(Map.get(params, "value"))) do
        URI.decode_query(Map.get(params, "value"))
      else
        Map.get(params, "value")
      end end).(), "id", Map.get(params, "id", params))
    else
      if (Kernel.is_binary((fn -> if (Kernel.is_binary(Map.get(params, "value"))) do
  URI.decode_query(Map.get(params, "value"))
else
  Map.get(params, "value")
end end).())) do
        Map.get(URI.decode_query(Map.get(params, "value")), "id", Map.get(params, "id", params))
      else
        Map.get(params, "id", params)
      end
    end
  end end).(), socket)}
  end
  def handle_event("delete_todo", params, socket) do
    Log.trace("[TodoLive] handleEvent DeleteTodo", %{:file_name => "src_haxe/server/live/TodoLive.hx", :line_number => 207, :class_name => "server.live.TodoLive", :method_name => "handleEvent"})
    {:noreply, delete_todo((fn -> if (Kernel.is_binary((fn -> if (Kernel.is_map(Map.get(params, "value"))) do
  Map.get(Map.get(params, "value"), "id", Map.get(params, "id", params))
else
  if (Kernel.is_binary(Map.get(params, "value"))) do
    Map.get(URI.decode_query(Map.get(params, "value")), "id", Map.get(params, "id", params))
  else
    Map.get(params, "id", params)
  end
end end).())) do
    String.to_integer((fn -> if (Kernel.is_map(Map.get(params, "value"))) do
      Map.get(Map.get(params, "value"), "id", Map.get(params, "id", params))
    else
      if (Kernel.is_binary(Map.get(params, "value"))) do
        Map.get(URI.decode_query(Map.get(params, "value")), "id", Map.get(params, "id", params))
      else
        Map.get(params, "id", params)
      end
    end end).())
  else
    if (Kernel.is_map((fn -> if (Kernel.is_binary(Map.get(params, "value"))) do
  URI.decode_query(Map.get(params, "value"))
else
  Map.get(params, "value")
end end).())) do
      Map.get((fn -> if (Kernel.is_binary(Map.get(params, "value"))) do
        URI.decode_query(Map.get(params, "value"))
      else
        Map.get(params, "value")
      end end).(), "id", Map.get(params, "id", params))
    else
      if (Kernel.is_binary((fn -> if (Kernel.is_binary(Map.get(params, "value"))) do
  URI.decode_query(Map.get(params, "value"))
else
  Map.get(params, "value")
end end).())) do
        Map.get(URI.decode_query(Map.get(params, "value")), "id", Map.get(params, "id", params))
      else
        Map.get(params, "id", params)
      end
    end
  end end).(), socket)}
  end
  def handle_event("edit_todo", params, socket) do
    {:noreply, start_editing((fn -> if (Kernel.is_binary((fn -> if (Kernel.is_map(Map.get(params, "value"))) do
  Map.get(Map.get(params, "value"), "id", Map.get(params, "id", params))
else
  if (Kernel.is_binary(Map.get(params, "value"))) do
    Map.get(URI.decode_query(Map.get(params, "value")), "id", Map.get(params, "id", params))
  else
    Map.get(params, "id", params)
  end
end end).())) do
    String.to_integer((fn -> if (Kernel.is_map(Map.get(params, "value"))) do
      Map.get(Map.get(params, "value"), "id", Map.get(params, "id", params))
    else
      if (Kernel.is_binary(Map.get(params, "value"))) do
        Map.get(URI.decode_query(Map.get(params, "value")), "id", Map.get(params, "id", params))
      else
        Map.get(params, "id", params)
      end
    end end).())
  else
    if (Kernel.is_map((fn -> if (Kernel.is_binary(Map.get(params, "value"))) do
  URI.decode_query(Map.get(params, "value"))
else
  Map.get(params, "value")
end end).())) do
      Map.get((fn -> if (Kernel.is_binary(Map.get(params, "value"))) do
        URI.decode_query(Map.get(params, "value"))
      else
        Map.get(params, "value")
      end end).(), "id", Map.get(params, "id", params))
    else
      if (Kernel.is_binary((fn -> if (Kernel.is_binary(Map.get(params, "value"))) do
  URI.decode_query(Map.get(params, "value"))
else
  Map.get(params, "value")
end end).())) do
        Map.get(URI.decode_query(Map.get(params, "value")), "id", Map.get(params, "id", params))
      else
        Map.get(params, "id", params)
      end
    end
  end end).(), socket)}
  end
  def handle_event("save_todo", params, socket) do
    {:noreply, save_edited_todo_typed((fn -> if (Kernel.is_binary((fn -> Map.get(params, "value", (fn -> if (Kernel.is_binary(Map.get(params, "id", params))) do
  String.to_integer(Map.get(params, "id", params))
else
  Map.get(params, "id", params)
end end).()) end).())) do
    URI.decode_query((fn -> Map.get(params, "value", (fn -> if (Kernel.is_binary(Map.get(params, "id", params))) do
      String.to_integer(Map.get(params, "id", params))
    else
      Map.get(params, "id", params)
    end end).()) end).())
  else
    Map.get(params, "value", (fn -> if (Kernel.is_binary(Map.get(params, "id", params))) do
      String.to_integer(Map.get(params, "id", params))
    else
      Map.get(params, "id", params)
    end end).())
  end end).(), socket)}
  end
  def handle_event("cancel_edit", params, socket) do
    {:noreply, recompute_visible(SafeAssigns.set_editing_todo(socket, nil))}
  end
  def handle_event("filter_todos", params, socket) do
    {:noreply, recompute_visible(SafeAssigns.set_filter(socket, Map.get(params, "filter")))}
  end
  def handle_event("sort_todos", params, socket) do
    {:noreply, recompute_visible(SafeAssigns.set_sort_by_and_resort(socket, Map.get(params, "sort_by")))}
  end
  def handle_event("search_todos", params, socket) do
    {:noreply, recompute_visible(SafeAssigns.set_search_query(socket, Map.get(params, "query")))}
  end
  def handle_event("toggle_tag", params, socket) do
    currently_selected = socket.assigns.selected_tags
    {:noreply, recompute_visible(SafeAssigns.set_selected_tags(socket, Map.get(params, "new_selected")))}
  end
  def handle_event("set_priority", params, socket) do
    id = if (Kernel.is_binary(Map.get(params, "id"))) do
      String.to_integer(Map.get(params, "id"))
    else
      Map.get(params, "id")
    end
    priority = Map.get(params, "priority")
    {:noreply, update_todo_priority(id, priority, socket)}
  end
  def handle_event("toggle_form", params, socket) do
    {:noreply, recompute_visible(SafeAssigns.set_show_form(socket, not socket.assigns.show_form))}
  end
  def handle_event("bulk_complete", params, socket) do
    {:noreply, complete_all_todos(socket)}
  end
  def handle_event("bulk_delete_completed", params, socket) do
    {:noreply, delete_completed_todos(socket)}
  end
  def handle_event(event, params, socket) do
    {:noreply, socket}
  end
end
