defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Test idiomatic Map transformations
     *
     * This test validates that all Map operations are transformed from
     * OOP-style Haxe code to idiomatic functional Elixir patterns.
     *
     * BEFORE (OOP-style):   map.set("key", value)
     * AFTER (Functional):   Map.put(map, "key", value)
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_map_construction()

    Main.test_basic_map_operations()

    Main.test_map_queries()

    Main.test_map_transformations()

    Main.test_map_utilities()

    Log.trace("Map idiomatic transformation tests complete", %{"fileName" => "Main.hx", "lineNumber" => 20, "className" => "Main", "methodName" => "main"})
  end

  @doc "Generated from Haxe testMapConstruction"
  def test_map_construction() do
    temp_string = nil

    Log.trace("=== Map Construction ===", %{"fileName" => "Main.hx", "lineNumber" => 29, "className" => "Main", "methodName" => "testMapConstruction"})

    empty_map = StringMap.new()

    temp_string = nil

    if ((empty_map == nil)), do: temp_string = "null", else: temp_string = empty_map.to_string()

    Log.trace("Empty map: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 33, "className" => "Main", "methodName" => "testMapConstruction"})

    g_array = StringMap.new()

    g_array = Map.put(g_array, "key1", 1)

    g_array = Map.put(g_array, "key2", 2)

    Log.trace("Map construction tests complete", %{"fileName" => "Main.hx", "lineNumber" => 39, "className" => "Main", "methodName" => "testMapConstruction"})
  end

  @doc "Generated from Haxe testBasicMapOperations"
  def test_basic_map_operations() do
    Log.trace("=== Basic Map Operations ===", %{"fileName" => "Main.hx", "lineNumber" => 47, "className" => "Main", "methodName" => "testBasicMapOperations"})

    map = StringMap.new()

    map = Map.put(map, "name", "Alice")

    map = Map.put(map, "city", "Portland")

    map = Map.put(map, "job", "Developer")

    name = Map.get(map, "name")

    city = Map.get(map, "city")

    missing = Map.get(map, "missing")

    Log.trace("Name: " <> to_string(name), %{"fileName" => "Main.hx", "lineNumber" => 61, "className" => "Main", "methodName" => "testBasicMapOperations"})

    Log.trace("City: " <> to_string(city), %{"fileName" => "Main.hx", "lineNumber" => 62, "className" => "Main", "methodName" => "testBasicMapOperations"})

    Log.trace("Missing: " <> to_string(missing), %{"fileName" => "Main.hx", "lineNumber" => 63, "className" => "Main", "methodName" => "testBasicMapOperations"})

    has_name = Map.has_key?(map, "name")

    has_missing = Map.has_key?(map, "missing")

    Log.trace("Has name: " <> Std.string(has_name), %{"fileName" => "Main.hx", "lineNumber" => 69, "className" => "Main", "methodName" => "testBasicMapOperations"})

    Log.trace("Has missing: " <> Std.string(has_missing), %{"fileName" => "Main.hx", "lineNumber" => 70, "className" => "Main", "methodName" => "testBasicMapOperations"})

    Map.delete(map, "job")

    job_after_remove = Map.get(map, "job")

    Log.trace("Job after remove: " <> to_string(job_after_remove), %{"fileName" => "Main.hx", "lineNumber" => 75, "className" => "Main", "methodName" => "testBasicMapOperations"})

    %{}

    value_after_clear = Map.get(map, "name")

    Log.trace("Value after clear: " <> to_string(value_after_clear), %{"fileName" => "Main.hx", "lineNumber" => 82, "className" => "Main", "methodName" => "testBasicMapOperations"})
  end

  @doc "Generated from Haxe testMapQueries"
  def test_map_queries() do
    Log.trace("=== Map Query Operations ===", %{"fileName" => "Main.hx", "lineNumber" => 90, "className" => "Main", "methodName" => "testMapQueries"})

    map = StringMap.new()

    map = Map.put(map, "a", 1)

    map = Map.put(map, "b", 2)

    map = Map.put(map, "c", 3)

    keys = Map.keys(map)

    Log.trace("Keys: " <> Std.string(keys), %{"fileName" => "Main.hx", "lineNumber" => 99, "className" => "Main", "methodName" => "testMapQueries"})

    values = Map.values(map)

    Log.trace("Values iterator: " <> Std.string(values), %{"fileName" => "Main.hx", "lineNumber" => 103, "className" => "Main", "methodName" => "testMapQueries"})

    has_keys = false

    key = Map.keys(map)
    (fn loop ->
      if key.has_next() do
            _key = _key.next()
        has_keys = true
        throw(:break)
        loop.()
      end
    end).()

    Log.trace("Map has keys: " <> Std.string(has_keys), %{"fileName" => "Main.hx", "lineNumber" => 112, "className" => "Main", "methodName" => "testMapQueries"})

    empty_map = StringMap.new()

    empty_has_keys = false

    key = Map.keys(empty_map)
    (fn loop ->
      if _key.has_next() do
            _key = _key.next()
        empty_has_keys = true
        throw(:break)
        loop.()
      end
    end).()

    Log.trace("Empty map has keys: " <> Std.string(empty_has_keys), %{"fileName" => "Main.hx", "lineNumber" => 120, "className" => "Main", "methodName" => "testMapQueries"})
  end

  @doc "Generated from Haxe testMapTransformations"
  def test_map_transformations() do
    Log.trace("=== Map Transformations ===", %{"fileName" => "Main.hx", "lineNumber" => 128, "className" => "Main", "methodName" => "testMapTransformations"})

    numbers = StringMap.new()

    numbers = Map.put(numbers, "one", 1)

    numbers = Map.put(numbers, "two", 2)

    numbers = Map.put(numbers, "three", 3)

    Log.trace("Iterating over map:", %{"fileName" => "Main.hx", "lineNumber" => 136, "className" => "Main", "methodName" => "testMapTransformations"})

    key = Map.keys(numbers)
    (fn loop ->
      if _key.has_next() do
            key = _key.next()
        value = Map.get(numbers, _key)
        Log.trace("  " <> _key <> " => " <> to_string(value), %{"fileName" => "Main.hx", "lineNumber" => 139, "className" => "Main", "methodName" => "testMapTransformations"})
        loop.()
      end
    end).()

    copied = Map.new(numbers)

    copied_value = Map.get(copied, "one")

    Log.trace("Copied map value for \"one\": " <> to_string(copied_value), %{"fileName" => "Main.hx", "lineNumber" => 147, "className" => "Main", "methodName" => "testMapTransformations"})

    int_map = IntMap.new()

    int_map = Map.put(int_map, 1, "first")

    int_map = Map.put(int_map, 2, "second")

    Log.trace("Int-keyed map:", %{"fileName" => "Main.hx", "lineNumber" => 154, "className" => "Main", "methodName" => "testMapTransformations"})

    key = Map.keys(int_map)
    (fn loop ->
      if _key.has_next() do
            key = _key.next()
        value = Map.get(int_map, _key)
        Log.trace("  " <> to_string(_key) <> " => " <> to_string(value), %{"fileName" => "Main.hx", "lineNumber" => 157, "className" => "Main", "methodName" => "testMapTransformations"})
        loop.()
      end
    end).()
  end

  @doc "Generated from Haxe testMapUtilities"
  def test_map_utilities() do
    Log.trace("=== Map Utilities ===", %{"fileName" => "Main.hx", "lineNumber" => 165, "className" => "Main", "methodName" => "testMapUtilities"})

    map = StringMap.new()

    map = Map.put(map, "string", "hello")

    map = Map.put(map, "number", 42)

    map = Map.put(map, "boolean", true)

    string_repr = map.to_string()

    Log.trace("String representation: " <> string_repr, %{"fileName" => "Main.hx", "lineNumber" => 174, "className" => "Main", "methodName" => "testMapUtilities"})

    string_val = Map.get(map, "string")

    number_val = Map.get(map, "number")

    bool_val = Map.get(map, "boolean")

    Log.trace("String value: " <> Std.string(string_val), %{"fileName" => "Main.hx", "lineNumber" => 181, "className" => "Main", "methodName" => "testMapUtilities"})

    Log.trace("Number value: " <> Std.string(number_val), %{"fileName" => "Main.hx", "lineNumber" => 182, "className" => "Main", "methodName" => "testMapUtilities"})

    Log.trace("Boolean value: " <> Std.string(bool_val), %{"fileName" => "Main.hx", "lineNumber" => 183, "className" => "Main", "methodName" => "testMapUtilities"})
  end

  @doc "Generated from Haxe testEdgeCases"
  def test_edge_cases() do
    Log.trace("=== Edge Cases ===", %{"fileName" => "Main.hx", "lineNumber" => 190, "className" => "Main", "methodName" => "testEdgeCases"})

    map = StringMap.new()

    map = Map.put(map, "", "empty string key")

    empty_key_value = Map.get(map, "")

    Log.trace("Empty string key value: " <> to_string(empty_key_value), %{"fileName" => "Main.hx", "lineNumber" => 196, "className" => "Main", "methodName" => "testEdgeCases"})

    map = Map.put(map, "key", "first")

    map = Map.put(map, "key", "second")

    overwritten = Map.get(map, "key")

    Log.trace("Overwritten value: " <> to_string(overwritten), %{"fileName" => "Main.hx", "lineNumber" => 202, "className" => "Main", "methodName" => "testEdgeCases"})

    result = StringMap.new()

    result = Map.put(result, "a", 1)

    result = Map.put(result, "b", 2)

    final_a = Map.get(result, "a")

    final_b = Map.get(result, "b")

    Log.trace("Final values after chaining: a=" <> to_string(final_a) <> ", b=" <> to_string(final_b), %{"fileName" => "Main.hx", "lineNumber" => 212, "className" => "Main", "methodName" => "testEdgeCases"})
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
