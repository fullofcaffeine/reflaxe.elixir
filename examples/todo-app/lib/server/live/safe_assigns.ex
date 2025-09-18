defmodule SafeAssigns do
  def set_editing_todo(socket, todo) do
    live_socket = socket
    :nil
  end
  def set_selected_tags(socket, tags) do
    live_socket = socket
    :nil
  end
  def set_filter(socket, filter) do
    live_socket = socket
    :nil
  end
  def set_sort_by(socket, sort_by) do
    live_socket = socket
    :nil
  end
  def set_search_query(socket, query) do
    live_socket = socket
    :nil
  end
  def set_show_form(socket, show_form) do
    live_socket = socket
    :nil
  end
  def update_todos_and_stats(socket, todos) do
    completed = SafeAssigns.count_completed(todos)
    pending = SafeAssigns.count_pending(todos)
    live_socket = socket
    :nil
  end
  def set_todos(socket, todos) do
    live_socket = socket
    :nil
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
end