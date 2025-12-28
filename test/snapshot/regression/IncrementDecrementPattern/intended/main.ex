defmodule Main do
  def main() do
    _ = test_while_loop()
    _ = test_for_loop()
  end
  defp test_while_loop() do
    k = 10
    pos = 0
    {_k, _pos} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, pos}, fn _, {acc_k, acc_pos} ->
      try do
        if (acc_k > 0) do
          old_pos = acc_pos
          acc_pos = acc_pos + 1
          old_k = acc_k
          acc_k = (acc_k - 1)
          {:cont, {acc_k, acc_pos}}
        else
          {:halt, {acc_k, acc_pos}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_k, acc_pos}}
        :throw, :continue ->
          {:cont, {acc_k, acc_pos}}
      end
    end)
    nil
  end
  defp test_for_loop() do
    count = 0
    _old_count = count
    count = count + 1
    old_count = count
    count = count + 1
    old_count = count
    count = count + 1
    old_count = count
    count = count + 1
    old_count = count
    count = count + 1
    nil
  end
end
