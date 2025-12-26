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
    _g = 0
    _ = length(items)
    results = Enum.reduce(0..(items_length - 1)//1, results, fn i, results -> Enum.concat(results, ["" <> Kernel.to_string(i) <> ": " <> item]) end)
    results
    nil
  end
  defp test_indexed_map() do
    items = ["first", "second", "third"]
    indexed = []
    _g = 0
    _ = length(items)
    indexed = Enum.reduce(0..(items_length - 1)//1, indexed, fn i, indexed -> Enum.concat(indexed, ["Item #" <> Kernel.to_string(i + 1) <> ": " <> items[i]]) end)
    indexed
    indexed
  end
  defp test_indexed_filter() do
    items = ["a", "b", "c", "d", "e"]
    even_indexed = []
    _g = 0
    _ = length(items)
    even_indexed = Enum.reduce(0..(items_length - 1)//1, even_indexed, fn i, even_indexed -> Enum.concat(even_indexed, [items[i]]) end)
    even_indexed
    even_indexed
  end
  defp test_complex_indexed_operation() do
    numbers = [10, 20, 30, 40, 50]
    sum = 0
    _g = 0
    _ = length(numbers)
    sum = Enum.reduce(0..(numbers_length - 1)//1, sum, fn i, sum -> sum + numbers[i] * i + 1 end)
    sum
    sum
  end
end
