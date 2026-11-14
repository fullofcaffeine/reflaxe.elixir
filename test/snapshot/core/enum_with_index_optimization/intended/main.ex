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
    _g = 0
    items_length = length(items)
    _ = Enum.reverse(Enum.reduce(0..(items_length - 1)//1, results, fn i, results_acc ->
      item = Enum.at(items, i)
      ["" <> Reflaxe.Elixir.HaxeFloat.to_string(i) <> ": " <> item | results_acc]
    end))
    nil
  end
  defp test_indexed_map() do
    items = ["first", "second", "third"]
    _g = 0
    items_length = length(items)
    indexed = Enum.map(0..(items_length - 1)//1, fn i -> "Item #" <> Reflaxe.Elixir.HaxeFloat.to_string(i + 1) <> ": " <> Enum.at(items, i) end)
    indexed
  end
  defp test_indexed_filter() do
    items = ["a", "b", "c", "d", "e"]
    even_indexed = []
    _g = 0
    items_length = length(items)
    even_indexed = Enum.reverse(Enum.reduce(0..(items_length - 1)//1, even_indexed, fn i, even_indexed_acc ->
      if (rem(i, 2) == 0) do
        even_indexed_acc = [Enum.at(items, i) | even_indexed_acc]
        even_indexed_acc
      else
        even_indexed_acc
      end
    end))
    even_indexed
  end
  defp test_complex_indexed_operation() do
    numbers = [10, 20, 30, 40, 50]
    sum = 0
    _g = 0
    numbers_length = length(numbers)
    sum = Enum.reduce(0..(numbers_length - 1)//1, sum, fn i, sum_acc -> sum_acc + Enum.at(numbers, i) * (i + 1) end)
    sum
  end
end
