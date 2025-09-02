defmodule TypeSafeConversions do
  def event_params_to_changeset_params(params) do
    todo_params = %{}
    if (params.title != nil) do
      title = params.title
    end
    if (params.description != nil) do
      description = params.description
    end
    if (params.priority != nil) do
      priority = params.priority
    end
    if (params.due_date != nil) do
      due_date = Date.from_string(params.due_date)
    end
    if (params.tags != nil) do
      tags = Enum.map(params.tags.split(","), fn s -> StringTools.trim(s) end)
    end
    if (params.completed != nil) do
      completed = params.completed
    end
    todo_params
  end
  def create_todo_params(title, description, priority, due_date, tags, user_id) do
    todo_params = %{:title => title, :priority => priority, :user_id => user_id, :completed => false}
    if (description != nil) do
      description = description
    end
    if (due_date != nil) do
      due_date = Date.from_string(due_date)
    end
    if (tags != nil) do
      tags = Enum.map(tags.split(","), fn s -> StringTools.trim(s) end)
    end
    todo_params
  end
  def validate_todo_creation_params(params) do
    params.title != nil && params.title.length > 0
  end
  def create_complete_assigns(base, todos, filter, sort_by, current_user, editing_todo, show_form, search_query, selected_tags) do
    assigns = %{:todos => if (todos != nil) do
  todos
else
  if (base != nil), do: base.todos, else: []
end, :filter => if (filter != nil) do
  filter
else
  if (base != nil), do: base.filter, else: "all"
end, :sort_by => if (sort_by != nil) do
  sort_by
else
  if (base != nil), do: base.sort_by, else: "created"
end, :current_user => if (current_user != nil) do
  current_user
else
  if (base != nil), do: base.current_user, else: create_default_user()
end, :editing_todo => if (editing_todo != nil) do
  editing_todo
else
  if (base != nil), do: base.editing_todo, else: nil
end, :show_form => if (show_form != nil) do
  show_form
else
  if (base != nil), do: base.show_form, else: false
end, :search_query => if (search_query != nil) do
  search_query
else
  if (base != nil), do: base.search_query, else: ""
end, :selected_tags => if (selected_tags != nil) do
  selected_tags
else
  if (base != nil), do: base.selected_tags, else: []
end, :total_todos => 0, :completed_todos => 0, :pending_todos => 0}
    total_todos = assigns.todos.length
    completed_todos = count_completed(assigns.todos)
    pending_todos = (assigns.total_todos - assigns.completed_todos)
    assigns
  end
  defp create_default_user() do
    %{:id => 1, :name => "Default User", :email => "default@example.com", :password_hash => "default_hash", :confirmed_at => nil, :last_login_at => nil, :active => true}
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
end