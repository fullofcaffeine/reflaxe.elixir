defmodule SafeAssigns do
  def set_editing_todo(socket, todo) do
    Phoenix.LiveView.assign(socket, %{:editing_todo => todo})
  end
  def set_selected_tags(socket, tags) do
    Phoenix.LiveView.assign(socket, %{:selected_tags => tags})
  end
  def set_filter(socket, filter) do
    Phoenix.LiveView.assign(socket, %{:filter => filter})
  end
  def set_sort_by(socket, sort_by) do
    Phoenix.LiveView.assign(socket, %{:sort_by => sort_by})
  end
  def set_search_query(socket, query) do
    Phoenix.LiveView.assign(socket, %{:search_query => query})
  end
  def set_show_form(socket, show_form) do
    Phoenix.LiveView.assign(socket, %{:show_form => show_form})
  end
  def update_todos_and_stats(socket, todos) do
    completed = SafeAssigns.count_completed(todos)
    pending = SafeAssigns.count_pending(todos)
    Phoenix.LiveView.assign(socket, %{:todos => todos, :total_todos => todos.length, :completed_todos => completed, :pending_todos => pending})
  end
  def set_todos(socket, todos) do
    Phoenix.LiveView.assign(socket, %{:todos => todos})
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
  defp count_pending(todos) do
    count = 0
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < todos.length) do
  todo = todos[g]
  g + 1
  if (not todo.completed), do: count + 1
  {:cont, acc}
else
  {:halt, acc}
end end)
    count
  end
end