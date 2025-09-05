defmodule Main do
  def main() do
    test_map_construction()
    test_basic_map_operations()
    test_map_queries()
    test_map_transformations()
    test_map_utilities()
    Log.trace("Map idiomatic transformation tests complete", %{:fileName => "Main.hx", :lineNumber => 20, :className => "Main", :methodName => "main"})
  end
  defp test_map_construction() do
    Log.trace("=== Map Construction ===", %{:fileName => "Main.hx", :lineNumber => 29, :className => "Main", :methodName => "testMapConstruction"})
    empty_map = %{}
    Log.trace("Empty map: " <> (if (empty_map == nil), do: "null", else: empty_map.toString()), %{:fileName => "Main.hx", :lineNumber => 33, :className => "Main", :methodName => "testMapConstruction"})
    g = %{}
    g = Map.put(g, "key1", 1)
    g = Map.put(g, "key2", 2)
    _initial_data = g
    Log.trace("Map construction tests complete", %{:fileName => "Main.hx", :lineNumber => 39, :className => "Main", :methodName => "testMapConstruction"})
  end
  defp test_basic_map_operations() do
    Log.trace("=== Basic Map Operations ===", %{:fileName => "Main.hx", :lineNumber => 47, :className => "Main", :methodName => "testBasicMapOperations"})
    map = %{}
    map = Map.put(map, "name", "Alice")
    map = Map.put(map, "city", "Portland")
    map = Map.put(map, "job", "Developer")
    name = Map.get(map, "name")
    city = Map.get(map, "city")
    missing = Map.get(map, "missing")
    Log.trace("Name: " <> name, %{:fileName => "Main.hx", :lineNumber => 61, :className => "Main", :methodName => "testBasicMapOperations"})
    Log.trace("City: " <> city, %{:fileName => "Main.hx", :lineNumber => 62, :className => "Main", :methodName => "testBasicMapOperations"})
    Log.trace("Missing: " <> missing, %{:fileName => "Main.hx", :lineNumber => 63, :className => "Main", :methodName => "testBasicMapOperations"})
    has_name = Map.has_key?(map, "name")
    has_missing = Map.has_key?(map, "missing")
    Log.trace("Has name: " <> Std.string(has_name), %{:fileName => "Main.hx", :lineNumber => 69, :className => "Main", :methodName => "testBasicMapOperations"})
    Log.trace("Has missing: " <> Std.string(has_missing), %{:fileName => "Main.hx", :lineNumber => 70, :className => "Main", :methodName => "testBasicMapOperations"})
    map = Map.delete(map, "job")
    job_after_remove = Map.get(map, "job")
    Log.trace("Job after remove: " <> job_after_remove, %{:fileName => "Main.hx", :lineNumber => 75, :className => "Main", :methodName => "testBasicMapOperations"})
    map.clear()
    value_after_clear = Map.get(map, "name")
    Log.trace("Value after clear: " <> value_after_clear, %{:fileName => "Main.hx", :lineNumber => 82, :className => "Main", :methodName => "testBasicMapOperations"})
  end
  defp test_map_queries() do
    Log.trace("=== Map Query Operations ===", %{:fileName => "Main.hx", :lineNumber => 90, :className => "Main", :methodName => "testMapQueries"})
    map = %{}
    map = Map.put(map, "a", 1)
    map = Map.put(map, "b", 2)
    map = Map.put(map, "c", 3)
    keys = Map.keys(map)
    Log.trace("Keys: " <> Std.string(keys), %{:fileName => "Main.hx", :lineNumber => 99, :className => "Main", :methodName => "testMapQueries"})
    values = map.iterator()
    Log.trace("Values iterator: " <> Std.string(values), %{:fileName => "Main.hx", :lineNumber => 103, :className => "Main", :methodName => "testMapQueries"})
    has_keys = false
    key = Map.keys(map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, has_keys, :ok}, fn _, {acc_key, acc_has_keys, acc_state} ->
  if (acc_key.hasNext()) do
    _key = acc_key.next()
    acc_has_keys = true
    throw(:break)
    {:cont, {acc_key, acc_has_keys, acc_state}}
  else
    {:halt, {acc_key, acc_has_keys, acc_state}}
  end
