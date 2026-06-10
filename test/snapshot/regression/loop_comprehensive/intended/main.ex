defmodule Main do
  def main() do
    evens = []
    evens = evens ++ [0]
    evens = evens ++ [2]
    evens = evens ++ [4]
    evens = evens ++ [6]
    evens = evens ++ [8]
    _ = evens
    _g = 0
    _ = Enum.each(0..9//1, fn i ->
  if (i == 5) do
    throw(:break)
  end
  nil
end)
    _g = 0
    _ = Enum.each(0..4//1, fn i ->
  if (i == 2) do
    throw(:continue)
  end
  nil
end)
    _ = 1
    _ = 2
    _ = 3
    _ = 4
    count = 0
    {_count} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {count}, fn _, {acc_count} ->
      try do
        if (acc_count < 3) do
          _old_count = acc_count
          acc_count = acc_count + 1
          {:cont, {acc_count}}
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
  end
end
