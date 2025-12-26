defmodule Main do
  defp test_simple_while_loop(key, limit) do
    count = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, fn _, {count} ->
      if (count < limit) do
        if (key == "test") do
          "Found: " <> key
        else
          (old_count = count
count = count + 1
old_count)
        end
        {:cont, {count}}
      else
        {:halt, {count}}
      end
    end)
    nil
    "Not found"
  end
  defp binary_search(arr, target) do
    left = 0
    right = (length(arr) - 1)
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {left, right}, fn _, {left, right} ->
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
    end)
    nil
    false
  end
  defp process_items(items, max_count, verbose) do
    processed = 0
    index = 0
    {_, _} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, 0}, fn _, {processed, index} ->
      if (index < length(items) and processed < max_count) do
        item = items[index]
        if (verbose), do: nil
        (old_processed = processed
processed = processed + 1
old_processed)
        (old_index = index
index = index + 1
old_index)
        {:cont, {processed, index}}
      else
        {:halt, {processed, index}}
      end
    end)
    nil
    nil
  end
end
