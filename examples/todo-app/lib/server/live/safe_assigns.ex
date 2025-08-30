defmodule SafeAssigns do
  def setEditingTodo(socket, todo) do
    fn socket, todo -> Phoenix.LiveView.assign(socket, %{:editing_todo => todo}) end
  end
  def setSelectedTags(socket, tags) do
    fn socket, tags -> Phoenix.LiveView.assign(socket, %{:selected_tags => tags}) end
  end
  def setFilter(socket, filter) do
    fn socket, filter -> Phoenix.LiveView.assign(socket, %{:filter => filter}) end
  end
  def setSortBy(socket, sortBy) do
    fn socket, sort_by -> Phoenix.LiveView.assign(socket, %{:sort_by => sort_by}) end
  end
  def setSearchQuery(socket, query) do
    fn socket, query -> Phoenix.LiveView.assign(socket, %{:search_query => query}) end
  end
  def setShowForm(socket, showForm) do
    fn socket, show_form -> Phoenix.LiveView.assign(socket, %{:show_form => show_form}) end
  end
  def updateTodosAndStats(socket, todos) do
    fn socket, todos -> completed = SafeAssigns.count_completed(todos)
pending = SafeAssigns.count_pending(todos)
Phoenix.LiveView.assign(socket, %{:todos => todos, :total_todos => todos.length, :completed_todos => completed, :pending_todos => pending}) end
  end
  def setTodos(socket, todos) do
    fn socket, todos -> Phoenix.LiveView.assign(socket, %{:todos => todos}) end
  end
  defp countCompleted(todos) do
    fn todos -> count = 0
g = 0
(fn ->
  loop_12 = fn loop_12 ->
    if (g < todos.length) do
      todo = todos[g]
      g + 1
      if (todo.completed) do
        count + 1
      end
      loop_12.(loop_12)
    else
      :ok
    end
  end
  loop_12.(loop_12)
end).()
count end
  end
  defp countPending(todos) do
    fn todos -> count = 0
g = 0
(fn ->
  loop_13 = fn loop_13 ->
    if (g < todos.length) do
      todo = todos[g]
      g + 1
      if (not todo.completed) do
        count + 1
      end
      loop_13.(loop_13)
    else
      :ok
    end
  end
  loop_13.(loop_13)
end).()
count end
  end
end