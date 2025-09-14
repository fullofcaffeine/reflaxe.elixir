defmodule Main do
  def main() do
    test_simple_while_loop("test", 5)
    result = binary_search([1, 3, 5, 7, 9], 5)
    Log.trace("Found: " <> Std.string(result), %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "main"})
    process_items(["a", "b", "c"], 10, true)
  end
  defp test_simple_while_loop(key, limit) do
    count = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {limit, count, :ok}, fn _, {acc_limit, acc_count, acc_state} ->
  if (acc_count < acc_limit) do
    if (key == "test"), do: "Found: " <> key
    acc_count = acc_count + 1
    {:cont, {acc_limit, acc_count, acc_state}}
  else
    {:halt, {acc_limit, acc_count, acc_state}}
  end
end)
    "Not found"
  end
  defp binary_search(arr, target) do
    left = 0
    right = (length(arr) - 1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {left, right, :ok}, fn _, {acc_left, acc_right, acc_state} ->
  if (acc_left <= acc_right) do
    mid = Std.int((acc_left + acc_right) / 2)
    if (arr[mid] == target), do: true, else: nil
    {:cont, {acc_left, acc_right, acc_state}}
  else
    {:halt, {acc_left, acc_right, acc_state}}
  end
end)
    false
  end
  defp process_items(items, max_count, verbose) do
    processed = 0
    index = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, max_count, processed, index, :ok}, fn _, {acc_items, acc_max_count, acc_processed, acc_index, acc_state} ->
  if (acc_index < length(acc_items) && acc_processed < acc_max_count) do
    item = acc_items[acc_index]
    if verbose do
      Log.trace("Processing: " <> item, %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "processItems"})
    end
    acc_processed = acc_processed + 1
    acc_index = acc_index + 1
    {:cont, {acc_items, acc_max_count, acc_processed, acc_index, acc_state}}
  else
    {:halt, {acc_items, acc_max_count, acc_processed, acc_index, acc_state}}
  end
end)
    Log.trace("Processed " <> Kernel.to_string(processed) <> " items out of max " <> Kernel.to_string(max_count), %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "processItems"})
  end
end