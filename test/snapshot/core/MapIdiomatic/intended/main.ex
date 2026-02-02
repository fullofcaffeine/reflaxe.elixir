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
    map = map |> Map.put("name", "Alice") |> Map.put("city", "Portland") |> Map.put("job", "Developer")
    _name = Map.get(map, "name")
    _city = Map.get(map, "city")
    _missing = Map.get(map, "missing")
    _has_name = Map.has_key?(map, "name")
    _has_missing = Map.has_key?(map, "missing")
    _map_had_key_map = Map.has_key?(map, "job")
    map = Map.delete(map, "job")
    _job_after_remove = Map.get(map, "job")
    map = %{}
    _value_after_clear = Map.get(map, "name")
    nil
  end
  defp test_map_queries() do
    map = %{}
    map = map |> Map.put("a", 1) |> Map.put("b", 2) |> Map.put("c", 3)
    _keys = Map.keys(map)
    _values = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :iterator, [map])
    has_keys = false
    {has_keys} = Enum.reduce_while(Map.keys(map), {has_keys}, fn _key, {acc_has_keys} ->
      try do
        acc_has_keys = true
        throw({:break, {acc_has_keys}})
        {:cont, {acc_has_keys}}
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
    {empty_has_keys} = Enum.reduce_while(Map.keys(empty_map), {empty_has_keys}, fn _key, {acc_empty_has_keys} ->
      try do
        acc_empty_has_keys = true
        throw({:break, {acc_empty_has_keys}})
        {:cont, {acc_empty_has_keys}}
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
    numbers = numbers |> Map.put("one", 1) |> Map.put("two", 2) |> Map.put("three", 3)
    _ = Enum.reduce_while(Map.keys(numbers), :ok, fn key, acc ->
  try do
    _value = Map.get(numbers, key)
    {:cont, acc}
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
    copied = numbers
    _copied_value = Map.get(copied, "one")
    int_map = %{}
    int_map = int_map |> Map.put(1, "first") |> Map.put(2, "second")
    _ = Enum.reduce_while(Map.keys(int_map), :ok, fn key, acc ->
  try do
    _value = Map.get(int_map, key)
    {:cont, acc}
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
    map = map |> Map.put("string", "hello") |> Map.put("number", 42) |> Map.put("boolean", true)
    _string_repr = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :to_string, [map])
    _string_val = Map.get(map, "string")
    _number_val = Map.get(map, "number")
    _bool_val = Map.get(map, "boolean")
    nil
  end
end
