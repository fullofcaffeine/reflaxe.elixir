defmodule Main do
  def main() do
    test_simple_while_loop("test", 5)
    result = binary_search([1, 3, 5, 7, 9], 5)
    Log.trace("Found: #{result}", %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "main"})
    process_items(["a", "b", "c"], 10, true)
  end
  defp test_simple_while_loop(key, limit) do
    Enum.each(0..(limit-1), fn count ->
      if key == "test", do: "Found: #{key}"
    end)
    "Not found"
  end
  defp binary_search(arr, target) do
    binary_search_recursive(arr, target, 0, length(arr) - 1)
  end

  defp binary_search_recursive(arr, target, left, right) when left <= right do
    mid = div(left + right, 2)
    cond do
      Enum.at(arr, mid) == target -> true
      Enum.at(arr, mid) < target -> binary_search_recursive(arr, target, mid + 1, right)
      true -> binary_search_recursive(arr, target, left, mid - 1)
    end
  end
  defp binary_search_recursive(_arr, _target, _left, _right), do: false
  defp process_items(items, max_count, verbose) do
    items
    |> Enum.take(max_count)
    |> Enum.each(fn item ->
      if verbose do
        Log.trace("Processing: #{item}", %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "processItems"})
      end
    end)
    Log.trace("Processed #{processed} items out of max #{max_count}", %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "processItems"})
  end
end