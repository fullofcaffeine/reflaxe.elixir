defmodule TypeSafeConversions do
  def event_params_to_changeset_params(params) do
    changeset_params = %{}
    if (params.title != nil) do
      value = {:StringValue, params.title}
      Map.put(changeset_params, "title", value)
    end
    if (params.description != nil) do
      value = {:StringValue, params.description}
      Map.put(changeset_params, "description", value)
    end
    if (params.priority != nil) do
      value = {:StringValue, params.priority}
      Map.put(changeset_params, "priority", value)
    end
    if (params.due_date != nil) do
      value = {:StringValue, params.due_date}
      Map.put(changeset_params, "due_date", value)
    end
    if (params.tags != nil) do
      value = {:StringValue, params.tags}
      Map.put(changeset_params, "tags", value)
    end
    if (params.completed != nil) do
      value = {:BoolValue, params.completed}
      Map.put(changeset_params, "completed", value)
    end
    changeset_params
  end
  def create_todo_params(title, description, priority, due_date, tags, user_id) do
    changeset_params = %{}
    value = {:StringValue, title}
    Map.put(changeset_params, "title", value)
    value = {:StringValue, priority}
    Map.put(changeset_params, "priority", value)
    value = {:IntValue, user_id}
    Map.put(changeset_params, "user_id", value)
    value = {:BoolValue, false}
    Map.put(changeset_params, "completed", value)
    if (description != nil) do
      value = {:StringValue, description}
      Map.put(changeset_params, "description", value)
    end
    if (due_date != nil) do
      value = {:StringValue, due_date}
      Map.put(changeset_params, "due_date", value)
    end
    if (tags != nil) do
      value = {:StringValue, tags}
      Map.put(changeset_params, "tags", value)
    end
    changeset_params
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < todos.length) do
  todo = todos[g]
  g + 1
  if (todo.completed), do: count + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    count
  end
end