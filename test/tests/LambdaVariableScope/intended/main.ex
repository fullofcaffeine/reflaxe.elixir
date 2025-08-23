defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    (
          Main.test_array_filter_with_outer_variable()
          Main.test_array_map_with_outer_variable()
          Main.test_nested_array_operations()
          Main.test_multiple_outer_variables()
        )
  end

  @doc "Function test_array_filter_with_outer_variable"
  @spec test_array_filter_with_outer_variable() :: nil
  def test_array_filter_with_outer_variable() do
    items = ["apple", "banana", "cherry"]
    target_item = "banana"
    temp_array = nil
    (
          g_array = []
          (
          g_counter = 0
          Enum.filter(items, fn v -> ((v != target_item)) end)
        )
          temp_array = g_counter
        )
    todos = [%{"id" => 1, "name" => "first"}, %{"id" => 2, "name" => "second"}]
    id = 2
    temp_array1 = nil
    (
          g_array = []
          (
          g_counter = 0
          Enum.filter(todos, fn v -> ((v.id != id)) end)
        )
          temp_array1 = g_counter
        )
  end

  @doc "Function test_array_map_with_outer_variable"
  @spec test_array_map_with_outer_variable() :: nil
  def test_array_map_with_outer_variable() do
    numbers = [1, 2, 3, 4, 5]
    multiplier = 3
    temp_array = nil
    (
          g_array = []
          (
          g_counter = 0
          Enum.map(numbers, fn v -> (v * multiplier) end)
        )
          temp_array = g_counter
        )
    prefix = "Item: "
    temp_array1 = nil
    (
          g_array = []
          (
          g_counter = 0
          Enum.map(numbers, fn v -> prefix <> Std.string(v) end)
        )
          temp_array1 = g_counter
        )
  end

  @doc "Function test_nested_array_operations"
  @spec test_nested_array_operations() :: nil
  def test_nested_array_operations() do
    (
          data = [[1, 2], [3, 4], [5, 6]]
          threshold = 3
          g_array = []
          g_counter = 0
          Enum.each(data, fn v -> 
      temp_array1 = nil
      g_array = []
      g_counter = 0
      g = v
      Enum.filter(g_counter, fn v2 -> ((v > threshold)) end)
      temp_array1 = g_counter
      g_counter ++ [temp_array1]
    end)
        )
  end

  @doc "Function test_multiple_outer_variables"
  @spec test_multiple_outer_variables() :: nil
  def test_multiple_outer_variables() do
    items = ["a", "b", "c", "d"]
    prefix = "prefix_"
    suffix = "_suffix"
    exclude_item = "b"
    temp_array = nil
    temp_array1 = nil
    (
          g_array = []
          (
          g_counter = 0
          Enum.filter(items, fn v -> ((v != exclude_item)) end)
        )
          temp_array1 = g_counter
        )
    (
          g_array = []
          (
          g_counter = 0
          Enum.map(temp_array1, fn v -> prefix <> v <> suffix end)
        )
          temp_array = g_counter
        )
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
