defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_array_filter_with_outer_variable()

    Main.test_array_map_with_outer_variable()

    Main.test_nested_array_operations()

    Main.test_multiple_outer_variables()
  end

  @doc "Generated from Haxe testArrayFilterWithOuterVariable"
  def test_array_filter_with_outer_variable() do
    temp_array = nil
    temp_array1 = nil

    items = ["apple", "banana", "cherry"]

    target_item = "banana"

    g_array = []
    g_counter = 0
    Enum.filter(items, fn item -> item != target_item end)
    temp_array = g_array

    todos = [%{"id" => 1, "name" => "first"}, %{"id" => 2, "name" => "second"}]

    id = 2

    g_array = []
    g_counter = 0
    Enum.filter(todos, fn item -> item.id != id end)
    temp_array1 = g_array
  end

  @doc "Generated from Haxe testArrayMapWithOuterVariable"
  def test_array_map_with_outer_variable() do
    temp_array = nil
    temp_array1 = nil

    numbers = [1, 2, 3, 4, 5]

    multiplier = 3

    g_array = []
    g_counter = 0
    Enum.map(numbers, fn item -> item * multiplier end)
    temp_array = g_array

    prefix = "Item: "

    g_array = []
    g_counter = 0
    Enum.map(numbers, fn item -> prefix <> Std.string(item) end)
    temp_array1 = g_array
  end

  @doc "Generated from Haxe testNestedArrayOperations"
  def test_nested_array_operations() do
    temp_array1 = nil

    data = [[1, 2], [3, 4], [5, 6]]

    threshold = 3

    g_array = []

    g_counter = 0

    Enum.map(data, fn item -> temp_array1 end)
  end

  @doc "Generated from Haxe testMultipleOuterVariables"
  def test_multiple_outer_variables() do
    temp_array1 = nil
    temp_array = nil

    items = ["a", "b", "c", "d"]

    prefix = "prefix_"

    suffix = "_suffix"

    exclude_item = "b"

    g_array = []
    g_counter = 0
    Enum.filter(items, fn item -> item != exclude_item end)
    temp_array1 = g_array

    g_array = []
    g_counter = 0
    Enum.map(temp_array1, fn item -> prefix <> item <> suffix end)
    temp_array = g_array
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
