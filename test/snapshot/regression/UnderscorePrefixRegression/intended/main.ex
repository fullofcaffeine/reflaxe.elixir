defmodule Main do
  def main() do
    test_simple_while_loop("test", 5)
    _result = binary_search([1, 3, 5, 7, 9], 5)
    process_items(["a", "b", "c"], 10, true)
  end
  defp test_simple_while_loop(key, limit) do
    count = 0
    (case Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {:__reflaxe_continue__, {count}}, fn _, {:__reflaxe_continue__, {acc_count}} ->
      try do
        if (acc_count < limit) do
          (case (if (key == "test"), do: {:halt, {:__reflaxe_return__, "Found: " <> key}}, else: {:cont, {:__reflaxe_continue__, {acc_count}}}) do
            {:halt, reflaxe_halt_payload} -> {:halt, reflaxe_halt_payload}
            {:cont, {:__reflaxe_continue__, {acc_count}}} ->
              acc_count = acc_count + 1
              {:cont, {:__reflaxe_continue__, {acc_count}}}
          end)
        else
          {:halt, {:__reflaxe_continue__, {acc_count}}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, {:__reflaxe_continue__, break_state}}
        :throw, {:continue, continue_state} ->
          {:cont, {:__reflaxe_continue__, continue_state}}
        :throw, :break ->
          {:halt, {:__reflaxe_continue__, {acc_count}}}
        :throw, :continue ->
          {:cont, {:__reflaxe_continue__, {acc_count}}}
      end
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {reflaxe_continue_count}} ->
        {_count} = {reflaxe_continue_count}
        "Not found"
    end)
  end
  defp binary_search(arr, target) do
    left = 0
    right = (length(arr) - 1)
    (case Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {:__reflaxe_continue__, {left, right}}, fn _, {:__reflaxe_continue__, {acc_left, acc_right}} ->
      try do
        if (acc_left <= acc_right) do
          mid = trunc(Reflaxe.Elixir.HaxeFloat.divide(acc_left + acc_right, 2))
          cond do
            Enum.at(arr, mid) == target -> {:halt, {:__reflaxe_return__, true}}
            Enum.at(arr, mid) < target ->
              acc_left = mid + 1
              {:cont, {:__reflaxe_continue__, {acc_left, acc_right}}}
            true ->
              acc_right = (mid - 1)
              {:cont, {:__reflaxe_continue__, {acc_left, acc_right}}}
          end
        else
          {:halt, {:__reflaxe_continue__, {acc_left, acc_right}}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, {:__reflaxe_continue__, break_state}}
        :throw, {:continue, continue_state} ->
          {:cont, {:__reflaxe_continue__, continue_state}}
        :throw, :break ->
          {:halt, {:__reflaxe_continue__, {acc_left, acc_right}}}
        :throw, :continue ->
          {:cont, {:__reflaxe_continue__, {acc_left, acc_right}}}
      end
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {reflaxe_continue_left, reflaxe_continue_right}} ->
        {_left, _right} = {reflaxe_continue_left, reflaxe_continue_right}
        false
    end)
  end
  defp process_items(items, max_count, verbose) do
    processed = 0
    index = 0
    {_processed, _index} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {processed, index}, fn _, {acc_processed, acc_index} ->
      try do
        if (acc_index < length(items) and acc_processed < max_count) do
          _item = Enum.at(items, acc_index)
          if (verbose), do: nil
          acc_processed = acc_processed + 1
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
