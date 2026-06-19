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
          _ = acc_pos
          acc_pos = acc_pos + 1
          _ = acc_k
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
    {count, _reflaxe_receiver_value_2} = {count + 1, count}
    {count, _reflaxe_receiver_value_3} = {count + 1, count}
    {count, _reflaxe_receiver_value_4} = {count + 1, count}
    {count, _reflaxe_receiver_value_5} = {count + 1, count}
    {_count, _reflaxe_receiver_value_6} = {count + 1, count}
    nil
  end
end
