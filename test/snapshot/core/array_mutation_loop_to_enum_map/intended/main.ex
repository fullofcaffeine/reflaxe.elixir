defmodule Main do
  def double_in_place(values) do
    values = Enum.map(values, fn item -> item * 2 end)
    values
  end
  def add_index_in_place(values) do
    values = Enum.with_index(values) |> Enum.map(fn {item, index} -> item + index end)
    values
  end
  def keep_stateful_when_counter_observed(values) do
    i = 0
    {i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i}, fn _, {acc_i} ->
      try do
        if (acc_i < length(values)) do
          _ = Enum.at(values, acc_i) * 2
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
    i
  end
  def main() do
    double_in_place([1, 2, 3])
    add_index_in_place([1, 2, 3])
    keep_stateful_when_counter_observed([1, 2, 3])
  end
end
