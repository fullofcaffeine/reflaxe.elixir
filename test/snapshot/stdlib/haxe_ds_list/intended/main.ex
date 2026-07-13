defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    values = Haxe.Ds.List.new()
    values = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :add, [values, "one"])
    values = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :add, [values, "two"])
    values = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :push, [values, "zero"])
    assert_that(values.length == 3, "length should track add and push")
    assert_that(apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :first, [values]) == "zero", "first should reflect pushed head")
    assert_that(apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :last, [values]) == "two", "last should reflect appended tail")
    assert_that(apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :to_string, [values]) == "{zero, one, two}", "toString should preserve order")
    entries = Array.new()
    key_value_iterator = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :key_value_iterator, [values])
    {entries} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {entries}, fn _, {acc_entries} ->
      try do
        if (apply(Map.get(key_value_iterator, :__reflaxe_class__) || Map.get(key_value_iterator, :__struct__), :has_next, [key_value_iterator])) do
          entry = apply(Map.get(key_value_iterator, :__reflaxe_class__) || Map.get(key_value_iterator, :__struct__), :next, [key_value_iterator])
          acc_entries = acc_entries ++ [Reflaxe.Elixir.HaxeFloat.to_string(entry.key) <> ":" <> entry.value]
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
    assert_that(Enum.join(entries, ",") == "0:zero,1:one,2:two", "keyValueIterator should preserve indices")
    {values, reflaxe_receiver_value_0} = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :remove, [values, "one"])
    assert_that(reflaxe_receiver_value_0, "remove should delete first matching value")
    {values, reflaxe_receiver_value_1} = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :remove, [values, "missing"])
    assert_that(not reflaxe_receiver_value_1, "remove should report missing values")
    {values, reflaxe_receiver_value_2} = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :pop, [values])
    assert_that(reflaxe_receiver_value_2 == "zero", "pop should remove the head")
    assert_that(apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :to_string, [values]) == "{two}", "pop/remove should rebind receiver state")
    mapped = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :map, [values, fn value -> value <> "!" end])
    assert_that(apply(Map.get(mapped, :__reflaxe_class__) || Map.get(mapped, :__struct__), :to_string, [mapped]) == "{two!}", "map should return a new list")
    values = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :clear, [values])
    assert_that(apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :is_empty, [values]), "clear should empty the list")
  end
end
