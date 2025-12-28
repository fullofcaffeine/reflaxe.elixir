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
    items_length = length(items)
    results = Enum.reduce(0..(items_length - 1)//1, results, fn i, results_acc ->
      item = items[i]
      Enum.concat(results_acc, ["" <> Kernel.to_string(i) <> ": " <> item])
    end)
    nil
  end
  defp test_indexed_map() do
    items = ["first", "second", "third"]
    indexed = []
    _g = 0
    items_length = length(items)
    indexed = Enum.reduce(0..(items_length - 1)//1, indexed, fn i, indexed_acc -> Enum.concat(indexed_acc, ["Item #" <> Kernel.to_string(i + 1) <> ": " <> items[i]]) end)
    indexed
  end
  defp test_indexed_filter() do
    items = ["a", "b", "c", "d", "e"]
    even_indexed = []
    _g = 0
    items_length = length(items)
    even_indexed = Enum.reduce(0..(items_length - 1)//1, even_indexed, fn i, even_indexed_acc ->
      if (rem(i, 2) == 0) do
        even_indexed_acc = Enum.concat(even_indexed_acc, [items[i]])
        even_indexed_acc
      else
        even_indexed_acc
      end
    end)
    even_indexed
  end
  defp test_complex_indexed_operation() do
    numbers = [10, 20, 30, 40, 50]
    sum = 0
    _g = 0
    numbers_length = length(numbers)
    sum = Enum.reduce(0..(numbers_length - 1)//1, sum, fn i, sum_acc -> sum_acc + numbers[i] * (i + 1) end)
    sum
  end
end
