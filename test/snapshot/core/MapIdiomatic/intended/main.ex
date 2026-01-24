defmodule Main do
  def main() do
    _ = test_map_construction()
    _ = test_basic_map_operations()
    _ = test_map_queries()
    _ = test_map_transformations()
    _ = test_map_utilities()
    nil
  end
  defp test_map_construction() do
    nil
  end
  defp test_basic_map_operations() do
    map = %{}
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, "name", "Alice"])
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, "city", "Portland"])
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, "job", "Developer"])
    _name = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :get, [map, "name"])
    _city = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :get, [map, "city"])
    _missing = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :get, [map, "missing"])
    _has_name = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :exists, [map, "name"])
    _has_missing = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :exists, [map, "missing"])
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :remove, [map, "job"])
    _job_after_remove = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :get, [map, "job"])
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :clear, [map])
    _value_after_clear = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :get, [map, "name"])
    nil
  end
  defp test_map_queries() do
    map = %{}
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, "a", 1])
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, "b", 2])
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, "c", 3])
    _keys = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :keys, [map])
    _values = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :iterator, [map])
    has_keys = false
    key = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :keys, [map])
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {has_keys}, fn _, {acc_has_keys} ->
      try do
        if (key.has_next.()) do
          _ = key.next.()
          acc_has_keys = true
          throw({:break, {acc_has_keys}})
          {:cont, {acc_has_keys}}
        else
          {:halt, {acc_has_keys}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_has_keys}}
        :throw, :continue ->
          {:cont, {acc_has_keys}}
      end
    end)
    empty_map = %{}
    empty_has_keys = false
    key = apply(Map.get(empty_map, :__reflaxe_class__) || Map.get(empty_map, :__struct__), :keys, [empty_map])
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {empty_has_keys}, fn _, {acc_empty_has_keys} ->
      try do
        if (key.has_next.()) do
          _ = key.next.()
          acc_empty_has_keys = true
          throw({:break, {acc_empty_has_keys}})
          {:cont, {acc_empty_has_keys}}
        else
          {:halt, {acc_empty_has_keys}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_empty_has_keys}}
        :throw, :continue ->
          {:cont, {acc_empty_has_keys}}
      end
    end)
    nil
  end
  defp test_map_transformations() do
    numbers = %{}
    _ = apply(Map.get(numbers, :__reflaxe_class__) || Map.get(numbers, :__struct__), :set, [numbers, "one", 1])
    _ = apply(Map.get(numbers, :__reflaxe_class__) || Map.get(numbers, :__struct__), :set, [numbers, "two", 2])
    _ = apply(Map.get(numbers, :__reflaxe_class__) || Map.get(numbers, :__struct__), :set, [numbers, "three", 3])
    key = apply(Map.get(numbers, :__reflaxe_class__) || Map.get(numbers, :__struct__), :keys, [numbers])
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  try do
    if (key.has_next.()) do
      key = key.next.()
      _value = apply(Map.get(numbers, :__reflaxe_class__) || Map.get(numbers, :__struct__), :get, [numbers, key])
      nil
      {:cont, acc}
    else
      {:halt, acc}
    end
  catch
    :throw, {:break, break_state} ->
      {:halt, break_state}
    :throw, {:continue, continue_state} ->
      {:cont, continue_state}
    :throw, :break ->
      {:halt, acc}
    :throw, :continue ->
      {:cont, acc}
  end
end)
    copied = apply(Map.get(numbers, :__reflaxe_class__) || Map.get(numbers, :__struct__), :copy, [numbers])
    _copied_value = apply(Map.get(copied, :__reflaxe_class__) || Map.get(copied, :__struct__), :get, [copied, "one"])
    int_map = %{}
    _ = apply(Map.get(int_map, :__reflaxe_class__) || Map.get(int_map, :__struct__), :set, [int_map, 1, "first"])
    _ = apply(Map.get(int_map, :__reflaxe_class__) || Map.get(int_map, :__struct__), :set, [int_map, 2, "second"])
    key = apply(Map.get(int_map, :__reflaxe_class__) || Map.get(int_map, :__struct__), :keys, [int_map])
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  try do
    if (key.has_next.()) do
      key = key.next.()
      _value = apply(Map.get(int_map, :__reflaxe_class__) || Map.get(int_map, :__struct__), :get, [int_map, key])
      nil
      {:cont, acc}
    else
      {:halt, acc}
    end
  catch
    :throw, {:break, break_state} ->
      {:halt, break_state}
    :throw, {:continue, continue_state} ->
      {:cont, continue_state}
    :throw, :break ->
      {:halt, acc}
    :throw, :continue ->
      {:cont, acc}
  end
end)
  end
  defp test_map_utilities() do
    map = %{}
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, "string", "hello"])
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, "number", 42])
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, "boolean", true])
    _string_repr = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :to_string, [map])
    _string_val = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :get, [map, "string"])
    _number_val = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :get, [map, "number"])
    _bool_val = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :get, [map, "boolean"])
    nil
  end
end
