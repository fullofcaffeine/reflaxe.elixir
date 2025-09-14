defmodule SafeAssigns do
  @compile [{:nowarn_unused_function, [{:_count_pending, 1}, {:_count_completed, 1}]}]

  def set_editing_todo(socket, todo) do
    live_socket = socket
    Phoenix.Component.assign(live_socket, :editing_todo, todo)
  end
  def set_selected_tags(socket, tags) do
    live_socket = socket
    Phoenix.Component.assign(live_socket, :selected_tags, tags)
  end
  def set_filter(socket, filter) do
    live_socket = socket
    Phoenix.Component.assign(live_socket, :filter, filter)
  end
  def set_sort_by(socket, sort_by) do
    live_socket = socket
    Phoenix.Component.assign(live_socket, :sort_by, sort_by)
  end
  def set_search_query(socket, query) do
    live_socket = socket
    Phoenix.Component.assign(live_socket, :search_query, query)
  end
  def set_show_form(socket, show_form) do
    live_socket = socket
    Phoenix.Component.assign(live_socket, :show_form, show_form)
  end
  def update_todos_and_stats(socket, todos) do
    completed = count_completed(todos)
    pending = count_pending(todos)
    live_socket = socket
    Phoenix.Component.assign([live_socket, todos, todos.length, completed, pending], %{:todos => {1}, :total_todos => {2}, :completed_todos => {3}, :pending_todos => {4}})
  end
  def set_todos(socket, todos) do
    live_socket = socket
    Phoenix.Component.assign(live_socket, :todos, todos)
  end
  defp _count_completed(todos) do
    count = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {todos, count, g, :ok}, fn _, {acc_todos, acc_count, acc_g, acc_state} ->
  if (acc_g < length(acc_todos)) do
    todo = acc_todos[acc_g]
    acc_g = acc_g + 1
    if (todo.completed) do
      acc_count = acc_count + 1
    end
    {:cont, {acc_todos, acc_count, acc_g, acc_state}}
  else
    {:halt, {acc_todos, acc_count, acc_g, acc_state}}
  end
end)
    count
  end
  defp _count_pending(todos) do
    count = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {todos, count, g, :ok}, fn _, {acc_todos, acc_count, acc_g, acc_state} ->
  if (acc_g < length(acc_todos)) do
    todo = acc_todos[acc_g]
    acc_g = acc_g + 1
    if (not todo.completed) do
      acc_count = acc_count + 1
    end
    {:cont, {acc_todos, acc_count, acc_g, acc_state}}
  else
    {:halt, {acc_todos, acc_count, acc_g, acc_state}}
  end
end)
    count
  end
end