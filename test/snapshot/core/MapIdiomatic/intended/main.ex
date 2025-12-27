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
    empty_map = %{}
    initial_data = %{"key1" => 1, "key2" => 2}
    nil
  end
  defp test_basic_map_operations() do
    map = %{}
    _ = StringMap.set(map, "name", "Alice")
    _ = StringMap.set(map, "city", "Portland")
    _ = StringMap.set(map, "job", "Developer")
    name = StringMap.get(map, "name")
    city = StringMap.get(map, "city")
    missing = StringMap.get(map, "missing")
    has_name = StringMap.exists(map, "name")
    has_missing = StringMap.exists(map, "missing")
    _ = StringMap.remove(map, "job")
    job_after_remove = StringMap.get(map, "job")
    _ = StringMap.clear(map)
    value_after_clear = StringMap.get(map, "name")
    nil
  end
  defp test_map_queries() do
    map = %{}
    _ = StringMap.set(map, "a", 1)
    _ = StringMap.set(map, "b", 2)
    _ = StringMap.set(map, "c", 3)
    keys = StringMap.keys(map)
    values = StringMap.iterator(map)
    has_keys = false
    key = StringMap.keys(map)
    Enum.each(has_keys, fn _ ->
      has_keys = true
      throw(:break)
    end)
    nil
    empty_map = %{}
    empty_has_keys = false
    key = StringMap.keys(empty_map)
    Enum.each(empty_has_keys, fn _ ->
      empty_has_keys = true
      throw(:break)
    end)
    nil
    nil
  end
  defp test_map_transformations() do
    numbers = %{}
    _ = StringMap.set(numbers, "one", 1)
    _ = StringMap.set(numbers, "two", 2)
    _ = StringMap.set(numbers, "three", 3)
    key = StringMap.keys(numbers)
    _ = Enum.each(colors, fn _ ->
  value = StringMap.get(numbers, key)
  nil
end)
    copied = StringMap.copy(numbers)
    copied_value = StringMap.get(copied, "one")
    int_map = %{}
    _ = int_map.set(int_map, 1, "first")
    _ = int_map.set(int_map, 2, "second")
    key = int_map.keys(int_map)
    _ = Enum.each(colors, fn _ ->
  value = int_map.get(int_map, key)
  nil
end)
  end
  defp test_map_utilities() do
    map = %{}
    _ = StringMap.set(map, "string", "hello")
    _ = StringMap.set(map, "number", 42)
    _ = StringMap.set(map, "boolean", true)
    string_repr = StringMap.to_string(map)
    string_val = StringMap.get(map, "string")
    number_val = StringMap.get(map, "number")
    bool_val = StringMap.get(map, "boolean")
    nil
  end
end
