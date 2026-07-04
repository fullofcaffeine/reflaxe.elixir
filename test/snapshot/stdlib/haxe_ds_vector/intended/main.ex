defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    values = Vector_Impl_._new(4, 0)
    _ = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :set, [values, 0, 99])
    _ = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :set, [values, 1, 101])
    _ = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :set, [values, 2, -12])
    _ = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :set, [values, 3, 0])
    comparator = fn left, right -> Reflect.compare(left, right) < 0 end
    _ = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :put_items, [values, Enum.sort(apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :items, [values]), comparator)])
    _ = assert_that(Vector_Impl_.join(values, ",") == "-12,0,99,101", "sort should use numeric Reflect.compare ordering")
    copied = Vector_Impl_.copy(values)
    _ = apply(Map.get(values, :__reflaxe_class__) || Map.get(values, :__struct__), :set, [values, 0, 7])
    _ = assert_that(apply(Map.get(copied, :__reflaxe_class__) || Map.get(copied, :__struct__), :get, [copied, 0]) == -12, "copy should preserve the old backing snapshot")
    mapped = Vector_Impl_.map(values, fn value -> "v:" <> Reflaxe.Elixir.HaxeFloat.to_string(value) end)
    _ = assert_that(Vector_Impl_.join(mapped, "|") == "v:7|v:0|v:99|v:101", "map should return a new vector")
    dest = Vector_Impl_._new(5, -1)
    _ = Vector_Impl_.blit(values, 0, dest, 1, 3)
    _ = assert_that(Vector_Impl_.join(dest, ",") == "-1,7,0,99,-1", "blit should copy from the source snapshot")
    arr = Vector_Impl_.to_array(dest)
    _ = apply(Map.get(dest, :__reflaxe_class__) || Map.get(dest, :__struct__), :set, [dest, 1, 8])
    _ = assert_that(Enum.at(arr, 1) == 7, "toArray should preserve a snapshot")
    alias = dest
    _ = apply(Map.get(alias, :__reflaxe_class__) || Map.get(alias, :__struct__), :set, [alias, 2, 42])
    _ = assert_that(apply(Map.get(dest, :__reflaxe_class__) || Map.get(dest, :__struct__), :get, [dest, 2]) == 42, "fromData should share backing state")
    sum = 0
    value = Vector_Impl_.iterator(dest)
    {sum} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum}, fn _, {acc_sum} ->
      try do
        if (apply(Map.get(value, :__reflaxe_class__) || Map.get(value, :__struct__), :has_next, [value])) do
          value = apply(Map.get(value, :__reflaxe_class__) || Map.get(value, :__struct__), :next, [value])
          acc_sum = acc_sum + value
          {:cont, {acc_sum}}
        else
          {:halt, {acc_sum}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_sum}}
        :throw, :continue ->
          {:cont, {acc_sum}}
      end
    end)
    _ = assert_that(sum == 147, "iterator should read the current backing state")
  end
end
