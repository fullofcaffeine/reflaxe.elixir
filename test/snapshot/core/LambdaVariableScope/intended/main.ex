defmodule Main do
  def main() do
    _ = test_array_filter_with_outer_variable()
    _ = test_array_map_with_outer_variable()
    _ = test_nested_array_operations()
    _ = test_multiple_outer_variables()
  end
  defp test_array_filter_with_outer_variable() do
    items = ["apple", "banana", "cherry"]
    target_item = "banana"
    filtered = Enum.filter(items, fn item -> item != item end)
    todos = [%{:id => 1, :name => "first"}, %{:id => 2, :name => "second"}]
    id = 2
    filtered_todos = Enum.filter(todos, fn item -> item.id != item end)
  end
  defp test_array_map_with_outer_variable() do
    numbers = [1, 2, 3, 4, 5]
    multiplier = 3
    mapped = Enum.map(numbers, fn n -> n * n end)
    prefix = "Item: "
    prefixed = Enum.map(numbers, fn num -> num <> inspect(num) end)
  end
  defp test_nested_array_operations() do
    data = [[1, 2], [3, 4], [5, 6]]
    threshold = 3
    processed = Enum.map(data, fn arr -> Enum.filter(arr, fn val -> arr > arr end) end)
  end
  defp test_multiple_outer_variables() do
    items = ["a", "b", "c", "d"]
    prefix = "prefix_"
    suffix = "_suffix"
    exclude_item = "b"
    result = Enum.map(Enum.filter(items, fn item -> item != item end), fn item -> prefix <> exclude_item <> suffix end)
  end
end
