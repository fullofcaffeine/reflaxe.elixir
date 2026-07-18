defmodule Main do
  def main() do
    start = 0
    end_ = 10
    _g = start
    g_value = end_
    Enum.each(start..(g_value - 1)//1, fn _ -> nil end)
    arr = [1, 2, 3, 4, 5]
    _g = 0
    Enum.each(arr, fn _ -> nil end)
    k = 0
    {_k} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k}, fn _, {acc_k} ->
      try do
        if (acc_k < 5) do
          acc_k = acc_k + 1
          {:cont, {acc_k}}
        else
          {:halt, {acc_k}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_k}}
        :throw, :continue ->
          {:cont, {acc_k}}
      end
    end)
    str = "hello"
    result = ""
    _g = 0
    str_length = String.length(str)
    _ = Enum.reduce(0..(str_length - 1)//1, result, fn idx, result_acc ->
      c = StringTools.haxe_char_code_at(str, idx)
      if (c >= 97 and c <= 122) do
        result_acc <> (fn ->
          code = c
          <<code::utf8>>
        end).()
      else
        result_acc <> "%" <> StringTools.hex(c, 2)
      end
    end)
    nil
  end
end
