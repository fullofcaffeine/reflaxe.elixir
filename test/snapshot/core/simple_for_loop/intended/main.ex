defmodule Main do
  def main() do
    fruits = ["apple", "banana", "orange"]
    _g = 0
    _ = Enum.each(fruits, fn _ -> nil end)
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i}, fn _, {acc_i} ->
      try do
        if (acc_i < length(fruits)) do
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
  end
end
