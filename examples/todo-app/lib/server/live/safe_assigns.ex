defmodule SafeAssigns do
  @moduledoc """
    SafeAssigns module generated from Haxe

     * Type-safe socket assign operations for TodoLive
     *
     * This approach eliminates string-based keys and provides compile-time
     * validation for socket assign operations, similar to our SafePubSub pattern.
     *
     * ## Benefits:
     * - **Compile-time validation**: No more typos in assign keys
     * - **Type safety**: Each assignment is validated for correct value type
     * - **IntelliSense support**: IDE can auto-complete available assignments
     * - **Refactor friendly**: Renaming fields updates all references automatically
     *
     * ## Usage:
     * ```haxe
     * // Type-safe individual assignments
     * socket = SafeAssigns.setEditingTodo(socket, todo);
     * socket = SafeAssigns.setSelectedTags(socket, tags);
     *
     * // Type-safe bulk assignments
     * socket = SafeAssigns.updateStats(socket, newTodos);
     * ```
  """

  # Static functions
  @doc "Generated from Haxe setEditingTodo"
  def set_editing_todo(socket, todo) do
    :LiveView.assign(socket, %{:editing_todo => todo})
  end

  @doc "Generated from Haxe setSelectedTags"
  def set_selected_tags(socket, tags) do
    :LiveView.assign(socket, %{:selected_tags => tags})
  end

  @doc "Generated from Haxe setFilter"
  def set_filter(socket, filter) do
    :LiveView.assign(socket, %{:filter => filter})
  end

  @doc "Generated from Haxe setSortBy"
  def set_sort_by(socket, sort_by) do
    :LiveView.assign(socket, %{:sort_by => sort_by})
  end

  @doc "Generated from Haxe setSearchQuery"
  def set_search_query(socket, query) do
    :LiveView.assign(socket, %{:search_query => query})
  end

  @doc "Generated from Haxe setShowForm"
  def set_show_form(socket, show_form) do
    :LiveView.assign(socket, %{:show_form => show_form})
  end

  @doc "Generated from Haxe updateTodosAndStats"
  def update_todos_and_stats(socket, todos) do
    completed = :SafeAssigns.countCompleted(todos)
    pending = :SafeAssigns.countPending(todos)
    :LiveView.assign(socket, %{:todos => todos, :total_todos => todos.length, :completed_todos => completed, :pending_todos => pending})
  end

  @doc "Generated from Haxe setTodos"
  def set_todos(socket, todos) do
    :LiveView.assign(socket, %{:todos => todos})
  end

  @doc "Generated from Haxe countCompleted"
  def count_completed(todos) do
    count = 0
    _g = 0
    loop_6()
    count
  end

  @doc "Generated from Haxe countPending"
  def count_pending(todos) do
    count = 0
    _g = 0
    loop_7()
    count
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
