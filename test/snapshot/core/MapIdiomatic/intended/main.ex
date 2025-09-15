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
    Log.trace("Empty map: #{inspect(empty_map)}", %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testMapConstruction"})

    initial_data = %{
      "key1" => 1,
      "key2" => 2
    }

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

    Log.trace("Name: #{name}", %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "testBasicMapOperations"})
    Log.trace("City: #{city}", %{:file_name => "Main.hx", :line_number => 62, :class_name => "Main", :method_name => "testBasicMapOperations"})
    Log.trace("Missing: #{inspect(missing)}", %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "testBasicMapOperations"})

    has_name = Map.has_key?(map, "name")
    has_missing = Map.has_key?(map, "missing")

    Log.trace("Has name: #{has_name}", %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "testBasicMapOperations"})
    Log.trace("Has missing: #{has_missing}", %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "testBasicMapOperations"})

    map = Map.delete(map, "job")
    job_after_remove = Map.get(map, "job")
    Log.trace("Job after remove: #{inspect(job_after_remove)}", %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "testBasicMapOperations"})

    # Clear map by reassigning to empty
    map = %{}
    value_after_clear = Map.get(map, "name")
    Log.trace("Value after clear: #{inspect(value_after_clear)}", %{:file_name => "Main.hx", :line_number => 82, :class_name => "Main", :method_name => "testBasicMapOperations"})
  end

  defp test_map_queries() do
    Log.trace("=== Map Query Operations ===", %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "testMapQueries"})

    map = %{
      "a" => 1,
      "b" => 2,
      "c" => 3
    }

    keys = Map.keys(map)
    Log.trace("Keys: #{inspect(keys)}", %{:file_name => "Main.hx", :line_number => 99, :class_name => "Main", :method_name => "testMapQueries"})

    values = Map.values(map)
    Log.trace("Values: #{inspect(values)}", %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testMapQueries"})

    # Check if map has keys
    has_keys = map_size(map) > 0
    Log.trace("Map has keys: #{has_keys}", %{:file_name => "Main.hx", :line_number => 112, :class_name => "Main", :method_name => "testMapQueries"})

    empty_map = %{}
    empty_has_keys = map_size(empty_map) > 0
    Log.trace("Empty map has keys: #{empty_has_keys}", %{:file_name => "Main.hx", :line_number => 120, :class_name => "Main", :method_name => "testMapQueries"})
  end

  defp test_map_transformations() do
    Log.trace("=== Map Transformations ===", %{:file_name => "Main.hx", :line_number => 128, :class_name => "Main", :method_name => "testMapTransformations"})

    numbers = %{
      "one" => 1,
      "two" => 2,
      "three" => 3
    }

    Log.trace("Iterating over map:", %{:file_name => "Main.hx", :line_number => 136, :class_name => "Main", :method_name => "testMapTransformations"})

    # Iterate over map entries
    Enum.each(numbers, fn {key, value} ->
      Log.trace("  #{key}: #{value}", %{:file_name => "Main.hx", :line_number => 140, :class_name => "Main", :method_name => "testMapTransformations"})
    end)

    # Copy map (maps are immutable, so just assign)
    copied = numbers
    copied_value = Map.get(copied, "one")
    Log.trace("Copied map value for \"one\": #{copied_value}", %{:file_name => "Main.hx", :line_number => 147, :class_name => "Main", :method_name => "testMapTransformations"})

    int_map = %{
      1 => "first",
      2 => "second"
    }

    Log.trace("Int-keyed map:", %{:file_name => "Main.hx", :line_number => 154, :class_name => "Main", :method_name => "testMapTransformations"})

    Enum.each(int_map, fn {key, value} ->
      Log.trace("  #{key}: #{value}", %{:file_name => "Main.hx", :line_number => 158, :class_name => "Main", :method_name => "testMapTransformations"})
    end)
  end

  defp test_map_utilities() do
    Log.trace("=== Map Utilities ===", %{:file_name => "Main.hx", :line_number => 165, :class_name => "Main", :method_name => "testMapUtilities"})

    map = %{
      "string" => "hello",
      "number" => 42,
      "boolean" => true
    }

    string_repr = inspect(map)
    Log.trace("String representation: #{string_repr}", %{:file_name => "Main.hx", :line_number => 174, :class_name => "Main", :method_name => "testMapUtilities"})

    string_val = Map.get(map, "string")
    number_val = Map.get(map, "number")
    bool_val = Map.get(map, "boolean")

    Log.trace("String value: #{string_val}", %{:file_name => "Main.hx", :line_number => 181, :class_name => "Main", :method_name => "testMapUtilities"})
    Log.trace("Number value: #{number_val}", %{:file_name => "Main.hx", :line_number => 182, :class_name => "Main", :method_name => "testMapUtilities"})
    Log.trace("Boolean value: #{bool_val}", %{:file_name => "Main.hx", :line_number => 183, :class_name => "Main", :method_name => "testMapUtilities"})
  end

  defp test_edge_cases() do
    Log.trace("=== Edge Cases ===", %{:file_name => "Main.hx", :line_number => 190, :class_name => "Main", :method_name => "testEdgeCases"})

    map = %{}
    map = Map.put(map, "", "empty string key")
    empty_key_value = Map.get(map, "")
    Log.trace("Empty string key value: #{empty_key_value}", %{:file_name => "Main.hx", :line_number => 196, :class_name => "Main", :method_name => "testEdgeCases"})

    # Overwrite value
    map = Map.put(map, "key", "first")
    map = Map.put(map, "key", "second")
    overwritten = Map.get(map, "key")
    Log.trace("Overwritten value: #{overwritten}", %{:file_name => "Main.hx", :line_number => 202, :class_name => "Main", :method_name => "testEdgeCases"})

    # Chain map operations
    result = %{}
    result = Map.put(result, "a", 1)
    result = Map.put(result, "b", 2)

    final_a = Map.get(result, "a")
    final_b = Map.get(result, "b")
    Log.trace("Final values after chaining: a=#{final_a}, b=#{final_b}", %{:file_name => "Main.hx", :line_number => 212, :class_name => "Main", :method_name => "testEdgeCases"})
  end
end