defmodule Main do
  def main() do
    test_basic_indexed_iteration()
    test_indexed_map()
    test_indexed_filter()
    test_complex_indexed_operation()
  end
  defp test_basic_indexed_iteration() do
    items = ["apple", "banana", "cherry"]
    results = []
    g = 0
    g1 = items.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    item = items[i]
    results ++ ["" <> i <> ": " <> item]
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    Log.trace(results, %{:fileName => "Main.hx", :lineNumber => 20, :className => "Main", :methodName => "testBasicIndexedIteration"})
  end
  defp test_indexed_map() do
    items = ["first", "second", "third"]
    indexed = []
    g = 0
    g1 = items.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    indexed ++ ["Item #" <> (i + 1) <> ": " <> items[i]]
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    indexed
  end
  defp test_indexed_filter() do
    items = ["a", "b", "c", "d", "e"]
    even_indexed = []
    g = 0
    g1 = items.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    if (i rem 2 == 0), do: even_indexed ++ [items[i]]
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    even_indexed
  end
  defp test_complex_indexed_operation() do
    numbers = [10, 20, 30, 40, 50]
    sum = 0
    g = 0
    g1 = numbers.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, sum, :ok}, fn _, {acc_g, acc_g1, acc_sum, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    acc_sum = acc_sum + numbers[i] * (i + 1)
    {:cont, {acc_g, acc_g1, acc_sum, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_sum, acc_state}}
  end
end)
    sum
  end
end