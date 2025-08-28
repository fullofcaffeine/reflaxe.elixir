defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_basic_indexed_iteration()

    Main.test_indexed_map()

    Main.test_indexed_filter()

    Main.test_complex_indexed_operation()
  end

  @doc "Generated from Haxe testBasicIndexedIteration"
  def test_basic_indexed_iteration() do
    items = ["apple", "banana", "cherry"]

    results = []

    g_counter = 0

    g_array = items.length

    (fn loop ->
      if ((g_counter < g_array)) do
            i = g_counter + 1
        item = Enum.at(items, i)
        results = results ++ ["" <> to_string(i) <> ": " <> item]
        loop.()
      end
    end).()

    Log.trace(results, %{"fileName" => "Main.hx", "lineNumber" => 20, "className" => "Main", "methodName" => "testBasicIndexedIteration"})
  end

  @doc "Generated from Haxe testIndexedMap"
  def test_indexed_map() do
    items = ["first", "second", "third"]

    indexed = []

    g_counter = 0

    g_array = items.length

    (fn loop ->
      if ((g_counter < g_array)) do
            i = g_counter + 1
        indexed = indexed ++ ["Item #" <> to_string(((i + 1))) <> ": " <> Enum.at(items, i)]
        loop.()
      end
    end).()

    indexed
  end

  @doc "Generated from Haxe testIndexedFilter"
  def test_indexed_filter() do
    items = ["a", "b", "c", "d", "e"]

    even_indexed = []

    g_counter = 0

    g_array = items.length

    (fn loop ->
      if ((g_counter < g_array)) do
            i = g_counter + 1
        even_indexed = if ((rem(i, 2) == 0)), do: even_indexed ++ [Enum.at(items, i)], else: even_indexed
        loop.()
      end
    end).()

    even_indexed
  end

  @doc "Generated from Haxe testComplexIndexedOperation"
  def test_complex_indexed_operation() do
    numbers = [10, 20, 30, 40, 50]

    sum = 0

    g_counter = 0

    g_array = numbers.length

    (fn loop ->
      if ((g_counter < g_array)) do
            i = g_counter + 1
        sum = sum + (Enum.at(numbers, i) * ((i + 1)))
        loop.()
      end
    end).()

    sum
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
