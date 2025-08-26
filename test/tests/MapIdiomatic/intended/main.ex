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
    (
          Main.test_map_construction()
          Main.test_basic_map_operations()
          Main.test_map_queries()
          Main.test_map_transformations()
          Main.test_map_utilities()
          Log.trace("Map idiomatic transformation tests complete", %{"fileName" => "Main.hx", "lineNumber" => 20, "className" => "Main", "methodName" => "main"})
        )
  end

  @doc """
    Test Map construction transforms
    new Map() should become %{}
    new Map(data) should become Map.new(data)
  """
  @spec test_map_construction() :: nil
  def test_map_construction() do
    temp_string = nil
    Log.trace("=== Map Construction ===", %{"fileName" => "Main.hx", "lineNumber" => 29, "className" => "Main", "methodName" => "testMapConstruction"})
    empty_map = Haxe.Ds.StringMap.new()
    temp_string = nil
    temp_string = if (((empty_map == nil))), do: "null", else: empty_map.to_string()
    Log.trace("Empty map: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 33, "className" => "Main", "methodName" => "testMapConstruction"})
    g_array = Haxe.Ds.StringMap.new()
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
    map = Haxe.Ds.StringMap.new()
    map.set("name", "Alice")
    map.set("city", "Portland")
    map.set("job", "Developer")
    name = map.get("name")
    city = map.get("city")
    missing = map.get("missing")
    Log.trace("Name: " <> to_string(name), %{"fileName" => "Main.hx", "lineNumber" => 61, "className" => "Main", "methodName" => "testBasicMapOperations"})
    Log.trace("City: " <> to_string(city), %{"fileName" => "Main.hx", "lineNumber" => 62, "className" => "Main", "methodName" => "testBasicMapOperations"})
    Log.trace("Missing: " <> to_string(missing), %{"fileName" => "Main.hx", "lineNumber" => 63, "className" => "Main", "methodName" => "testBasicMapOperations"})
    has_name = Enum.any?(map, "name")
    has_missing = Enum.any?(map, "missing")
    Log.trace("Has name: " <> Std.string(has_name), %{"fileName" => "Main.hx", "lineNumber" => 69, "className" => "Main", "methodName" => "testBasicMapOperations"})
    Log.trace("Has missing: " <> Std.string(has_missing), %{"fileName" => "Main.hx", "lineNumber" => 70, "className" => "Main", "methodName" => "testBasicMapOperations"})
    map.remove("job")
    job_after_remove = map.get("job")
    Log.trace("Job after remove: " <> to_string(job_after_remove), %{"fileName" => "Main.hx", "lineNumber" => 75, "className" => "Main", "methodName" => "testBasicMapOperations"})
    map.clear()
    value_after_clear = map.get("name")
    Log.trace("Value after clear: " <> to_string(value_after_clear), %{"fileName" => "Main.hx", "lineNumber" => 82, "className" => "Main", "methodName" => "testBasicMapOperations"})
  end

  @doc """
    Test Map query operations: keys, values, size, isEmpty
    These should transform to Map.keys, Map.values, map_size, etc.
  """
  @spec test_map_queries() :: nil
  def test_map_queries() do
    Log.trace("=== Map Query Operations ===", %{"fileName" => "Main.hx", "lineNumber" => 90, "className" => "Main", "methodName" => "testMapQueries"})
    map = Haxe.Ds.StringMap.new()
    map.set("a", 1)
    map.set("b", 2)
    map.set("c", 3)
    keys = map.keys()
    Log.trace("Keys: " <> Std.string(keys), %{"fileName" => "Main.hx", "lineNumber" => 99, "className" => "Main", "methodName" => "testMapQueries"})
    values = map.iterator()
    Log.trace("Values iterator: " <> Std.string(values), %{"fileName" => "Main.hx", "lineNumber" => 103, "className" => "Main", "methodName" => "testMapQueries"})
    has_keys = false
    (
          key = map.keys()
          (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> key.has_next() end,
        fn ->
          (
                key.next()
                has_keys = true
                throw(:break)
              )
        end,
        loop_helper
      )
    )
        )
    Log.trace("Map has keys: " <> Std.string(has_keys), %{"fileName" => "Main.hx", "lineNumber" => 112, "className" => "Main", "methodName" => "testMapQueries"})
    empty_map = Haxe.Ds.StringMap.new()
    empty_has_keys = false
    (
          key = empty_map.keys()
          (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> key.has_next() end,
        fn ->
          (
                key.next()
                empty_has_keys = true
                throw(:break)
              )
        end,
        loop_helper
      )
    )
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
    numbers = Haxe.Ds.StringMap.new()
    numbers.set("one", 1)
    numbers.set("two", 2)
    numbers.set("three", 3)
    Log.trace("Iterating over map:", %{"fileName" => "Main.hx", "lineNumber" => 136, "className" => "Main", "methodName" => "testMapTransformations"})
    (
          key = numbers.keys()
          (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> key.has_next() end,
        fn ->
          (
                key = key.next()
                value = numbers.get(key)
                Log.trace("  " <> key <> " => " <> to_string(value), %{"fileName" => "Main.hx", "lineNumber" => 139, "className" => "Main", "methodName" => "testMapTransformations"})
              )
        end,
        loop_helper
      )
    )
        )
    copied = numbers.copy()
    copied_value = copied.get("one")
    Log.trace("Copied map value for \"one\": " <> to_string(copied_value), %{"fileName" => "Main.hx", "lineNumber" => 147, "className" => "Main", "methodName" => "testMapTransformations"})
    int_map = Haxe.Ds.IntMap.new()
    int_map.set(1, "first")
    int_map.set(2, "second")
    Log.trace("Int-keyed map:", %{"fileName" => "Main.hx", "lineNumber" => 154, "className" => "Main", "methodName" => "testMapTransformations"})
    (
          key = int_map.keys()
          (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> key.has_next() end,
        fn ->
          (
                key = key.next()
                value = int_map.get(key)
                Log.trace("  " <> to_string(key) <> " => " <> to_string(value), %{"fileName" => "Main.hx", "lineNumber" => 157, "className" => "Main", "methodName" => "testMapTransformations"})
              )
        end,
        loop_helper
      )
    )
        )
  end

  @doc """
    Test Map utility operations: toString, copy, etc.

  """
  @spec test_map_utilities() :: nil
  def test_map_utilities() do
    Log.trace("=== Map Utilities ===", %{"fileName" => "Main.hx", "lineNumber" => 165, "className" => "Main", "methodName" => "testMapUtilities"})
    map = Haxe.Ds.StringMap.new()
    map.set("string", "hello")
    map.set("number", 42)
    map.set("boolean", true)
    string_repr = map.to_string()
    Log.trace("String representation: " <> string_repr, %{"fileName" => "Main.hx", "lineNumber" => 174, "className" => "Main", "methodName" => "testMapUtilities"})
    string_val = map.get("string")
    number_val = map.get("number")
    bool_val = map.get("boolean")
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
    map = Haxe.Ds.StringMap.new()
    map.set("", "empty string key")
    empty_key_value = map.get("")
    Log.trace("Empty string key value: " <> to_string(empty_key_value), %{"fileName" => "Main.hx", "lineNumber" => 196, "className" => "Main", "methodName" => "testEdgeCases"})
    map.set("key", "first")
    map.set("key", "second")
    overwritten = map.get("key")
    Log.trace("Overwritten value: " <> to_string(overwritten), %{"fileName" => "Main.hx", "lineNumber" => 202, "className" => "Main", "methodName" => "testEdgeCases"})
    result = Haxe.Ds.StringMap.new()
    result.set("a", 1)
    result.set("b", 2)
    final_a = result.get("a")
    final_b = result.get("b")
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
