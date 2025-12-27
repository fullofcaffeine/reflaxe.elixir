defmodule Main do
  defp test_simple_while_loop(key, limit) do
    count = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, fn _, {count} ->
      if (count < limit) do
        count = if (key == "test") do
          "Found: " <> key
          count
        else
          _old_count = count
          count = count + 1
          count
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
    {left, right} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {left, right}, fn _, {left, right} ->
      if (left <= right) do
        mid = trunc((left + right) / 2)
        {left, right} = cond do
          arr[mid] == target ->
            true
            {left, right}
          arr[mid] < target ->
            left = mid + 1
            {left, right}
          :true ->
            right = (mid - 1)
            {left, right}
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
    {processed, index} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0, 0}, fn _, {processed, index} ->
      if (index < length(items) and processed < max_count) do
        item = items[index]
        if (verbose), do: nil
        _old_processed = processed
        processed = processed + 1
        old_index = index
        index = index + 1
        old_index
        {:cont, {processed, index}}
      else
        {:halt, {processed, index}}
      end
    end)
    nil
    nil
  end
end
