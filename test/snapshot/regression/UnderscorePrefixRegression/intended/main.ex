defmodule Main do
  defp test_simple_while_loop(key, limit) do
    count = 0
    _ = Enum.each(0..(limit - 1), (fn -> fn count ->
  if (count == "test"), do: "Found: " <> count
  count + 1
end end).())
    "Not found"
  end
  defp binary_search(arr, target) do
    left = 0
    right = (length(arr) - 1)
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {left, right}, (fn -> fn _, {left, right} ->
  if (left <= right) do
    mid = trunc.(left + right / 2)
    cond do
      arr[mid] == target -> true
      arr[mid] < target -> left = mid + 1
      :true -> right = (mid - 1)
    end
    {:cont, {left, right}}
  else
    {:halt, {left, right}}
  end
end end).())
    false
  end
  defp process_items(items, max_count, verbose) do
    processed = 0
    index = 0
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, max_count, processed, index}, (fn -> fn _, {items, max_count, processed, index} ->
  if (index < length(items) and processed < max_count) do
    item = items[index]
    if (verbose) do
      Log.trace("Processing: " <> item, %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "processItems"})
    end
    processed + 1
    index + 1
    {:cont, {items, max_count, processed, index}}
  else
    {:halt, {items, max_count, processed, index}}
  end
end end).())
    _ = Log.trace("Processed #{(fn -> processed end).()} items out of max #{(fn -> max_count end).()}", %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "processItems"})
  end
end
