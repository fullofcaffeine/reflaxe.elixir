defmodule TodoAppWeb.TodoLive do
  use TodoAppWeb, :live_view

  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    _g = :TodoPubSub.subscribe(:TodoUpdates)
    case (_g.elem(0)) do
      0 ->
        _g_2 = _g.elem(1)
      1 ->
        _g_2 = _g.elem(1)
        reason = _g_2
        {:Error, "Failed to subscribe to updates: " + reason}
    end
    current_user = :TodoLive.get_user_from_session(session)
    todos = :TodoLive.load_todos(current_user.id)
    assigns = %{:todos => todos, :filter => "all", :sort_by => "created", :current_user => current_user, :editing_todo => nil, :show_form => false, :search_query => "", :selected_tags => [], :total_todos => todos.length, :completed_todos => :TodoLive.count_completed(todos), :pending_todos => :TodoLive.count_pending(todos)}
    updated_socket = :LiveView.assign(socket, assigns)
    {:Ok, updated_socket}
  end


  @doc "Generated from Haxe handle_event"
  def handle_event(event, params, socket) do
    temp_socket = nil

    temp_socket = nil
    case (event) do
      "bulk_complete" ->
        temp_socket = :TodoLive.complete_all_todos(socket)
      "bulk_delete_completed" ->
        temp_socket = :TodoLive.delete_completed_todos(socket)
      "cancel_edit" ->
        temp_socket = :SafeAssigns.setEditingTodo(socket, nil)
      "create_todo" ->
        temp_socket = :TodoLive.create_new_todo(params, socket)
      "delete_todo" ->
        temp_socket = :TodoLive.delete_todo(params.id, socket)
      "edit_todo" ->
        temp_socket = :TodoLive.start_editing(params.id, socket)
      "filter_todos" ->
        temp_socket = :SafeAssigns.setFilter(socket, params.filter)
      "save_todo" ->
        temp_socket = :TodoLive.save_edited_todo(params, socket)
      "search_todos" ->
        temp_socket = :SafeAssigns.setSearchQuery(socket, params.query)
      "set_priority" ->
        temp_socket = :TodoLive.update_todo_priority(params.id, params.priority, socket)
      "sort_todos" ->
        temp_socket = :SafeAssigns.setSortBy(socket, params.sort_by)
      "toggle_form" ->
        temp_socket = :SafeAssigns.setShowForm(socket, not socket.assigns.show_form)
      "toggle_tag" ->
        temp_socket = :TodoLive.toggle_tag_filter(params.tag, socket)
      "toggle_todo" ->
        temp_socket = :TodoLive.toggle_todo_status(params.id, socket)
      _ ->
        temp_socket = socket
    end
    {:NoReply, temp_socket}
  end


  @doc "Generated from Haxe handle_info"
  def handle_info(msg, socket) do
    temp_socket = nil
    temp_flash_type = nil

    temp_socket = nil
    _g = :TodoPubSub.parseMessage(msg)
    case (_g.elem(0)) do
      0 ->
        _g_2 = _g.elem(1)
        parsed_msg = _g_2
        case (parsed_msg.elem(0)) do
          0 ->
            _g_3 = parsed_msg.elem(1)
            todo = _g_3
            temp_socket = :TodoLive.add_todo_to_list(todo, socket)
          1 ->
            _g_3 = parsed_msg.elem(1)
            todo = _g_3
            temp_socket = :TodoLive.update_todo_in_list(todo, socket)
          2 ->
            _g_3 = parsed_msg.elem(1)
            id = _g_3
            temp_socket = :TodoLive.remove_todo_from_list(id, socket)
          3 ->
            _g_3 = parsed_msg.elem(1)
            action = _g_3
            temp_socket = :TodoLive.handle_bulk_update(action, socket)
          4 ->
            _g_3 = parsed_msg.elem(1)
            user_id = _g_3
            temp_socket = socket
          5 ->
            _g_3 = parsed_msg.elem(1)
            user_id = _g_3
            temp_socket = socket
          6 ->
            _g_3 = parsed_msg.elem(1)
            _g_1 = parsed_msg.elem(2)
            message = _g_3
            level = _g_1
            temp_flash_type = nil
            case (level.elem(0)) do
              0 ->
                temp_flash_type = :Info
              1 ->
                temp_flash_type = :Warning
              2 ->
                temp_flash_type = :Error
              3 ->
                temp_flash_type = :Error
            end
            flash_type = temp_flash_type
            temp_socket = :LiveView.put_flash(socket, flash_type, message)
        end
      1 ->
        :Log.trace("Received unknown PubSub message: " + :Std.string(msg), %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 197, :className => "server.live.TodoLive", :methodName => "handle_info"})
        temp_socket = socket
    end
    {:NoReply, temp_socket}
  end


  @doc "Generated from Haxe create_new_todo"
  def create_new_todo(params, socket) do
    temp_right = nil

    todo_params_title = params.title
    todo_params_description = params.description
    todo_params_completed = false
    temp_right = nil
    if (params.priority != nil) do
      temp_right = params.priority
    else
      temp_right = "medium"
    end
    todo_params_due_date = params.due_date
    todo_params_tags = :TodoLive.parse_tags(params.tags)
    todo_params_user_id = socket.assigns.current_user.id
    changeset_params = :TypeSafeConversions.eventParamsToChangesetParams(params)
    changeset = :Todo.changeset(%Todo{}, changeset_params)
    _g = :Repo.insert(changeset)
    case (_g.elem(0)) do
      0 ->
        _g_2 = _g.elem(1)
        todo = _g_2
        _g_3 = :TodoPubSub.broadcast(:TodoUpdates, {:TodoCreated, todo})
        case (_g_3.elem(0)) do
          0 ->
            _g_4 = _g_3.elem(1)
          1 ->
            _g_4 = _g_3.elem(1)
            reason = _g_4
            :Log.trace("Failed to broadcast todo creation: " + reason, %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 228, :className => "server.live.TodoLive", :methodName => "create_new_todo"})
        end
        todos = [todo].concat(socket.assigns.todos)
        current_assigns = socket.assigns
        complete_assigns = :TypeSafeConversions.createCompleteAssigns(current_assigns, todos, nil, nil, nil, nil, false, nil, nil)
        updated_socket = :LiveView.assign(socket, complete_assigns)
        :LiveView.put_flash(updated_socket, :Success, "Todo created successfully!")
      1 ->
        _g_2 = _g.elem(1)
        reason = _g_2
        :LiveView.put_flash(socket, :Error, "Failed to create todo: " + :Std.string(reason))
    end
  end


  @doc "Generated from Haxe toggle_todo_status"
  def toggle_todo_status(id, socket) do
    todo = :TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil) do
      socket
    end
    updated_changeset = :Todo.toggle_completed(todo)
    _g = :Repo.update(updated_changeset)
    case (_g.elem(0)) do
      0 ->
        _g_2 = _g.elem(1)
        updated_todo = _g_2
        _g_3 = :TodoPubSub.broadcast(:TodoUpdates, {:TodoUpdated, updated_todo})
        case (_g_3.elem(0)) do
          0 ->
            _g_4 = _g_3.elem(1)
          1 ->
            _g_4 = _g_3.elem(1)
            reason = _g_4
            :Log.trace("Failed to broadcast todo update: " + reason, %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 267, :className => "server.live.TodoLive", :methodName => "toggle_todo_status"})
        end
        :TodoLive.update_todo_in_list(updated_todo, socket)
      1 ->
        _g_2 = _g.elem(1)
        reason = _g_2
        :LiveView.put_flash(socket, :Error, "Failed to update todo: " + :Std.string(reason))
    end
  end


  @doc "Generated from Haxe delete_todo"
  def delete_todo(id, socket) do
    todo = :TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil) do
      socket
    end
    _g = :Repo.delete(todo)
    case (_g.elem(0)) do
      0 ->
        _g_2 = _g.elem(1)
        deleted_todo = _g_2
        _g_3 = :TodoPubSub.broadcast(:TodoUpdates, {:TodoDeleted, id})
        case (_g_3.elem(0)) do
          0 ->
            _g_4 = _g_3.elem(1)
          1 ->
            _g_4 = _g_3.elem(1)
            reason = _g_4
            :Log.trace("Failed to broadcast todo deletion: " + reason, %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 289, :className => "server.live.TodoLive", :methodName => "delete_todo"})
        end
        :TodoLive.remove_todo_from_list(id, socket)
      1 ->
        _g_2 = _g.elem(1)
        reason = _g_2
        :LiveView.put_flash(socket, :Error, "Failed to delete todo: " + :Std.string(reason))
    end
  end


  @doc "Generated from Haxe update_todo_priority"
  def update_todo_priority(id, priority, socket) do
    todo = :TodoLive.find_todo(id, socket.assigns.todos)
    if (todo == nil) do
      socket
    end
    updated_changeset = :Todo.update_priority(todo, priority)
    _g = :Repo.update(updated_changeset)
    case (_g.elem(0)) do
      0 ->
        _g_2 = _g.elem(1)
        updated_todo = _g_2
        _g_3 = :TodoPubSub.broadcast(:TodoUpdates, {:TodoUpdated, updated_todo})
        case (_g_3.elem(0)) do
          0 ->
            _g_4 = _g_3.elem(1)
          1 ->
            _g_4 = _g_3.elem(1)
            reason = _g_4
            :Log.trace("Failed to broadcast todo priority update: " + reason, %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 313, :className => "server.live.TodoLive", :methodName => "update_todo_priority"})
        end
        :TodoLive.update_todo_in_list(updated_todo, socket)
      1 ->
        _g_2 = _g.elem(1)
        reason = _g_2
        :LiveView.put_flash(socket, :Error, "Failed to update priority: " + :Std.string(reason))
    end
  end


  @doc "Generated from Haxe add_todo_to_list"
  def add_todo_to_list(todo, socket) do
    if (todo.user_id == socket.assigns.current_user.id) do
      socket
    end
    todos = [todo].concat(socket.assigns.todos)
    current_assigns = socket.assigns
    complete_assigns = :TypeSafeConversions.createCompleteAssigns(current_assigns, todos)
    :LiveView.assign(socket, complete_assigns)
  end


  @doc "Generated from Haxe update_todo_in_list"
  def update_todo_in_list(updated_todo, socket) do
    _this = socket.assigns.todos
    _g = []
    _g_1 = 0
    loop_9()
    current_assigns = socket.assigns
    complete_assigns = :TypeSafeConversions.createCompleteAssigns(current_assigns, _g)
    :LiveView.assign(socket, complete_assigns)
  end


  @doc "Generated from Haxe remove_todo_from_list"
  def remove_todo_from_list(id, socket) do
    _this = socket.assigns.todos
    _g = []
    _g_1 = 0
    loop_10()
    current_assigns = socket.assigns
    complete_assigns = :TypeSafeConversions.createCompleteAssigns(current_assigns, _g)
    :LiveView.assign(socket, complete_assigns)
  end


  @doc "Generated from Haxe load_todos"
  def load_todos(user_id) do
    query = :Query.from(:Todo, "t")
    where_conditions = %StringMap{}
    value = {:Integer, user_id}
    where_conditions.set("user_id", value)
    conditions = %{:where => where_conditions}
    query = :Query.where(query, conditions)
    :Repo.all(query)
  end


  @doc "Generated from Haxe find_todo"
  def find_todo(id, todos) do
    _g = 0
    loop_11()
    nil
  end


  @doc "Generated from Haxe count_completed"
  def count_completed(todos) do
    count = 0
    _g = 0
    loop_12()
    count
  end


  @doc "Generated from Haxe count_pending"
  def count_pending(todos) do
    count = 0
    _g = 0
    loop_13()
    count
  end


  @doc "Generated from Haxe parse_tags"
  def parse_tags(tags_string) do
    if (tags_string == nil || tags_string == "") do
      []
    end
    _this = tags_string.split(",")
    _g = []
    _g_1 = 0
    loop_14()
    _g
  end


  @doc "Generated from Haxe get_user_from_session"
  def get_user_from_session(session) do
    temp_number = nil

    temp_number = nil
    if (session.user_id != nil) do
      temp_number = session.user_id
    else
      temp_number = 1
    end
    %{:id => temp_number, :name => "Demo User", :email => "demo@example.com", :password_hash => "hashed_password", :confirmed_at => nil, :last_login_at => nil, :active => true}
  end


  @doc "Generated from Haxe complete_all_todos"
  def complete_all_todos(socket) do
    temp_array = nil

    temp_array = nil
    _this = socket.assigns.todos
    _g = []
    _g_1 = 0
    loop_15()
    temp_array = _g
    _g = 0
    loop_16()
    _g = :TodoPubSub.broadcast(:TodoUpdates, {:BulkUpdate, :CompleteAll})
    case (_g.elem(0)) do
      0 ->
        _g_2 = _g.elem(1)
      1 ->
        _g_2 = _g.elem(1)
        reason = _g_2
        :Log.trace("Failed to broadcast bulk complete: " + reason, %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 449, :className => "server.live.TodoLive", :methodName => "complete_all_todos"})
    end
    updated_todos = :TodoLive.load_todos(socket.assigns.current_user.id)
    current_assigns = socket.assigns
    complete_assigns = :TypeSafeConversions.createCompleteAssigns(current_assigns, updated_todos)
    completed_todos = complete_assigns.total_todos
    pending_todos = 0
    updated_socket = :LiveView.assign(socket, complete_assigns)
    :LiveView.put_flash(updated_socket, :Info, "All todos marked as completed!")
  end


  @doc "Generated from Haxe delete_completed_todos"
  def delete_completed_todos(socket) do
    temp_array = nil
    temp_array_1 = nil

    temp_array = nil
    _this = socket.assigns.todos
    _g = []
    _g_1 = 0
    loop_17()
    temp_array = _g
    _g = 0
    loop_18()
    :TodoPubSub.broadcast(:TodoUpdates, {:BulkUpdate, :DeleteCompleted})
    temp_array_1 = nil
    _this = socket.assigns.todos
    _g = []
    _g_1 = 0
    loop_19()
    temp_array_1 = _g
    current_assigns = socket.assigns
    complete_assigns = :TypeSafeConversions.createCompleteAssigns(current_assigns, temp_array_1)
    completed_todos = 0
    pending_todos = temp_array_1.length
    updated_socket = :LiveView.assign(socket, complete_assigns)
    :LiveView.put_flash(updated_socket, :Info, "Completed todos deleted!")
  end


  @doc "Generated from Haxe start_editing"
  def start_editing(id, socket) do
    todo = :TodoLive.find_todo(id, socket.assigns.todos)
    :SafeAssigns.setEditingTodo(socket, todo)
  end


  @doc "Generated from Haxe save_edited_todo"
  def save_edited_todo(params, socket) do
    todo = socket.assigns.editing_todo
    if (todo == nil) do
      socket
    end
    changeset_params = :TypeSafeConversions.eventParamsToChangesetParams(params)
    changeset = :Todo.changeset(todo, changeset_params)
    _g = :Repo.update(changeset)
    case (_g.elem(0)) do
      0 ->
        _g_2 = _g.elem(1)
        updated_todo = _g_2
        _g_3 = :TodoPubSub.broadcast(:TodoUpdates, {:TodoUpdated, updated_todo})
        case (_g_3.elem(0)) do
          0 ->
            _g_4 = _g_3.elem(1)
          1 ->
            _g_4 = _g_3.elem(1)
            reason = _g_4
            :Log.trace("Failed to broadcast todo save: " + reason, %{:fileName => "src_haxe/server/live/TodoLive.hx", :lineNumber => 514, :className => "server.live.TodoLive", :methodName => "save_edited_todo"})
        end
        updated_socket = :TodoLive.update_todo_in_list(updated_todo, socket)
        :LiveView.assign(updated_socket, "editing_todo", nil)
      1 ->
        _g_2 = _g.elem(1)
        reason = _g_2
        :LiveView.put_flash(socket, :Error, "Failed to save todo: " + :Std.string(reason))
    end
  end


  @doc "Generated from Haxe handle_bulk_update"
  def handle_bulk_update(action, socket) do
    temp_result = nil

    temp_result = nil
    case (action.elem(0)) do
      0 ->
        updated_todos = :TodoLive.load_todos(socket.assigns.current_user.id)
        current_assigns = socket.assigns
        complete_assigns = :TypeSafeConversions.createCompleteAssigns(current_assigns, updated_todos)
        temp_result = :LiveView.assign(socket, complete_assigns)
      1 ->
        updated_todos = :TodoLive.load_todos(socket.assigns.current_user.id)
        current_assigns = socket.assigns
        complete_assigns = :TypeSafeConversions.createCompleteAssigns(current_assigns, updated_todos)
        temp_result = :LiveView.assign(socket, complete_assigns)
      2 ->
        _g = action.elem(1)
        priority = _g
        temp_result = socket
      3 ->
        _g = action.elem(1)
        tag = _g
        temp_result = socket
      4 ->
        _g = action.elem(1)
        tag = _g
        temp_result = socket
    end
    temp_result
  end


  @doc "Generated from Haxe toggle_tag_filter"
  def toggle_tag_filter(tag, socket) do
    temp_array = nil

    selected_tags = socket.assigns.selected_tags
    temp_array = nil
    if (selected_tags.contains(tag)) do
      _g = []
      _g_1 = 0
      _g_2 = selected_tags
      loop_20()
      temp_array = _g
    else
      temp_array = selected_tags.concat([tag])
    end
    :SafeAssigns.setSelectedTags(socket, temp_array)
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
