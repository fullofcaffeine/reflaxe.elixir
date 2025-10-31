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
    Log.trace("Empty map: #{(fn -> if (empty_map == nil), do: "null", else: empty_map.toString() end).()}", %{:file_name => "Main.hx", :line_number => 34, :class_name => "Main", :method_name => "testMapConstruction"})
    _ = %{"key1" => 1, "key2" => 2}
    Log.trace("Map construction tests complete", %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "testMapConstruction"})
  end
  defp test_basic_map_operations() do
    Log.trace("=== Basic Map Operations ===", %{:file_name => "Main.hx", :line_number => 48, :class_name => "Main", :method_name => "testBasicMapOperations"})
    map = %{}
    map = Map.put(map, :name, "Alice")
    map = Map.put(map, :city, "Portland")
    map = Map.put(map, :job, "Developer")
    name = map.get("name")
    city = map.get("city")
    missing = map.get("missing")
    Log.trace("Name: #{(fn -> name end).()}", %{:file_name => "Main.hx", :line_number => 62, :class_name => "Main", :method_name => "testBasicMapOperations"})
    Log.trace("City: #{(fn -> city end).()}", %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "testBasicMapOperations"})
    Log.trace("Missing: #{(fn -> missing end).()}", %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "testBasicMapOperations"})
    has_name = map.exists("name")
    has_missing = map.exists("missing")
    Log.trace("Has name: #{(fn -> inspect(has_name) end).()}", %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "testBasicMapOperations"})
    Log.trace("Has missing: #{(fn -> inspect(has_missing) end).()}", %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "testBasicMapOperations"})
    map.remove("job")
    job_after_remove = map.get("job")
    Log.trace("Job after remove: #{(fn -> job_after_remove end).()}", %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "testBasicMapOperations"})
    map.clear()
    value_after_clear = map.get("name")
    Log.trace("Value after clear: #{(fn -> value_after_clear end).()}", %{:file_name => "Main.hx", :line_number => 83, :class_name => "Main", :method_name => "testBasicMapOperations"})
  end
  defp test_map_queries() do
    Log.trace("=== Map Query Operations ===", %{:file_name => "Main.hx", :line_number => 91, :class_name => "Main", :method_name => "testMapQueries"})
    map = %{}
    map = Map.put(map, :a, 1)
    map = Map.put(map, :b, 2)
    map = Map.put(map, :c, 3)
    keys = map.keys()
    Log.trace("Keys: #{(fn -> inspect(keys) end).()}", %{:file_name => "Main.hx", :line_number => 100, :class_name => "Main", :method_name => "testMapQueries"})
    values = map.iterator()
    Log.trace("Values iterator: #{(fn -> inspect(values) end).()}", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "testMapQueries"})
    has_keys = false
    _ = map.keys()
    Enum.each(has_keys, fn _ ->
      has_keys = true
      throw(:break)
    end)
    Log.trace("Map has keys: #{(fn -> inspect(has_keys) end).()}", %{:file_name => "Main.hx", :line_number => 113, :class_name => "Main", :method_name => "testMapQueries"})
    empty_map = %{}
    empty_has_keys = false
    _ = empty_map.keys()
    Enum.each(empty_has_keys, fn _ ->
      empty_has_keys = true
      throw(:break)
    end)
    Log.trace("Empty map has keys: #{(fn -> inspect(empty_has_keys) end).()}", %{:file_name => "Main.hx", :line_number => 121, :class_name => "Main", :method_name => "testMapQueries"})
  end
  defp test_map_transformations() do
    Log.trace("=== Map Transformations ===", %{:file_name => "Main.hx", :line_number => 129, :class_name => "Main", :method_name => "testMapTransformations"})
    numbers = %{}
    numbers = Map.put(numbers, :one, 1)
    numbers = Map.put(numbers, :two, 2)
    numbers = Map.put(numbers, :three, 3)
    Log.trace("Iterating over map:", %{:file_name => "Main.hx", :line_number => 137, :class_name => "Main", :method_name => "testMapTransformations"})
    key = numbers.keys()
    Enum.each(key, fn item ->
      value = item.get(item)
      Log.trace("  " <> item <> " => " <> value.to_string(), %{:file_name => "Main.hx", :line_number => 140, :class_name => "Main", :method_name => "testMapTransformations"})
    end)
    copied = numbers.copy()
    copied_value = copied.get("one")
    Log.trace("Copied map value for \"one\": #{(fn -> copied_value end).()}", %{:file_name => "Main.hx", :line_number => 148, :class_name => "Main", :method_name => "testMapTransformations"})
    int_map = %{}
    int_map = Map.put(int_map, 1, "first")
    int_map = Map.put(int_map, 2, "second")
    Log.trace("Int-keyed map:", %{:file_name => "Main.hx", :line_number => 155, :class_name => "Main", :method_name => "testMapTransformations"})
    key = int_map.keys()
    Enum.each(key, fn item ->
      value = int_map.get(item)
      Log.trace("  " <> key2.to_string() <> " => " <> value.to_string(), %{:file_name => "Main.hx", :line_number => 158, :class_name => "Main", :method_name => "testMapTransformations"})
    end)
  end
  defp test_map_utilities() do
    Log.trace("=== Map Utilities ===", %{:file_name => "Main.hx", :line_number => 166, :class_name => "Main", :method_name => "testMapUtilities"})
    map = %{}
    map = Map.put(map, :string, "hello")
    map = Map.put(map, :number, 42)
    map = Map.put(map, :boolean, true)
    string_repr = MyApp.StringBuf.to_string(map)
    Log.trace("String representation: #{(fn -> string_repr end).()}", %{:file_name => "Main.hx", :line_number => 175, :class_name => "Main", :method_name => "testMapUtilities"})
    string_val = map.get("string")
    number_val = map.get("number")
    bool_val = map.get("boolean")
    Log.trace("String value: #{(fn -> inspect(string_val) end).()}", %{:file_name => "Main.hx", :line_number => 182, :class_name => "Main", :method_name => "testMapUtilities"})
    Log.trace("Number value: #{(fn -> inspect(number_val) end).()}", %{:file_name => "Main.hx", :line_number => 183, :class_name => "Main", :method_name => "testMapUtilities"})
    Log.trace("Boolean value: #{(fn -> inspect(bool_val) end).()}", %{:file_name => "Main.hx", :line_number => 184, :class_name => "Main", :method_name => "testMapUtilities"})
  end
end
