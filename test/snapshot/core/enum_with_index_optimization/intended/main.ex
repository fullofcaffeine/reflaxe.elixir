defmodule Main do
  def main() do
    test_basic_indexed_iteration()
    test_indexed_map()
    test_indexed_filter()
    test_complex_indexed_operation()
  end

  defp test_basic_indexed_iteration() do
    items = ["apple", "banana", "cherry"]

    results = items
      |> Enum.with_index()
      |> Enum.map(fn {item, i} -> "#{i}: #{item}" end)

    Log.trace(results, %{:file_name => "Main.hx", :line_number => 20, :class_name => "Main", :method_name => "testBasicIndexedIteration"})
  end
  defp test_indexed_map() do
    items = ["first", "second", "third"]

    items
    |> Enum.with_index()
    |> Enum.map(fn {item, i} -> "Item ##{i + 1}: #{item}" end)
  end
  defp test_indexed_filter() do
    items = ["a", "b", "c", "d", "e"]

    items
    |> Enum.with_index()
    |> Enum.filter(fn {_item, i} -> rem(i, 2) == 0 end)
    |> Enum.map(fn {item, _i} -> item end)
  end
  defp test_complex_indexed_operation() do
    numbers = [10, 20, 30, 40, 50]

    numbers
    |> Enum.with_index()
    |> Enum.reduce(0, fn {value, i}, sum ->
      # Weighted sum: value * (index + 1)
      sum + value * (i + 1)
    end)
  end
end