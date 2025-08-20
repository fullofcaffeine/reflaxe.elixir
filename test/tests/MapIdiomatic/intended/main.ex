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
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Main.test_map_construction()
    Main.test_basic_map_operations()
    Main.test_map_queries()
    Main.test_map_transformations()
    Main.test_map_utilities()
    Log.trace("Map idiomatic transformation tests complete", %{"fileName" => "Main.hx", "lineNumber" => 20, "className" => "Main", "methodName" => "main"})
  end

  @doc """
    Test Map construction transforms
    new Map() should become %{}
    new Map(data) should become Map.new(data)
  """
  @spec test_map_construction() :: nil
  def test_map_construction() do
    Log.trace("=== Map Construction ===", %{"fileName" => "Main.hx", "lineNumber" => 29, "className" => "Main", "methodName" => "testMapConstruction"})
    empty_map = %{}
    temp_string = nil
    temp_string = if (empty_map == nil), do: "null", else: empty_map.to_string()
    Log.trace("Empty map: " <> (temp_string), %{"fileName" => "Main.hx", "lineNumber" => 33, "className" => "Main", "methodName" => "testMapConstruction"})
    g = %{}
    g.set("key1", 1)
    g.set("key2", 2)
    Log.trace("Map construction tests complete", %{"fileName" => "Main.hx", "lineNumber" => 39, "className" => "Main", "methodName" => "testMapConstruction"})
  end

  @doc """
    Test basic Map operations: set, get, remove, exists
    These should transform to Map.put, Map.get, Map.delete, Map.has_key?
  """
  @spec test_basic_map_operations() :: nil
  def test_basic_map_operations() do
    Log.trace("=== Basic Map Operations ===", %{"fileName" => "Main.hx", "lineNumber" => 47, "className" => "Main", "methodName" => "testBasicMapOperations"})
    map = %{}
    Map.put(map, "name", "Alice")
    Map.put(map, "city", "Portland")
    Map.put(map, "job", "Developer")
    name = Map.get(map, "name")
    city = Map.get(map, "city")
    missing = Map.get(map, "missing")
    Log.trace("Name: " <> Kernel.inspect(name), %{"fileName" => "Main.hx", "lineNumber" => 61, "className" => "Main", "methodName" => "testBasicMapOperations"})
    Log.trace("City: " <> Kernel.inspect(city), %{"fileName" => "Main.hx", "lineNumber" => 62, "className" => "Main", "methodName" => "testBasicMapOperations"})
    Log.trace("Missing: " <> Kernel.inspect(missing), %{"fileName" => "Main.hx", "lineNumber" => 63, "className" => "Main", "methodName" => "testBasicMapOperations"})
    has_name = Map.has_key?(map, "name")
    has_missing = Map.has_key?(map, "missing")
    Log.trace("Has name: " <> Std.string(has_name), %{"fileName" => "Main.hx", "lineNumber" => 69, "className" => "Main", "methodName" => "testBasicMapOperations"})
    Log.trace("Has missing: " <> Std.string(has_missing), %{"fileName" => "Main.hx", "lineNumber" => 70, "className" => "Main", "methodName" => "testBasicMapOperations"})
    Map.delete(map, "job")
    job_after_remove = Map.get(map, "job")
    Log.trace("Job after remove: " <> Kernel.inspect(job_after_remove), %{"fileName" => "Main.hx", "lineNumber" => 75, "className" => "Main", "methodName" => "testBasicMapOperations"})
    %{}
    value_after_clear = Map.get(map, "name")
    Log.trace("Value after clear: " <> Kernel.inspect(value_after_clear), %{"fileName" => "Main.hx", "lineNumber" => 82, "className" => "Main", "methodName" => "testBasicMapOperations"})
  end

  @doc """
    Test Map query operations: keys, values, size, isEmpty
    These should transform to Map.keys, Map.values, map_size, etc.
  """
  @spec test_map_queries() :: nil
  def test_map_queries() do
    Log.trace("=== Map Query Operations ===", %{"fileName" => "Main.hx", "lineNumber" => 90, "className" => "Main", "methodName" => "testMapQueries"})
    map = %{}
    Map.put(map, "a", 1)
    Map.put(map, "b", 2)
    Map.put(map, "c", 3)
    keys = Map.keys(map)
    Log.trace("Keys: " <> Std.string(keys), %{"fileName" => "Main.hx", "lineNumber" => 99, "className" => "Main", "methodName" => "testMapQueries"})
    values = Map.values(map)
    Log.trace("Values iterator: " <> Std.string(values), %{"fileName" => "Main.hx", "lineNumber" => 103, "className" => "Main", "methodName" => "testMapQueries"})
    has_keys = false
    key = Map.keys(map)
    (
      loop_helper = fn loop_fn, {has_keys} ->
        if (key.has_next()) do
          try do
            key = key.next()
          has_keys = true
          throw(:break)
          loop_fn.({true})
            loop_fn.(loop_fn, {has_keys})
          catch
            :break -> {has_keys}
            :continue -> loop_fn.(loop_fn, {has_keys})
          end
        else
          {has_keys}
        end
      end
      {has_keys} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    Log.trace("Map has keys: " <> Std.string(has_keys), %{"fileName" => "Main.hx", "lineNumber" => 112, "className" => "Main", "methodName" => "testMapQueries"})
    empty_map = %{}
    empty_has_keys = false
    key = Map.keys(empty_map)
    (
      loop_helper = fn loop_fn, {empty_has_keys} ->
        if (key.has_next()) do
          try do
            key = key.next()
          empty_has_keys = true
          throw(:break)
          loop_fn.({true})
            loop_fn.(loop_fn, {empty_has_keys})
          catch
            :break -> {empty_has_keys}
            :continue -> loop_fn.(loop_fn, {empty_has_keys})
          end
        else
          {empty_has_keys}
        end
      end
      {empty_has_keys} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    Log.trace("Empty map has keys: " <> Std.string(empty_has_keys), %{"fileName" => "Main.hx", "lineNumber" => 120, "className" => "Main", "methodName" => "testMapQueries"})
  end

  @doc """
    Test Map transformations and iterations
    These should work with Elixir's functional iteration patterns
  """
  @spec test_map_transformations() :: nil
  def test_map_transformations() do
    Log.trace("=== Map Transformations ===", %{"fileName" => "Main.hx", "lineNumber" => 128, "className" => "Main", "methodName" => "testMapTransformations"})
    numbers = %{}
    numbers.set("one", 1)
    numbers.set("two", 2)
    numbers.set("three", 3)
    Log.trace("Iterating over map:", %{"fileName" => "Main.hx", "lineNumber" => 136, "className" => "Main", "methodName" => "testMapTransformations"})
    key = numbers.keys()
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    value = numbers.get(key)
    Log.trace("  " <> key <> " => " <> Kernel.inspect(value), %{"fileName" => "Main.hx", "lineNumber" => 139, "className" => "Main", "methodName" => "testMapTransformations"})
            loop_fn.(loop_fn)
          catch
            :break -> nil
            :continue -> loop_fn.(loop_fn)
          end
        else
          nil
        end
      end
      try do
        loop_helper.(loop_helper)
      catch
        :break -> nil
      end
    )
    copied = numbers.copy()
    copied_value = copied.get("one")
    Log.trace("Copied map value for \"one\": " <> Kernel.inspect(copied_value), %{"fileName" => "Main.hx", "lineNumber" => 147, "className" => "Main", "methodName" => "testMapTransformations"})
    int_map = %{}
    Map.put(int_map, 1, "first")
    Map.put(int_map, 2, "second")
    Log.trace("Int-keyed map:", %{"fileName" => "Main.hx", "lineNumber" => 154, "className" => "Main", "methodName" => "testMapTransformations"})
    key = Map.keys(int_map)
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    value = Map.get(int_map, key)
    Log.trace("  " <> Integer.to_string(key) <> " => " <> Kernel.inspect(value), %{"fileName" => "Main.hx", "lineNumber" => 157, "className" => "Main", "methodName" => "testMapTransformations"})
            loop_fn.(loop_fn)
          catch
            :break -> nil
            :continue -> loop_fn.(loop_fn)
          end
        else
          nil
        end
      end
      try do
        loop_helper.(loop_helper)
      catch
        :break -> nil
      end
    )
  end

  @doc """
    Test Map utility operations: toString, copy, etc.

  """
  @spec test_map_utilities() :: nil
  def test_map_utilities() do
    Log.trace("=== Map Utilities ===", %{"fileName" => "Main.hx", "lineNumber" => 165, "className" => "Main", "methodName" => "testMapUtilities"})
    map = %{}
    Map.put(map, "string", "hello")
    Map.put(map, "number", 42)
    Map.put(map, "boolean", true)
    string_repr = map.to_string()
    Log.trace("String representation: " <> string_repr, %{"fileName" => "Main.hx", "lineNumber" => 174, "className" => "Main", "methodName" => "testMapUtilities"})
    string_val = Map.get(map, "string")
    number_val = Map.get(map, "number")
    bool_val = Map.get(map, "boolean")
    Log.trace("String value: " <> Std.string(string_val), %{"fileName" => "Main.hx", "lineNumber" => 181, "className" => "Main", "methodName" => "testMapUtilities"})
    Log.trace("Number value: " <> Std.string(number_val), %{"fileName" => "Main.hx", "lineNumber" => 182, "className" => "Main", "methodName" => "testMapUtilities"})
    Log.trace("Boolean value: " <> Std.string(bool_val), %{"fileName" => "Main.hx", "lineNumber" => 183, "className" => "Main", "methodName" => "testMapUtilities"})
  end

  @doc """
    Test edge cases and special scenarios

  """
  @spec test_edge_cases() :: nil
  def test_edge_cases() do
    Log.trace("=== Edge Cases ===", %{"fileName" => "Main.hx", "lineNumber" => 190, "className" => "Main", "methodName" => "testEdgeCases"})
    map = %{}
    Map.put(map, "", "empty string key")
    empty_key_value = Map.get(map, "")
    Log.trace("Empty string key value: " <> Kernel.inspect(empty_key_value), %{"fileName" => "Main.hx", "lineNumber" => 196, "className" => "Main", "methodName" => "testEdgeCases"})
    Map.put(map, "key", "first")
    Map.put(map, "key", "second")
    overwritten = Map.get(map, "key")
    Log.trace("Overwritten value: " <> Kernel.inspect(overwritten), %{"fileName" => "Main.hx", "lineNumber" => 202, "className" => "Main", "methodName" => "testEdgeCases"})
    result = %{}
    result.set("a", 1)
    result.set("b", 2)
    final_a = result.get("a")
    final_b = result.get("b")
    Log.trace("Final values after chaining: a=" <> Kernel.inspect(final_a) <> ", b=" <> Kernel.inspect(final_b), %{"fileName" => "Main.hx", "lineNumber" => 212, "className" => "Main", "methodName" => "testEdgeCases"})
  end

end
