defmodule Main do
  def main() do
    test_simple_for_loop()
    test_while_loop()
    test_array_map()
    test_array_filter()
    test_string_iteration()
    test_nested_loops()
    test_loop_with_break()
    test_loop_with_continue()
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
    Enum.map(numbers, fn x -> x * 2 end)
  end
  defp test_array_filter() do
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    Enum.filter(numbers, fn x -> rem(x, 2) == 0 end)
  end
  defp test_string_iteration() do
    input = "Hello World!"
    result = ""
    _g = 0
    input_length = String.length(input)
    result = Enum.reduce(0..(input_length - 1)//1, result, fn i, result_acc ->
      c = StringTools.haxe_char_code_at(input, i)
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
        true ->
          result_acc = result_acc <> "%" <> String.upcase(StringTools.hex(c, 2))
          result_acc
      end
    end)
    result
  end
  defp test_nested_loops() do
    result = []
    result = result ++ ["(#{Reflaxe.Elixir.HaxeFloat.to_string(0)}, #{Reflaxe.Elixir.HaxeFloat.to_string(0)})"]
    result = result ++ ["(#{Reflaxe.Elixir.HaxeFloat.to_string(0)}, #{Reflaxe.Elixir.HaxeFloat.to_string(1)})"]
    result = result ++ ["(#{Reflaxe.Elixir.HaxeFloat.to_string(0)}, #{Reflaxe.Elixir.HaxeFloat.to_string(2)})"]
    result = result ++ ["(#{Reflaxe.Elixir.HaxeFloat.to_string(1)}, #{Reflaxe.Elixir.HaxeFloat.to_string(0)})"]
    result = result ++ ["(#{Reflaxe.Elixir.HaxeFloat.to_string(1)}, #{Reflaxe.Elixir.HaxeFloat.to_string(1)})"]
    result = result ++ ["(#{Reflaxe.Elixir.HaxeFloat.to_string(1)}, #{Reflaxe.Elixir.HaxeFloat.to_string(2)})"]
    result = result ++ ["(#{Reflaxe.Elixir.HaxeFloat.to_string(2)}, #{Reflaxe.Elixir.HaxeFloat.to_string(0)})"]
    result = result ++ ["(#{Reflaxe.Elixir.HaxeFloat.to_string(2)}, #{Reflaxe.Elixir.HaxeFloat.to_string(1)})"]
    result = result ++ ["(#{Reflaxe.Elixir.HaxeFloat.to_string(2)}, #{Reflaxe.Elixir.HaxeFloat.to_string(2)})"]
    result
  end
  defp test_loop_with_break() do
    result = -1
    _g = 0
    result = Enum.reduce_while(0..99//1, result, fn i, result_acc ->
      try do
        if (i * i > 50) do
          result_acc = i
          throw({:break, result_acc})
          {:cont, result_acc}
        else
          {:cont, result_acc}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, result_acc}
        :throw, :continue ->
          {:cont, result_acc}
      end
    end)
    result
  end
  defp test_loop_with_continue() do
    result = []
    _g = 0
    result = Enum.reduce_while(0..9//1, result, fn i, result_acc ->
      try do
        if (rem(i, 2) == 0) do
          throw({:continue, result_acc})
        end
        result_acc = Enum.concat(result_acc, [i])
        {:cont, result_acc}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, result_acc}
        :throw, :continue ->
          {:cont, result_acc}
      end
    end)
    result
  end
end
