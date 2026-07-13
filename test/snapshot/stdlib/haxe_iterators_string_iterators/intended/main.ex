defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    iterator = StringIterator.new("aé中")
    codes = Array.new()
    {codes} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {codes}, fn _, {acc_codes} ->
      try do
        if (apply(Map.get(iterator, :__reflaxe_class__) || Map.get(iterator, :__struct__), :has_next, [iterator])) do
          acc_codes = acc_codes ++ [apply(Map.get(iterator, :__reflaxe_class__) || Map.get(iterator, :__struct__), :next, [iterator])]
          {:cont, {acc_codes}}
        else
          {:halt, {acc_codes}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_codes}}
        :throw, :continue ->
          {:cont, {acc_codes}}
      end
    end)
    assert_that(Enum.join(codes, ",") == "97,233,20013", "StringIterator should return codepoints")
    key_value_iterator = StringKeyValueIterator.new("aé中")
    entries = Array.new()
    {entries} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {entries}, fn _, {acc_entries} ->
      try do
        if (apply(Map.get(key_value_iterator, :__reflaxe_class__) || Map.get(key_value_iterator, :__struct__), :has_next, [key_value_iterator])) do
          entry = apply(Map.get(key_value_iterator, :__reflaxe_class__) || Map.get(key_value_iterator, :__struct__), :next, [key_value_iterator])
          acc_entries = acc_entries ++ [Reflaxe.Elixir.HaxeFloat.to_string(entry.key) <> ":" <> Reflaxe.Elixir.HaxeFloat.to_string(entry.value)]
          {:cont, {acc_entries}}
        else
          {:halt, {acc_entries}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_entries}}
        :throw, :continue ->
          {:cont, {acc_entries}}
      end
    end)
    assert_that(Enum.join(entries, ",") == "0:97,1:233,2:20013", "StringKeyValueIterator should return character indices and codepoints")
  end
end
