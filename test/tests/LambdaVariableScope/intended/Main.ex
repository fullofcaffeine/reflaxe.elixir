defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Main.test_array_filter_with_outer_variable()
    Main.test_array_map_with_outer_variable()
    Main.test_nested_array_operations()
    Main.test_multiple_outer_variables()
  end

  @doc "Function test_array_filter_with_outer_variable"
  @spec test_array_filter_with_outer_variable() :: nil
  def test_array_filter_with_outer_variable() do
    items = ["apple", "banana", "cherry"]
    target_item = "banana"
    temp_array = nil
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < items.length) do
          try do
            v = Enum.at(items, g)
          g = g + 1
          if (v != target_item), do: g ++ [v], else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array = g
    todos = [%{"id" => 1, "name" => "first"}, %{"id" => 2, "name" => "second"}]
    id = 2
    temp_array1 = nil
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < todos.length) do
          try do
            v = Enum.at(todos, g)
          g = g + 1
          if (v.id != id), do: g ++ [v], else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array1 = g
  end

  @doc "Function test_array_map_with_outer_variable"
  @spec test_array_map_with_outer_variable() :: nil
  def test_array_map_with_outer_variable() do
    numbers = [1, 2, 3, 4, 5]
    multiplier = 3
    temp_array = nil
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < numbers.length) do
          try do
            v = Enum.at(numbers, g)
          g = g + 1
          g ++ [v * multiplier]
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array = g
    prefix = "Item: "
    temp_array1 = nil
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < numbers.length) do
          try do
            v = Enum.at(numbers, g)
          g = g + 1
          g ++ [prefix <> Std.string(v)]
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array1 = g
  end

  @doc "Function test_nested_array_operations"
  @spec test_nested_array_operations() :: nil
  def test_nested_array_operations() do
    data = [[1, 2], [3, 4], [5, 6]]
    threshold = 3
    _g_array = []
    _g_counter = 0
    (
      loop_helper = fn loop_fn, {g_counter, temp_array1} ->
        if (g < data.length) do
          try do
            v = Enum.at(data, g)
    g = g + 1
    tempArray1 = nil
    _g_counter = []
    _g_counter = 0
    _g_counter = v
    (
      loop_helper = fn loop_fn, {g_counter} ->
        if (g < g.length) do
          try do
            v = Enum.at(g, g)
    g = g + 1
    if (v > threshold), do: _g_counter.push(v), else: nil
            loop_fn.(loop_fn, {g_counter})
          catch
            :break -> {g_counter}
            :continue -> loop_fn.(loop_fn, {g_counter})
          end
        else
          {g_counter}
        end
      end
      {g_counter} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array1 = _g_counter
    _g_counter.push(temp_array1)
            loop_fn.(loop_fn, {g_counter, temp_array1})
          catch
            :break -> {g_counter, temp_array1}
            :continue -> loop_fn.(loop_fn, {g_counter, temp_array1})
          end
        else
          {g_counter, temp_array1}
        end
      end
      {g_counter, temp_array1} = try do
        loop_helper.(loop_helper, {nil, nil})
      catch
        :break -> {nil, nil}
      end
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
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < items.length) do
          try do
            v = Enum.at(items, g)
          g = g + 1
          if (v != exclude_item), do: g ++ [v], else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array1 = g
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < temp_array1.length) do
          try do
            v = Enum.at(temp_array1, g)
          g = g + 1
          g ++ [prefix <> v <> suffix]
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array = g
  end

end