end)
    Log.trace("Map has keys: " <> Std.string(has_keys), %{:fileName => "Main.hx", :lineNumber => 112, :className => "Main", :methodName => "testMapQueries"})
    empty_map = %{}
    empty_has_keys = false
    key = Map.keys(empty_map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {empty_has_keys, key, :ok}, fn _, {acc_empty_has_keys, acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    _key = acc_key.next()
    acc_empty_has_keys = true
    throw(:break)
    {:cont, {acc_empty_has_keys, acc_key, acc_state}}
  else
    {:halt, {acc_empty_has_keys, acc_key, acc_state}}
  end
end)
    Log.trace("Empty map has keys: " <> Std.string(empty_has_keys), %{:fileName => "Main.hx", :lineNumber => 120, :className => "Main", :methodName => "testMapQueries"})
  end
  defp test_map_transformations() do
    Log.trace("=== Map Transformations ===", %{:fileName => "Main.hx", :lineNumber => 128, :className => "Main", :methodName => "testMapTransformations"})
    numbers = %{}
    numbers = Map.put(numbers, "one", 1)
    numbers = Map.put(numbers, "two", 2)
    numbers = Map.put(numbers, "three", 3)
    Log.trace("Iterating over map:", %{:fileName => "Main.hx", :lineNumber => 136, :className => "Main", :methodName => "testMapTransformations"})
    key = Map.keys(numbers)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    value = Map.get(numbers, acc_key)
    Log.trace("  " <> acc_key <> " => " <> value, %{:fileName => "Main.hx", :lineNumber => 139, :className => "Main", :methodName => "testMapTransformations"})
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
    copied = numbers.copy()
    copied_value = Map.get(copied, "one")
    Log.trace("Copied map value for \"one\": " <> copied_value, %{:fileName => "Main.hx", :lineNumber => 147, :className => "Main", :methodName => "testMapTransformations"})
    int_map = %{}
    int_map = Map.put(int_map, 1, "first")
    int_map = Map.put(int_map, 2, "second")
    Log.trace("Int-keyed map:", %{:fileName => "Main.hx", :lineNumber => 154, :className => "Main", :methodName => "testMapTransformations"})
    key = Map.keys(int_map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    value = Map.get(int_map, acc_key)
    Log.trace("  " <> acc_key <> " => " <> value, %{:fileName => "Main.hx", :lineNumber => 157, :className => "Main", :methodName => "testMapTransformations"})
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
  end
  defp test_map_utilities() do
    Log.trace("=== Map Utilities ===", %{:fileName => "Main.hx", :lineNumber => 165, :className => "Main", :methodName => "testMapUtilities"})
    map = %{}
    map = Map.put(map, "string", "hello")
    map = Map.put(map, "number", 42)
    map = Map.put(map, "boolean", true)
    string_repr = map.toString()
    Log.trace("String representation: " <> string_repr, %{:fileName => "Main.hx", :lineNumber => 174, :className => "Main", :methodName => "testMapUtilities"})
    string_val = Map.get(map, "string")
    number_val = Map.get(map, "number")
    bool_val = Map.get(map, "boolean")
    Log.trace("String value: " <> Std.string(string_val), %{:fileName => "Main.hx", :lineNumber => 181, :className => "Main", :methodName => "testMapUtilities"})
    Log.trace("Number value: " <> Std.string(number_val), %{:fileName => "Main.hx", :lineNumber => 182, :className => "Main", :methodName => "testMapUtilities"})
    Log.trace("Boolean value: " <> Std.string(bool_val), %{:fileName => "Main.hx", :lineNumber => 183, :className => "Main", :methodName => "testMapUtilities"})
  end
  defp test_edge_cases() do
    Log.trace("=== Edge Cases ===", %{:fileName => "Main.hx", :lineNumber => 190, :className => "Main", :methodName => "testEdgeCases"})
    map = %{}
    map = Map.put(map, "", "empty string key")
    empty_key_value = Map.get(map, "")
    Log.trace("Empty string key value: " <> empty_key_value, %{:fileName => "Main.hx", :lineNumber => 196, :className => "Main", :methodName => "testEdgeCases"})
    map = Map.put(map, "key", "first")
    map = Map.put(map, "key", "second")
    overwritten = Map.get(map, "key")
    Log.trace("Overwritten value: " <> overwritten, %{:fileName => "Main.hx", :lineNumber => 202, :className => "Main", :methodName => "testEdgeCases"})
    result = %{}
    result = Map.put(result, "a", 1)
    result = Map.put(result, "b", 2)
    final_a = Map.get(result, "a")
    final_b = Map.get(result, "b")
    Log.trace("Final values after chaining: a=" <> final_a <> ", b=" <> final_b, %{:fileName => "Main.hx", :lineNumber => 212, :className => "Main", :methodName => "testEdgeCases"})
  end
end