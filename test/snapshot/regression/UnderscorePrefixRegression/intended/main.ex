defmodule Main do
  def main() do
    _ = test_simple_while_loop("test", 5)
    _result = binary_search([1, 3, 5, 7, 9], 5)
    _ = process_items(["a", "b", "c"], 10, true)
  end
  defp test_simple_while_loop(key, limit) do
    count = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {count}, fn _, {acc_count} ->
      try do
        if (acc_count < limit) do
          if (key == "test") do
            "Found: " <> key
          else
            old_count = acc_count
            acc_count = acc_count + 1
            {:cont, {acc_count}}
          end
        else
          {:halt, {acc_count}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_count}}
        :throw, :continue ->
          {:cont, {acc_count}}
      end
    end)
    "Not found"
  end
  defp binary_search(arr, target) do
    left = 0
    right = (length(arr) - 1)
    {_left, _right} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {left, right}, fn _, {acc_left, acc_right} ->
      try do
        if (acc_left <= acc_right) do
          mid = trunc((acc_left + acc_right) / 2)
          cond do
            arr[mid] == target -> true
            arr[mid] < target -> acc_left = mid + 1
            :true -> acc_right = (mid - 1)
          end
          {:cont, {acc_left, acc_right}}
        else
          {:halt, {acc_left, acc_right}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_left, acc_right}}
        :throw, :continue ->
          {:cont, {acc_left, acc_right}}
      end
    end)
    false
  end
  defp process_items(items, max_count, verbose) do
    processed = 0
    index = 0
    {_processed, _index} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {processed, index}, fn _, {acc_processed, acc_index} ->
      try do
        if (acc_index < length(items) and acc_processed < max_count) do
          item = items[acc_index]
          if (verbose), do: nil
          old_processed = acc_processed
          acc_processed = acc_processed + 1
          old_index = acc_index
          acc_index = acc_index + 1
          {:cont, {acc_processed, acc_index}}
        else
          {:halt, {acc_processed, acc_index}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_processed, acc_index}}
        :throw, :continue ->
          {:cont, {acc_processed, acc_index}}
      end
    end)
    nil
  end
end
