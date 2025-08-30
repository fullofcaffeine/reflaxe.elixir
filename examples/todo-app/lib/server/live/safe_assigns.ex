defmodule SafeAssigns do
  def setEditingTodo(socket, todo) do
    Phoenix.LiveView.assign(socket, %{:editing_todo => todo})
  end
  def setSelectedTags(socket, tags) do
    Phoenix.LiveView.assign(socket, %{:selected_tags => tags})
  end
  def setFilter(socket, filter) do
    Phoenix.LiveView.assign(socket, %{:filter => filter})
  end
  def setSortBy(socket, sortBy) do
    Phoenix.LiveView.assign(socket, %{:sort_by => sort_by})
  end
  def setSearchQuery(socket, query) do
    Phoenix.LiveView.assign(socket, %{:search_query => query})
  end
  def setShowForm(socket, showForm) do
    Phoenix.LiveView.assign(socket, %{:show_form => show_form})
  end
  def updateTodosAndStats(socket, todos) do
    completed = SafeAssigns.count_completed(todos)
    pending = SafeAssigns.count_pending(todos)
    Phoenix.LiveView.assign(socket, %{:todos => todos, :total_todos => todos.length, :completed_todos => completed, :pending_todos => pending})
  end
  def setTodos(socket, todos) do
    Phoenix.LiveView.assign(socket, %{:todos => todos})
  end
  defp countCompleted(todos) do
    count = 0
    g = 0
    (fn ->
      loop_12 = fn loop_12 ->
        if (g < todos.length) do
          todo = todos[g]
      g + 1
      if (todo.completed), do: count + 1
          loop_12.(loop_12)
        else
          :ok
        end
      end
      loop_12.(loop_12)
    end).()
    count
  end
  defp countPending(todos) do
    count = 0
    g = 0
    (fn ->
      loop_13 = fn loop_13 ->
        if (g < todos.length) do
          todo = todos[g]
      g + 1
      if (not todo.completed), do: count + 1
          loop_13.(loop_13)
        else
          :ok
        end
      end
      loop_13.(loop_13)
    end).()
    count
  end
end