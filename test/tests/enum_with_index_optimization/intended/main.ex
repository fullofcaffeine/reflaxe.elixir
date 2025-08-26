defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    (
          Main.test_basic_indexed_iteration()
          Main.test_indexed_map()
          Main.test_indexed_filter()
          Main.test_complex_indexed_operation()
        )
  end

  @doc "Function test_basic_indexed_iteration"
  @spec test_basic_indexed_iteration() :: nil
  def test_basic_indexed_iteration() do
    (
          items = ["apple", "banana", "cherry"]
          results = []
          g_counter = 0
          g_array = items.length
          items
    |> Enum.with_index()
    |> Enum.map(fn {item, i} -> "" <> to_string(i) <> ": " <> item end)
          Log.trace(results, %{"fileName" => "Main.hx", "lineNumber" => 20, "className" => "Main", "methodName" => "testBasicIndexedIteration"})
        )
  end

  @doc "Function test_indexed_map"
  @spec test_indexed_map() :: Array.t()
  def test_indexed_map() do
    (
          items = ["first", "second", "third"]
          indexed = []
          g_counter = 0
          g_array = items.length
          items
    |> Enum.with_index()
    |> Enum.map(fn {item, i} -> "Item #" <> to_string(((i + 1))) <> ": " <> item end)
          indexed
        )
  end

  @doc "Function test_indexed_filter"
  @spec test_indexed_filter() :: Array.t()
  def test_indexed_filter() do
    (
          items = ["a", "b", "c", "d", "e"]
          even_indexed = []
          g_counter = 0
          g_array = items.length
          items
    |> Enum.with_index()
    |> Enum.map(fn {item, i} -> item end)
          even_indexed
        )
  end

  @doc "Function test_complex_indexed_operation"
  @spec test_complex_indexed_operation() :: integer()
  def test_complex_indexed_operation() do
    (
          numbers = [10, 20, 30, 40, 50]
          sum = 0
          g_counter = 0
          g_array = numbers.length
          numbers
    |> Enum.with_index()
    |> Enum.each(fn {item, i} ->
      (
            i = g_counter + 1
            sum = sum + (item * ((i + 1)))
          )
    end)
          sum
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
