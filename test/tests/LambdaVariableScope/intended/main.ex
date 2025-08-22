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
          while_loop(fn -> ((g < items.length)) end, fn -> (
          v = Enum.at(items, g)
          g + 1
          if ((v != target_item)) do
          g ++ [v]
        end
        ) end)
        )
          temp_array = g
        )
    todos = [%{"id" => 1, "name" => "first"}, %{"id" => 2, "name" => "second"}]
    id = 2
    temp_array1 = nil
    (
          g_array = []
          (
          g_counter = 0
          while_loop(fn -> ((g < todos.length)) end, fn -> (
          v = Enum.at(todos, g)
          g + 1
          if ((v.id != id)) do
          g ++ [v]
        end
        ) end)
        )
          temp_array1 = g
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
          while_loop(fn -> ((g < numbers.length)) end, fn -> (
          v = Enum.at(numbers, g)
          g + 1
          g ++ [(v * multiplier)]
        ) end)
        )
          temp_array = g
        )
    prefix = "Item: "
    temp_array1 = nil
    (
          g_array = []
          (
          g_counter = 0
          while_loop(fn -> ((g < numbers.length)) end, fn -> (
          v = Enum.at(numbers, g)
          g + 1
          g ++ [prefix <> Std.string(v)]
        ) end)
        )
          temp_array1 = g
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
          while_loop(fn -> ((g < data.length)) end, fn -> v = Enum.at(data, g)
    g + 1
    temp_array1 = nil
    g_array = []
    g_counter = 0
    g = v
    while_loop(fn -> ((g < g.length)) end, fn -> (
          v = Enum.at(g, g)
          g + 1
          if ((v > threshold)) do
          g ++ [v]
        end
        ) end)
    temp_array1 = g
    g ++ [temp_array1] end)
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
          while_loop(fn -> ((g < items.length)) end, fn -> (
          v = Enum.at(items, g)
          g + 1
          if ((v != exclude_item)) do
          g ++ [v]
        end
        ) end)
        )
          temp_array1 = g
        )
    (
          g_array = []
          (
          g_counter = 0
          while_loop(fn -> ((g < temp_array1.length)) end, fn -> (
          v = Enum.at(temp_array1, g)
          g + 1
          g ++ [prefix <> v <> suffix]
        ) end)
        )
          temp_array = g
        )
  end

end
