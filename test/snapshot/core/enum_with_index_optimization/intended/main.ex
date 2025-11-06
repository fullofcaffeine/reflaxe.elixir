defmodule Main do
  def main() do
    _ = test_basic_indexed_iteration()
    _ = test_indexed_map()
    _ = test_indexed_filter()
    _ = test_complex_indexed_operation()
    _
  end
  defp test_basic_indexed_iteration() do
    _ = ["apple", "banana", "cherry"]
    _ = []
    _ = Enum.each(items, (fn -> fn item ->
  i = 1
  item = items[i]
  item = Enum.concat(item, ["" <> Kernel.to_string(i) <> ": " <> item])
end end).())
    _ = Log.trace(results, %{:file_name => "Main.hx", :line_number => 20, :class_name => "Main", :method_name => "testBasicIndexedIteration"})
    _
  end
  defp test_indexed_map() do
    _ = ["first", "second", "third"]
    _ = Enum.each(items, (fn -> fn item ->
  i = 1
  item = Enum.concat(item, ["Item #" <> Kernel.to_string(i + 1) <> ": " <> items[i]])
end end).())
    []
  end
  defp test_indexed_filter() do
    _ = ["a", "b", "c", "d", "e"]
    _ = Enum.each(items, (fn -> fn item ->
  i = 1
  if (rem(item, 2) == 0), do: item = Enum.concat(item, [items[i]])
end end).())
    []
  end
  defp test_complex_indexed_operation() do
    sum = 0
    _ = [10, 20, 30, 40, 50]
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
