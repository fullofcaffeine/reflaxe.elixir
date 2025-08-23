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
          loop_helper = fn loop_fn, {v, g1} ->
      if ((g_counter < items.length)) do
        v = Enum.at(items, g_counter)
        g1 = g1 + 1
        if ((v != target_item)) do
              g_counter ++ [v]
            end
        loop_fn.(loop_fn, {v, g1})
      else
        {v, g1}
      end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
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
          loop_helper = fn loop_fn, {v, g1} ->
      if ((g_counter < todos.length)) do
        v = Enum.at(todos, g_counter)
        g1 = g1 + 1
        if ((v.id != id)) do
              g_counter ++ [v]
            end
        loop_fn.(loop_fn, {v, g1})
      else
        {v, g1}
      end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
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
          loop_helper = fn loop_fn, {v, g1} ->
      if ((g_counter < numbers.length)) do
        v = Enum.at(numbers, g_counter)
        g1 = g1 + 1
        g_counter ++ [(v * multiplier)]
        loop_fn.(loop_fn, {v, g1})
      else
        {v, g1}
      end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
        )
          temp_array = g_counter
        )
    prefix = "Item: "
    temp_array1 = nil
    (
          g_array = []
          (
          g_counter = 0
          loop_helper = fn loop_fn, {v, g1} ->
      if ((g_counter < numbers.length)) do
        v = Enum.at(numbers, g_counter)
        g1 = g1 + 1
        g_counter ++ [prefix <> Std.string(v)]
        loop_fn.(loop_fn, {v, g1})
      else
        {v, g1}
      end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
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
          loop_helper = fn loop_fn, {v, g1, temp_array1, g3, g4, g5} ->
      if ((g_counter < data.length)) do
        v = Enum.at(data, g_counter)
        g1 = g1 + 1
        temp_array1 = nil
        g_array = []
        g_counter = 0
        g = v
        loop_helper = fn loop_fn, {v2, g4} ->
          if ((g_counter < g_counter.length)) do
            v = Enum.at(g_counter, g_counter)
            g4 = g4 + 1
            if ((v > threshold)) do
                  g_counter ++ [v]
                end
            loop_fn.(loop_fn, {v2, g4})
          else
            {v2, g4}
          end
        end

        {v2, g4} = loop_helper.(loop_helper, {v2, g4})
        temp_array1 = g_counter
        g_counter ++ [temp_array1]
        loop_fn.(loop_fn, {v, g1, temp_array1, g3, g4, g5})
      else
        {v, g1, temp_array1, g3, g4, g5}
      end
    end

    {v, g1, temp_array1, g3, g4, g5} = loop_helper.(loop_helper, {v, g1, temp_array1, g3, g4, g5})
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
          loop_helper = fn loop_fn, {v, g1} ->
      if ((g_counter < items.length)) do
        v = Enum.at(items, g_counter)
        g1 = g1 + 1
        if ((v != exclude_item)) do
              g_counter ++ [v]
            end
        loop_fn.(loop_fn, {v, g1})
      else
        {v, g1}
      end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
        )
          temp_array1 = g_counter
        )
    (
          g_array = []
          (
          g_counter = 0
          loop_helper = fn loop_fn, {v, g1} ->
      if ((g_counter < temp_array1.length)) do
        v = Enum.at(temp_array1, g_counter)
        g1 = g1 + 1
        g_counter ++ [prefix <> v <> suffix]
        loop_fn.(loop_fn, {v, g1})
      else
        {v, g1}
      end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
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
