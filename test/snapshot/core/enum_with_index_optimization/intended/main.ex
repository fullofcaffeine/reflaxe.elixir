defmodule Main do
  def main() do
    _ = test_basic_indexed_iteration()
    _ = test_indexed_map()
    _ = test_indexed_filter()
    _ = test_complex_indexed_operation()
  end
  defp test_basic_indexed_iteration() do
    items = ["apple", "banana", "cherry"]
    results = []
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items}, (fn -> fn _, {items} ->
  if (0 < length(items)) do
    i = 1
    item = items[i]
    results = Enum.concat(results, ["" <> Kernel.to_string(i) <> ": " <> item])
    {:cont, {items}}
  else
    {:halt, {items}}
  end
end end).())
    nil
  end
  defp test_indexed_map() do
    items = ["first", "second", "third"]
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items}, (fn -> fn _, {items} ->
  if (0 < length(items)) do
    i = 1
    indexed = Enum.concat(indexed, ["Item #" <> Kernel.to_string(i + 1) <> ": " <> items[i]])
    {:cont, {items}}
  else
    {:halt, {items}}
  end
end end).())
    []
  end
  defp test_indexed_filter() do
    items = ["a", "b", "c", "d", "e"]
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items}, (fn -> fn _, {items} ->
  if (0 < length(items)) do
    i = 1
    if (rem(i, 2) == 0), do: even_indexed = Enum.concat(even_indexed, [items[i]])
    {:cont, {items}}
  else
    {:halt, {items}}
  end
end end).())
    []
  end
  defp test_complex_indexed_operation() do
    numbers = [10, 20, 30, 40, 50]
    sum = 0
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, sum}, (fn -> fn _, {numbers, sum} ->
  if (0 < length(numbers)) do
    i = 1
    sum = sum + numbers[i] * i + 1
    {:cont, {numbers, sum}}
  else
    {:halt, {numbers, sum}}
  end
end end).())
    sum
  end
end
