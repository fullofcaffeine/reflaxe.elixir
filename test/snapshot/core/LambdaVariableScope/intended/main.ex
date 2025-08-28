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
    (fn loop ->
      if ((g_counter < items.length)) do
            v = Enum.at(items, g_counter)
        g_counter + 1
        g_array = if ((v != target_item)), do: g_array ++ [v], else: g_array
        loop.()
      end
    end).()
    temp_array = g_array

    todos = [%{"id" => 1, "name" => "first"}, %{"id" => 2, "name" => "second"}]

    id = 2

    g_array = []
    g_counter = 0
    (fn loop ->
      if ((g_counter < todos.length)) do
            v = Enum.at(todos, g_counter)
        g_counter + 1
        g_array = if ((v.id != id)), do: g_array ++ [v], else: g_array
        loop.()
      end
    end).()
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
    (fn loop ->
      if ((g_counter < numbers.length)) do
            v = Enum.at(numbers, g_counter)
        g_counter + 1
        g_array = g_array ++ [(v * multiplier)]
        loop.()
      end
    end).()
    temp_array = g_array

    prefix = "Item: "

    g_array = []
    g_counter = 0
    (fn loop ->
      if ((g_counter < numbers.length)) do
            v = Enum.at(numbers, g_counter)
        g_counter + 1
        g_array = g_array ++ [prefix <> Std.string(v)]
        loop.()
      end
    end).()
    temp_array1 = g_array
  end

  @doc "Generated from Haxe testNestedArrayOperations"
  def test_nested_array_operations() do
    temp_array1 = nil

    data = [[1, 2], [3, 4], [5, 6]]

    threshold = 3

    g_array = []

    g_counter = 0

    (fn loop ->
      if ((g_counter < data.length)) do
            v = Enum.at(data, g_counter)
        g_counter + 1
        g_array = []
        g_counter = 0
        g_array = v
        (fn loop ->
          if ((g_counter < g_array.length)) do
                v = Enum.at(g_array, g_counter)
            g_counter + 1
            g_array = if ((v > threshold)), do: g_array ++ [v], else: g_array
            loop.()
          end
        end).()
        temp_array1 = g_array
        g_array = g_array ++ [temp_array1]
        loop.()
      end
    end).()
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
    (fn loop ->
      if ((g_counter < items.length)) do
            v = Enum.at(items, g_counter)
        g_counter + 1
        g_array = if ((v != exclude_item)), do: g_array ++ [v], else: g_array
        loop.()
      end
    end).()
    temp_array1 = g_array

    g_array = []
    g_counter = 0
    (fn loop ->
      if ((g_counter < temp_array1.length)) do
            v = Enum.at(temp_array1, g_counter)
        g_counter + 1
        g_array = g_array ++ [prefix <> v <> suffix]
        loop.()
      end
    end).()
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
