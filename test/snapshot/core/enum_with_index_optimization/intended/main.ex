defmodule Main do
  def main() do
    test_basic_indexed_iteration()
    test_indexed_map()
    test_indexed_filter()
    test_complex_indexed_operation()
  end
  defp test_basic_indexed_iteration() do
    items = ["apple", "banana", "cherry"]
    Enum.reduce(items, [], fn item, acc ->
      acc = Enum.concat(acc, ["" <> item.to_string() <> ": " <> item])
      acc
    end)
  end
  defp test_indexed_map() do
    items = ["first", "second", "third"]
    Enum.reduce(Map.values(items), [], fn item, acc -> if (Kernel.length(item.metas) > 0), do: acc ++ [item.metas[0]], else: acc end)
  end
  defp test_indexed_filter() do
    items = ["a", "b", "c", "d", "e"]
    Enum.reduce(Map.values(items), [], fn item, acc -> if (Kernel.length(item.metas) > 0), do: acc ++ [item.metas[0]], else: acc end)
  end
  defp test_complex_indexed_operation() do
    sum = 0
    numbers = [10, 20, 30, 40, 50]
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {numbers, sum}, fn _, {numbers, sum} ->
      if (0 < length(numbers)) do
        i = 1
        sum = sum + numbers[i] * i + 1
        {:cont, {numbers, sum}}
      else
        {:halt, {numbers, sum}}
      end
    end)
    sum
  end
end
