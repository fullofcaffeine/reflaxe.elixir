defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    first = HashIteratorKey.new(1, 10)
    second = HashIteratorKey.new(2, 20)
    map = HashMap.new(nil)
    map = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, first, "one"])
    map = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, second, "two"])
    iterator = HashMapKeyValueIterator.new(map)
    seen = Array.new()
    {seen} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {seen}, fn _, {acc_seen} ->
      try do
        if (apply(Map.get(iterator, :__reflaxe_class__) || Map.get(iterator, :__struct__), :has_next, [iterator])) do
          pair = apply(Map.get(iterator, :__reflaxe_class__) || Map.get(iterator, :__struct__), :next, [iterator])
          acc_seen = acc_seen ++ [(fn ->
            reflaxe_dispatch_receiver = pair.key
            apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
          end).() <> "=" <> pair.value]
          {:cont, {acc_seen}}
        else
          {:halt, {acc_seen}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_seen}}
        :throw, :continue ->
          {:cont, {acc_seen}}
      end
    end)
    seen = Enum.sort(seen, fn a, b -> &Reflect.compare/2.(a, b) < 0 end)
    assert_that(Enum.join(seen, ",") == "key:1=one,key:2=two", "explicit HashMapKeyValueIterator should preserve key/value pairs")
  end
end
