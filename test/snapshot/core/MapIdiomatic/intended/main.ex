defmodule Main do
  def main() do
    test_map_construction()
    test_basic_map_operations()
    test_map_queries()
    test_map_transformations()
    test_map_utilities()
    Log.trace("Map idiomatic transformation tests complete", %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "main"})
  end
  defp test_map_construction() do
    Log.trace("=== Map Construction ===", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testMapConstruction"})
    empty_map = %{}
    Log.trace("Empty map: #{if empty_map == nil, do: "null", else: empty_map.toString()}", %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "testMapConstruction"})
    initial_data = %{"key1" => 1, "key2" => 2}
    Log.trace("Map construction tests complete", %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "testMapConstruction"})
  end
  defp test_basic_map_operations() do
    Log.trace("=== Basic Map Operations ===", %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "testBasicMapOperations"})
    map = %{}
    map.set("name", "Alice")
    map.set("city", "Portland")
    map.set("job", "Developer")
    name = map.get("name")
    city = map.get("city")
    missing = map.get("missing")
    Log.trace("Name: #{name}", %{:file_name => "Main.hx", :line_number => 62, :class_name => "Main", :method_name => "testBasicMapOperations"})
    Log.trace("City: #{city}", %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "testBasicMapOperations"})
    Log.trace("Missing: #{missing}", %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "testBasicMapOperations"})
    has_name = map.exists("name")
    has_missing = map.exists("missing")
    Log.trace("Has name: #{inspect(has_name)}", %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "testBasicMapOperations"})
    Log.trace("Has missing: #{inspect(has_missing)}", %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "testBasicMapOperations"})
    map.remove("job")
    job_after_remove = map.get("job")
    Log.trace("Job after remove: #{job_after_remove}", %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "testBasicMapOperations"})
    map.clear()
    value_after_clear = map.get("name")
    Log.trace("Value after clear: #{value_after_clear}", %{:file_name => "Main.hx", :line_number => 83, :class_name => "Main", :method_name => "testBasicMapOperations"})
  end
  defp test_map_queries() do
    Log.trace("=== Map Query Operations ===", %{:file_name => "Main.hx", :line_number => 91, :class_name => "Main", :method_name => "testMapQueries"})
    map = %{}
    map.set("a", 1)
    map.set("b", 2)
    map.set("c", 3)
    keys = map.keys()
    Log.trace("Keys: #{inspect(keys)}", %{:file_name => "Main.hx", :line_number => 100, :class_name => "Main", :method_name => "testMapQueries"})
    values = map.iterator()
    Log.trace("Values iterator: #{inspect(values)}", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "testMapQueries"})
    has_keys = false
    key = map.keys()
    Enum.each(has_keys, fn {name, hex} ->
  has_keys = true
  throw(:break)
end)
    Log.trace("Map has keys: #{inspect(has_keys)}", %{:file_name => "Main.hx", :line_number => 113, :class_name => "Main", :method_name => "testMapQueries"})
    empty_map = %{}
    empty_has_keys = false
    key = empty_map.keys()
    Enum.each(empty_has_keys, fn {name, hex} ->
  empty_has_keys = true
  throw(:break)
end)
    Log.trace("Empty map has keys: #{inspect(empty_has_keys)}", %{:file_name => "Main.hx", :line_number => 121, :class_name => "Main", :method_name => "testMapQueries"})
  end
  defp test_map_transformations() do
    Log.trace("=== Map Transformations ===", %{:file_name => "Main.hx", :line_number => 129, :class_name => "Main", :method_name => "testMapTransformations"})
    numbers = %{}
    numbers.set("one", 1)
    numbers.set("two", 2)
    numbers.set("three", 3)
    Log.trace("Iterating over map:", %{:file_name => "Main.hx", :line_number => 137, :class_name => "Main", :method_name => "testMapTransformations"})
    key = numbers.keys()
    Enum.each(key, fn {name, hex} ->
  value = numbers.get(key2)
  Log.trace("  " <> key2 <> " => " <> value.to_string(), %{:file_name => "Main.hx", :line_number => 140, :class_name => "Main", :method_name => "testMapTransformations"})
end)
    copied = numbers.copy()
    copied_value = copied.get("one")
    Log.trace("Copied map value for \"one\": #{copied_value}", %{:file_name => "Main.hx", :line_number => 148, :class_name => "Main", :method_name => "testMapTransformations"})
    int_map = %{}
    int_map.set(1, "first")
    int_map.set(2, "second")
    Log.trace("Int-keyed map:", %{:file_name => "Main.hx", :line_number => 155, :class_name => "Main", :method_name => "testMapTransformations"})
    key = int_map.keys()
    Enum.each(key, fn {name, hex} ->
  value = int_map.get(key2)
  Log.trace("  " <> key2.to_string() <> " => " <> value.to_string(), %{:file_name => "Main.hx", :line_number => 158, :class_name => "Main", :method_name => "testMapTransformations"})
end)
  end
  defp test_map_utilities() do
    Log.trace("=== Map Utilities ===", %{:file_name => "Main.hx", :line_number => 166, :class_name => "Main", :method_name => "testMapUtilities"})
    map = %{}
    map.set("string", "hello")
    map.set("number", 42)
    map.set("boolean", true)
    string_repr = StringBuf.to_string(map)
    Log.trace("String representation: #{string_repr}", %{:file_name => "Main.hx", :line_number => 175, :class_name => "Main", :method_name => "testMapUtilities"})
    string_val = map.get("string")
    number_val = map.get("number")
    bool_val = map.get("boolean")
    Log.trace("String value: #{inspect(string_val)}", %{:file_name => "Main.hx", :line_number => 182, :class_name => "Main", :method_name => "testMapUtilities"})
    Log.trace("Number value: #{inspect(number_val)}", %{:file_name => "Main.hx", :line_number => 183, :class_name => "Main", :method_name => "testMapUtilities"})
    Log.trace("Boolean value: #{inspect(bool_val)}", %{:file_name => "Main.hx", :line_number => 184, :class_name => "Main", :method_name => "testMapUtilities"})
  end
  defp test_edge_cases() do
    Log.trace("=== Edge Cases ===", %{:file_name => "Main.hx", :line_number => 191, :class_name => "Main", :method_name => "testEdgeCases"})
    map = %{}
    map.set("", "empty string key")
    empty_key_value = map.get("")
    Log.trace("Empty string key value: #{empty_key_value}", %{:file_name => "Main.hx", :line_number => 197, :class_name => "Main", :method_name => "testEdgeCases"})
    map.set("key", "first")
    map.set("key", "second")
    overwritten = map.get("key")
    Log.trace("Overwritten value: #{overwritten}", %{:file_name => "Main.hx", :line_number => 203, :class_name => "Main", :method_name => "testEdgeCases"})
    result = %{}
    result.set("a", 1)
    result.set("b", 2)
    final_a = result.get("a")
    final_b = result.get("b")
    Log.trace("Final values after chaining: a=#{final_a}, b=#{final_b}", %{:file_name => "Main.hx", :line_number => 213, :class_name => "Main", :method_name => "testEdgeCases"})
  end
end