defmodule Main do
  def main() do
    _ = test_simple_for_loop()
    _ = test_while_loop()
    _ = test_array_map()
    _ = test_array_filter()
    _ = test_string_iteration()
    _ = test_nested_loops()
    _ = test_loop_with_break()
    _ = test_loop_with_continue()
  end
  defp test_simple_for_loop() do
    nil
  end
  defp test_while_loop() do
    count = 0
    sum = 0
    {_count, sum} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {count, sum}, fn _, {acc_count, acc_sum} ->
      try do
        if (acc_count < 10) do
          acc_sum = acc_sum + acc_count
          old_count = acc_count
          acc_count = acc_count + 1
          {:cont, {acc_count, acc_sum}}
        else
          {:halt, {acc_count, acc_sum}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_count, acc_sum}}
        :throw, :continue ->
          {:cont, {acc_count, acc_sum}}
      end
    end)
    sum
  end
  defp test_array_map() do
    numbers = [1, 2, 3, 4, 5]
    _ = Enum.map(numbers, fn x -> x * 2 end)
  end
  defp test_array_filter() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    _ = Enum.filter(numbers, fn x -> rem(x, 2) == 0 end)
  end
  defp test_string_iteration() do
    input = "Hello World!"
    result = ""
    _g = 0
    input_length = String.length(input)
    result = Enum.reduce(0..(input_length - 1)//1, result, fn i, result_acc ->
      c = if (i < 0) do
        nil
      else
        Enum.at(String.to_charlist(input), i)
      end
      cond do
        c >= 65 and c <= 90 or c >= 97 and c <= 122 or c >= 48 and c <= 57 ->
          result_acc = result_acc <> (fn ->
  code = c
  <<code::utf8>>
end).()
          result_acc
        c == 32 ->
          result_acc = result_acc <> "+"
          result_acc
        :true ->
          result_acc = result_acc <> "%" <> String.upcase(StringTools.hex(c, 2))
          result_acc
      end
    end)
    result
  end
  defp test_nested_loops() do
    result = []
    result = result ++ ["(#{Kernel.to_string(0)}, #{Kernel.to_string(0)})"]
    result = result ++ ["(#{Kernel.to_string(0)}, #{Kernel.to_string(1)})"]
    result = result ++ ["(#{Kernel.to_string(0)}, #{Kernel.to_string(2)})"]
    result = result ++ ["(#{Kernel.to_string(1)}, #{Kernel.to_string(0)})"]
    result = result ++ ["(#{Kernel.to_string(1)}, #{Kernel.to_string(1)})"]
    result = result ++ ["(#{Kernel.to_string(1)}, #{Kernel.to_string(2)})"]
    result = result ++ ["(#{Kernel.to_string(2)}, #{Kernel.to_string(0)})"]
    result = result ++ ["(#{Kernel.to_string(2)}, #{Kernel.to_string(1)})"]
    result = result ++ ["(#{Kernel.to_string(2)}, #{Kernel.to_string(2)})"]
    result
  end
  defp test_loop_with_break() do
    result = -1
    _g = 0
    result = Enum.reduce(0..99//1, result, fn i, _result_acc ->
      if (i * i > 50) do
        throw(:break)
        i
      else
        i
      end
    end)
    result
  end
  defp test_loop_with_continue() do
    result = []
    _g = 0
    result = Enum.reduce(0..9//1, result, fn i, result_acc ->
      if (rem(i, 2) == 0) do
        throw(:continue)
      end
      Enum.concat(result_acc, [i])
    end)
    result
  end
end
