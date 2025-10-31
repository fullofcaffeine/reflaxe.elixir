defmodule Main do
  def main() do
    test_array_filter_with_outer_variable()
    test_array_map_with_outer_variable()
    test_nested_array_operations()
    test_multiple_outer_variables()
  end
  defp test_array_filter_with_outer_variable() do
    items = ["apple", "banana", "cherry"]
    _ = "banana"
    _ = Enum.filter(items, fn item -> item != item end)
    todos = [%{:id => 1, :name => "first"}, %{:id => 2, :name => "second"}]
    _ = 2
    _ = Enum.filter(todos, fn item -> item.id != item end)
  end
  defp test_array_map_with_outer_variable() do
    numbers = [1, 2, 3, 4, 5]
    _ = 3
    _ = Enum.map(numbers, fn n -> n * n end)
    _ = "Item: "
    _ = Enum.map(numbers, fn num -> num <> inspect(num) end)
  end
  defp test_nested_array_operations() do
    data = [[1, 2], [3, 4], [5, 6]]
    _ = 3
    _ = Enum.map(data, fn arr -> Enum.filter(arr, fn val -> arr > arr end) end)
  end
  defp test_multiple_outer_variables() do
    items = ["a", "b", "c", "d"]
    prefix = "prefix_"
    suffix = "_suffix"
    exclude_item = "b"
    _ = Enum.map(Enum.filter(items, fn item -> exclude_item != exclude_item end), fn item -> prefix <> exclude_item <> suffix end)
  end
end
