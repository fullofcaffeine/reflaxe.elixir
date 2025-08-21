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
  @doc """
    Set the editing_todo field

  """
  @spec set_editing_todo(Phoenix.Socket.t(), Null.t()) :: Phoenix.Socket.t()
  def set_editing_todo(socket, todo) do
    LiveView.assign_multiple(socket, %{"editing_todo" => todo})
  end

  @doc """
    Set the selected_tags field

  """
  @spec set_selected_tags(Phoenix.Socket.t(), Array.t()) :: Phoenix.Socket.t()
  def set_selected_tags(socket, tags) do
    LiveView.assign_multiple(socket, %{"selected_tags" => tags})
  end

  @doc """
    Set the filter field

  """
  @spec set_filter(Phoenix.Socket.t(), String.t()) :: Phoenix.Socket.t()
  def set_filter(socket, filter) do
    LiveView.assign_multiple(socket, %{"filter" => filter})
  end

  @doc """
    Set the sort_by field

  """
  @spec set_sort_by(Phoenix.Socket.t(), String.t()) :: Phoenix.Socket.t()
  def set_sort_by(socket, sort_by) do
    LiveView.assign_multiple(socket, %{"sort_by" => sort_by})
  end

  @doc """
    Set the search_query field

  """
  @spec set_search_query(Phoenix.Socket.t(), String.t()) :: Phoenix.Socket.t()
  def set_search_query(socket, query) do
    LiveView.assign_multiple(socket, %{"search_query" => query})
  end

  @doc """
    Set the show_form field

  """
  @spec set_show_form(Phoenix.Socket.t(), boolean()) :: Phoenix.Socket.t()
  def set_show_form(socket, show_form) do
    LiveView.assign_multiple(socket, %{"show_form" => show_form})
  end

  @doc """
    Update todos and automatically recalculate statistics

  """
  @spec update_todos_and_stats(Phoenix.Socket.t(), Array.t()) :: Phoenix.Socket.t()
  def update_todos_and_stats(socket, todos) do
    completed = SafeAssigns.count_completed(todos)
    pending = SafeAssigns.count_pending(todos)
    LiveView.assign_multiple(socket, %{"todos" => todos, "total_todos" => todos.length, "completed_todos" => completed, "pending_todos" => pending})
  end

  @doc """
    Update just the todos list without stats recalculation

  """
  @spec set_todos(Phoenix.Socket.t(), Array.t()) :: Phoenix.Socket.t()
  def set_todos(socket, todos) do
    LiveView.assign_multiple(socket, %{"todos" => todos})
  end

  @doc """
    Helper function to count completed todos

  """
  @spec count_completed(Array.t()) :: integer()
  def count_completed(todos) do
    count = 0
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g, count} ->
        if (g < todos.length) do
          try do
            todo = Enum.at(todos, g)
          g = g + 1
          if (todo.completed) do
      count = count + 1
    end
          loop_fn.({g + 1, count})
            loop_fn.(loop_fn, {g, count})
          catch
            :break -> {g, count}
            :continue -> loop_fn.(loop_fn, {g, count})
          end
        else
          {g, count}
        end
      end
      {g, count} = try do
        loop_helper.(loop_helper, {nil, nil})
      catch
        :break -> {nil, nil}
      end
    )
    count
  end

  @doc """
    Helper function to count pending todos

  """
  @spec count_pending(Array.t()) :: integer()
  def count_pending(todos) do
    count = 0
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g, count} ->
        if (g < todos.length) do
          try do
            todo = Enum.at(todos, g)
          g = g + 1
          if (!todo.completed) do
      count = count + 1
    end
          loop_fn.({g + 1, count})
            loop_fn.(loop_fn, {g, count})
          catch
            :break -> {g, count}
            :continue -> loop_fn.(loop_fn, {g, count})
          end
        else
          {g, count}
        end
      end
      {g, count} = try do
        loop_helper.(loop_helper, {nil, nil})
      catch
        :break -> {nil, nil}
      end
    )
    count
  end

end
