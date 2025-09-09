defmodule Main do
  def main() do
    test_map_construction()
    test_basic_map_operations()
    test_map_queries()
    test_map_transformations()
    test_map_utilities()
    Log.trace("Map idiomatic transformation tests complete", %{:file_name => "Main.hx", :line_number => 20, :class_name => "Main", :method_name => "main"})
  end
  defp test_map_construction() do
    Log.trace("=== Map Construction ===", %{:file_name => "Main.hx", :line_number => 29, :class_name => "Main", :method_name => "testMapConstruction"})
    empty_map = %{}
    Log.trace("Empty map: " <> (if (empty_map == nil), do: "null", else: empty_map.to_string()), %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testMapConstruction"})
    g = %{}
    g = Map.put(g, "key1", 1)
    g = Map.put(g, "key2", 2)
    _initial_data = g
    Log.trace("Map construction tests complete", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "testMapConstruction"})
  end
  defp test_basic_map_operations() do
    Log.trace("=== Basic Map Operations ===", %{:file_name => "Main.hx", :line_number => 47, :class_name => "Main", :method_name => "testBasicMapOperations"})
    map = %{}
    map = Map.put(map, "name", "Alice")
    map = Map.put(map, "city", "Portland")
    map = Map.put(map, "job", "Developer")
    name = Map.get(map, "name")
    city = Map.get(map, "city")
    missing = Map.get(map, "missing")
    Log.trace("Name: " <> Kernel.to_string(name), %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "testBasicMapOperations"})
    Log.trace("City: " <> Kernel.to_string(city), %{:file_name => "Main.hx", :line_number => 62, :class_name => "Main", :method_name => "testBasicMapOperations"})
    Log.trace("Missing: " <> Kernel.to_string(missing), %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "testBasicMapOperations"})
    has_name = Map.has_key?(map, "name")
    has_missing = Map.has_key?(map, "missing")
    Log.trace("Has name: " <> Std.string(has_name), %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "testBasicMapOperations"})
    Log.trace("Has missing: " <> Std.string(has_missing), %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "testBasicMapOperations"})
    map = Map.delete(map, "job")
    job_after_remove = Map.get(map, "job")
    Log.trace("Job after remove: " <> Kernel.to_string(job_after_remove), %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "testBasicMapOperations"})
    map.clear()
    value_after_clear = Map.get(map, "name")
    Log.trace("Value after clear: " <> Kernel.to_string(value_after_clear), %{:file_name => "Main.hx", :line_number => 82, :class_name => "Main", :method_name => "testBasicMapOperations"})
  end
  defp test_map_queries() do
    Log.trace("=== Map Query Operations ===", %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "testMapQueries"})
    map = %{}
    map = Map.put(map, "a", 1)
    map = Map.put(map, "b", 2)
    map = Map.put(map, "c", 3)
    keys = Map.keys(map)
    Log.trace("Keys: " <> Std.string(keys), %{:file_name => "Main.hx", :line_number => 99, :class_name => "Main", :method_name => "testMapQueries"})
    values = map.iterator()
    Log.trace("Values iterator: " <> Std.string(values), %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testMapQueries"})
    has_keys = false
    key = Map.keys(map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {has_keys, key, :ok}, fn _, {acc_has_keys, acc_key, acc_state} -> nil end)
    Log.trace("Map has keys: " <> Std.string(has_keys), %{:file_name => "Main.hx", :line_number => 112, :class_name => "Main", :method_name => "testMapQueries"})
    empty_map = %{}
    empty_has_keys = false
    key = Map.keys(empty_map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {empty_has_keys, key, :ok}, fn _, {acc_empty_has_keys, acc_key, acc_state} -> nil end)
    Log.trace("Empty map has keys: " <> Std.string(empty_has_keys), %{:file_name => "Main.hx", :line_number => 120, :class_name => "Main", :method_name => "testMapQueries"})
  end
  defp test_map_transformations() do
    Log.trace("=== Map Transformations ===", %{:file_name => "Main.hx", :line_number => 128, :class_name => "Main", :method_name => "testMapTransformations"})
    numbers = %{}
    numbers = Map.put(numbers, "one", 1)
    numbers = Map.put(numbers, "two", 2)
    numbers = Map.put(numbers, "three", 3)
    Log.trace("Iterating over map:", %{:file_name => "Main.hx", :line_number => 136, :class_name => "Main", :method_name => "testMapTransformations"})
    key = Map.keys(numbers)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
    copied = numbers.copy()
    copied_value = Map.get(copied, "one")
    Log.trace("Copied map value for \"one\": " <> Kernel.to_string(copied_value), %{:file_name => "Main.hx", :line_number => 147, :class_name => "Main", :method_name => "testMapTransformations"})
    int_map = %{}
    int_map = Map.put(int_map, 1, "first")
    int_map = Map.put(int_map, 2, "second")
    Log.trace("Int-keyed map:", %{:file_name => "Main.hx", :line_number => 154, :class_name => "Main", :method_name => "testMapTransformations"})
    key = Map.keys(int_map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
  end
  defp test_map_utilities() do
    Log.trace("=== Map Utilities ===", %{:file_name => "Main.hx", :line_number => 165, :class_name => "Main", :method_name => "testMapUtilities"})
    map = %{}
    map = Map.put(map, "string", "hello")
    map = Map.put(map, "number", 42)
    map = Map.put(map, "boolean", true)
    string_repr = map.to_string()
    Log.trace("String representation: " <> string_repr, %{:file_name => "Main.hx", :line_number => 174, :class_name => "Main", :method_name => "testMapUtilities"})
    string_val = Map.get(map, "string")
    number_val = Map.get(map, "number")
    bool_val = Map.get(map, "boolean")
    Log.trace("String value: " <> Std.string(string_val), %{:file_name => "Main.hx", :line_number => 181, :class_name => "Main", :method_name => "testMapUtilities"})
    Log.trace("Number value: " <> Std.string(number_val), %{:file_name => "Main.hx", :line_number => 182, :class_name => "Main", :method_name => "testMapUtilities"})
    Log.trace("Boolean value: " <> Std.string(bool_val), %{:file_name => "Main.hx", :line_number => 183, :class_name => "Main", :method_name => "testMapUtilities"})
  end
  defp test_edge_cases() do
    Log.trace("=== Edge Cases ===", %{:file_name => "Main.hx", :line_number => 190, :class_name => "Main", :method_name => "testEdgeCases"})
    map = %{}
    map = Map.put(map, "", "empty string key")
    empty_key_value = Map.get(map, "")
    Log.trace("Empty string key value: " <> Kernel.to_string(empty_key_value), %{:file_name => "Main.hx", :line_number => 196, :class_name => "Main", :method_name => "testEdgeCases"})
    map = Map.put(map, "key", "first")
    map = Map.put(map, "key", "second")
    overwritten = Map.get(map, "key")
    Log.trace("Overwritten value: " <> Kernel.to_string(overwritten), %{:file_name => "Main.hx", :line_number => 202, :class_name => "Main", :method_name => "testEdgeCases"})
    result = %{}
    result = Map.put(result, "a", 1)
    result = Map.put(result, "b", 2)
    final_a = Map.get(result, "a")
    final_b = Map.get(result, "b")
    Log.trace("Final values after chaining: a=" <> Kernel.to_string(final_a) <> ", b=" <> Kernel.to_string(final_b), %{:file_name => "Main.hx", :line_number => 212, :class_name => "Main", :method_name => "testEdgeCases"})
  end
end