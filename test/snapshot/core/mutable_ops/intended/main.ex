defmodule Main do
  def main() do
    _ = test_mutable_ops()
    _ = test_variable_reassignment()
    _ = test_loop_counters()
  end
  defp test_mutable_ops() do
    x = 10
    x = x + 5
    x = (x - 3)
    x = x * 2
    x = rem(x, 3)
    str = "Hello"
    str = "#{str} World"
    arr = [1, 2, 3]
    arr = arr ++ [4, 5]
    nil
  end
  defp test_variable_reassignment() do
    count = 0
    count = count + 1
    count = count + 1
    count = count + 1
    value = 5
    value = if (value > 0), do: value * 2, else: value * -1
    result = 1
    result = result * 2
    result = result + 10
    result = (result - 5)
    nil
  end
  defp test_loop_counters() do
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i}, fn _, {acc_i} ->
      try do
        if (acc_i < 5) do
          old_i = acc_i
          acc_i = acc_i + 1
          {:cont, {acc_i}}
        else
          {:halt, {acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_i}}
        :throw, :continue ->
          {:cont, {acc_i}}
      end
    end)
    j = 5
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j}, fn _, {acc_j} ->
      try do
        if (acc_j > 0) do
          old_j = acc_j
          acc_j = (acc_j - 1)
          {:cont, {acc_j}}
        else
          {:halt, {acc_j}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_j}}
        :throw, :continue ->
          {:cont, {acc_j}}
      end
    end)
    sum = 0
    k = 1
    {_sum, _k} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum, k}, fn _, {acc_sum, acc_k} ->
      try do
        if (acc_k <= 5) do
          acc_sum = acc_sum + acc_k
          old_k = acc_k
          acc_k = acc_k + 1
          {:cont, {acc_sum, acc_k}}
        else
          {:halt, {acc_sum, acc_k}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_sum, acc_k}}
        :throw, :continue ->
          {:cont, {acc_sum, acc_k}}
      end
    end)
    total = 0
    x = 0
    {_total, _x} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, x}, fn _, {acc_total, acc_x} ->
      try do
        if (acc_x < 3) do
          y = 0
          {acc_total, y} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {acc_total, y}, fn _, {acc_total, acc_y} ->
            try do
              if (acc_y < 3) do
                acc_total = acc_total + 1
                old_y = acc_y
                acc_y = acc_y + 1
                {:cont, {acc_total, acc_y}}
              else
                {:halt, {acc_total, acc_y}}
              end
            catch
              :throw, {:break, break_state} ->
                {:halt, break_state}
              :throw, {:continue, continue_state} ->
                {:cont, continue_state}
              :throw, :break ->
                {:halt, {acc_total, acc_y}}
              :throw, :continue ->
                {:cont, {acc_total, acc_y}}
            end
          end)
          old_x = acc_x
          acc_x = acc_x + 1
          {:cont, {acc_total, acc_x}}
        else
          {:halt, {acc_total, acc_x}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_total, acc_x}}
        :throw, :continue ->
          {:cont, {acc_total, acc_x}}
      end
    end)
    nil
  end
end
