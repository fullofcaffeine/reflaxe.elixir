defmodule Main do
  def main() do
    Main.test_basic_indexed_iteration()
    Main.test_indexed_map()
    Main.test_indexed_filter()
    Main.test_complex_indexed_operation()
  end
  defp test_basic_indexed_iteration() do
    items = ["apple", "banana", "cherry"]
    results = []
    g = 0
    g1 = items.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  item = items[i]
  results.push("" + i + ": " + item)
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace(results, %{:fileName => "Main.hx", :lineNumber => 20, :className => "Main", :methodName => "testBasicIndexedIteration"})
  end
  defp test_indexed_map() do
    items = ["first", "second", "third"]
    indexed = []
    g = 0
    g1 = items.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  indexed.push("Item #" + (i + 1) + ": " + items[i])
  {:cont, acc}
else
  {:halt, acc}
end end)
    indexed
  end
  defp test_indexed_filter() do
    items = ["a", "b", "c", "d", "e"]
    even_indexed = []
    g = 0
    g1 = items.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  if (i rem 2 == 0), do: even_indexed.push(items[i])
  {:cont, acc}
else
  {:halt, acc}
end end)
    even_indexed
  end
  defp test_complex_indexed_operation() do
    numbers = [10, 20, 30, 40, 50]
    sum = 0
    g = 0
    g1 = numbers.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  sum = sum + numbers[i] * (i + 1)
  {:cont, acc}
else
  {:halt, acc}
end end)
    sum
  end
end