defmodule Main do
  def sum_codes(source) do
    total = 0
    index = 0
    {total, _index} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, index}, fn _, {acc_total, acc_index} ->
      try do
        if (acc_index < StringTools.haxe_length(source)) do
          acc_total = acc_total + StringTools.haxe_char_code_at(source, acc_index)
          acc_index = acc_index + 1
          {:cont, {acc_total, acc_index}}
        else
          {:halt, {acc_total, acc_index}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_total, acc_index}}
        :throw, :continue ->
          {:cont, {acc_total, acc_index}}
      end
    end)
    total
  end
  def count(source, wanted) do
    found = 0
    index = 0
    {found, _index} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {found, index}, fn _, {acc_found, acc_index} ->
      try do
        if (acc_index < StringTools.haxe_length(source)) do
          acc_found = if (StringTools.haxe_char_at(source, acc_index) == wanted) do
            acc_found = acc_found + 1
            acc_found
          else
            acc_found
          end
          acc_index = acc_index + 1
          {:cont, {acc_found, acc_index}}
        else
          {:halt, {acc_found, acc_index}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_found, acc_index}}
        :throw, :continue ->
          {:cont, {acc_found, acc_index}}
      end
    end)
    found
  end
  def sum_numbers(source, separator) do
    total = 0
    start = 0
    index = 0
    {total, _start, _index} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total, start, index}, fn _, {acc_total, acc_start, acc_index} ->
      try do
        if (acc_index <= StringTools.haxe_length(source)) do
          {acc_start, acc_total} = if (acc_index == StringTools.haxe_length(source) or StringTools.haxe_substr_non_nil_len(source, acc_index, StringTools.haxe_length(separator)) == separator) do
            number = Reflaxe.Elixir.HaxeInt.parse(StringTools.haxe_substring(source, acc_start, acc_index))
            acc_total = if (not Kernel.is_nil(number)), do: acc_total + number, else: acc_total
            acc_start = acc_index + StringTools.haxe_length(separator)
            {acc_start, acc_total}
          else
            {acc_start, acc_total}
          end
          acc_index = acc_index + 1
          {:cont, {acc_total, acc_start, acc_index}}
        else
          {:halt, {acc_total, acc_start, acc_index}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_total, acc_start, acc_index}}
        :throw, :continue ->
          {:cont, {acc_total, acc_start, acc_index}}
      end
    end)
    total
  end
  def code_at(source, index) do
    StringTools.haxe_char_code_at(source, index)
  end
  def cut(source, start, length) do
    StringTools.haxe_substr_non_nil_len(source, start, length)
  end
  def release() do
    StringTools.release_index()
  end
  def main() do
    v = "#{Reflaxe.Elixir.HaxeFloat.to_string(sum_codes("12,34"))} #{Reflaxe.Elixir.HaxeFloat.to_string(count("12,34", ","))} #{Reflaxe.Elixir.HaxeFloat.to_string(sum_numbers("12,34", ","))}"
    IO.puts(v)
    v = "#{Reflaxe.Elixir.HaxeFloat.to_string(code_at("12,34", 0))} #{cut("12,34", 0, 2)}"
    IO.puts(v)
    release()
  end
end
