defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Map/Dictionary test case
     * Tests various map types and operations
  """

  # Static functions
  @doc "Generated from Haxe stringMap"
  def string_map() do
    map = StringMap.new()

    map = Map.put(map, "one", 1)

    map = Map.put(map, "two", 2)

    map = Map.put(map, "three", 3)

    Log.trace("Value of \"two\": " <> to_string(Map.get(map, "two")), %{"fileName" => "Main.hx", "lineNumber" => 18, "className" => "Main", "methodName" => "stringMap"})

    Log.trace("Value of \"four\": " <> to_string(Map.get(map, "four")), %{"fileName" => "Main.hx", "lineNumber" => 19, "className" => "Main", "methodName" => "stringMap"})

    Log.trace("Has \"one\": " <> Std.string(Map.has_key?(map, "one")), %{"fileName" => "Main.hx", "lineNumber" => 22, "className" => "Main", "methodName" => "stringMap"})

    Log.trace("Has \"four\": " <> Std.string(Map.has_key?(map, "four")), %{"fileName" => "Main.hx", "lineNumber" => 23, "className" => "Main", "methodName" => "stringMap"})

    Map.delete(map, "two")

    Log.trace("After remove, has \"two\": " <> Std.string(Map.has_key?(map, "two")), %{"fileName" => "Main.hx", "lineNumber" => 27, "className" => "Main", "methodName" => "stringMap"})

    Log.trace("Iterating string map:", %{"fileName" => "Main.hx", "lineNumber" => 30, "className" => "Main", "methodName" => "stringMap"})

    key = Map.keys(map)

    (fn loop ->
      if key.has_next() do
            key = key.next()
        Log.trace("  " <> key <> " => " <> to_string(Map.get(map, key)), %{"fileName" => "Main.hx", "lineNumber" => 32, "className" => "Main", "methodName" => "stringMap"})
        loop.()
      end
    end).()

    %{}

    g_array = []

    k = Map.keys(map)

    (fn loop ->
      if k.has_next() do
            k = k.next()
        g_array = g_array ++ [k]
        loop.()
      end
    end).()

    Log.trace("After clear, keys: " <> Std.string(g_array), %{"fileName" => "Main.hx", "lineNumber" => 37, "className" => "Main", "methodName" => "stringMap"})
  end

  @doc "Generated from Haxe intMap"
  def int_map() do
    temp_array = nil
    temp_array1 = nil

    map = IntMap.new()

    map = Map.put(map, 1, "first")

    map = Map.put(map, 2, "second")

    map = Map.put(map, 10, "tenth")

    map = Map.put(map, 100, "hundredth")

    Log.trace("Int map values:", %{"fileName" => "Main.hx", "lineNumber" => 49, "className" => "Main", "methodName" => "intMap"})

    key = Map.keys(map)

    (fn loop ->
      if key.has_next() do
            key = key.next()
        Log.trace("  " <> to_string(key) <> " => " <> to_string(Map.get(map, key)), %{"fileName" => "Main.hx", "lineNumber" => 51, "className" => "Main", "methodName" => "intMap"})
        loop.()
      end
    end).()

    g_array = []
    k = Map.keys(map)
    (fn loop ->
      if k.has_next() do
            k = k.next()
        g_array = g_array ++ [k]
        loop.()
      end
    end).()
    temp_array = g_array

    g_array = []
    k = Map.keys(map)
    (fn loop ->
      if k.has_next() do
            k = k.next()
        g_array = g_array ++ [Map.get(map, k)]
        loop.()
      end
    end).()
    temp_array1 = g_array

    Log.trace("Keys: " <> Std.string(temp_array), %{"fileName" => "Main.hx", "lineNumber" => 57, "className" => "Main", "methodName" => "intMap"})

    Log.trace("Values: " <> Std.string(temp_array1), %{"fileName" => "Main.hx", "lineNumber" => 58, "className" => "Main", "methodName" => "intMap"})
  end

  @doc "Generated from Haxe objectMap"
  def object_map() do
    map = ObjectMap.new()

    obj1 = %{"id" => 1}

    obj2 = %{"id" => 2}

    map = Map.put(map, obj1, "Object 1")

    map = Map.put(map, obj2, "Object 2")

    Log.trace("Object 1 value: " <> to_string(Map.get(map, obj1)), %{"fileName" => "Main.hx", "lineNumber" => 71, "className" => "Main", "methodName" => "objectMap"})

    Log.trace("Object 2 value: " <> to_string(Map.get(map, obj2)), %{"fileName" => "Main.hx", "lineNumber" => 72, "className" => "Main", "methodName" => "objectMap"})

    obj3 = %{"id" => 1}

    Log.trace("New {id: 1} value: " <> to_string(Map.get(map, obj3)), %{"fileName" => "Main.hx", "lineNumber" => 76, "className" => "Main", "methodName" => "objectMap"})
  end

  @doc "Generated from Haxe mapLiterals"
  def map_literals() do
    temp_map = nil
    temp_map1 = nil

    temp_map = nil

    g_array = StringMap.new()
    g_array = Map.put(g_array, "red", 16711680)
    g_array = Map.put(g_array, "green", 65280)
    g_array = Map.put(g_array, "blue", 255)
    temp_map = g_array

    Log.trace("Color values:", %{"fileName" => "Main.hx", "lineNumber" => 88, "className" => "Main", "methodName" => "mapLiterals"})

    color = temp_map.keys()

    (fn loop ->
      if color.has_next() do
            color = color.next()
        hex = StringTools.hex(temp_map.get(color), 6)
        Log.trace("  " <> color <> " => #" <> hex, %{"fileName" => "Main.hx", "lineNumber" => 91, "className" => "Main", "methodName" => "mapLiterals"})
        loop.()
      end
    end).()

    temp_map1 = nil

    g_array = IntMap.new()
    g_array = Map.put(g_array, 1, 1)
    g_array = Map.put(g_array, 2, 4)
    g_array = Map.put(g_array, 3, 9)
    g_array = Map.put(g_array, 4, 16)
    g_array = Map.put(g_array, 5, 25)
    temp_map1 = g_array

    Log.trace("Squares:", %{"fileName" => "Main.hx", "lineNumber" => 103, "className" => "Main", "methodName" => "mapLiterals"})

    n = temp_map1.keys()

    (fn loop ->
      if n.has_next() do
            n = n.next()
        Log.trace("  " <> to_string(n) <> "² = " <> to_string(temp_map1.get(n)), %{"fileName" => "Main.hx", "lineNumber" => 105, "className" => "Main", "methodName" => "mapLiterals"})
        loop.()
      end
    end).()
  end

  @doc "Generated from Haxe nestedMaps"
  def nested_maps() do
    users = StringMap.new()

    alice = StringMap.new()

    alice = Map.put(alice, "age", 30)

    alice = Map.put(alice, "email", "alice@example.com")

    alice = Map.put(alice, "active", true)

    bob = StringMap.new()

    bob = Map.put(bob, "age", 25)

    bob = Map.put(bob, "email", "bob@example.com")

    bob = Map.put(bob, "active", false)

    users = Map.put(users, "alice", alice)

    users = Map.put(users, "bob", bob)

    Log.trace("User data:", %{"fileName" => "Main.hx", "lineNumber" => 128, "className" => "Main", "methodName" => "nestedMaps"})

    username = Map.keys(users)

    (fn loop ->
      if username.has_next() do
            username = username.next()
        user_data = Map.get(users, username)
        Log.trace("  " <> username <> ":", %{"fileName" => "Main.hx", "lineNumber" => 131, "className" => "Main", "methodName" => "nestedMaps"})
        field = Map.keys(user_data)
        (fn loop ->
          if field.has_next() do
                field = field.next()
            Log.trace("    " <> field <> ": " <> Std.string(Map.get(user_data, field)), %{"fileName" => "Main.hx", "lineNumber" => 133, "className" => "Main", "methodName" => "nestedMaps"})
            loop.()
          end
        end).()
        loop.()
      end
    end).()
  end

  @doc "Generated from Haxe mapTransformations"
  def map_transformations() do
    temp_map = nil
    temp_map1 = nil
    temp_map2 = nil

    g_array = StringMap.new()
    g_array = Map.put(g_array, "a", 1)
    g_array = Map.put(g_array, "b", 2)
    g_array = Map.put(g_array, "c", 3)
    g_array = Map.put(g_array, "d", 4)
    temp_map = g_array

    doubled = StringMap.new()

    key = temp_map.keys()
    (fn loop ->
      if key.has_next() do
            key = key.next()
        value = (temp_map.get(key) * 2)
        doubled = Map.put(doubled, key, value)
        loop.()
      end
    end).()

    Log.trace("Doubled values:", %{"fileName" => "Main.hx", "lineNumber" => 153, "className" => "Main", "methodName" => "mapTransformations"})

    key = Map.keys(doubled)
    (fn loop ->
      if key.has_next() do
            key = key.next()
        Log.trace("  " <> key <> " => " <> to_string(Map.get(doubled, key)), %{"fileName" => "Main.hx", "lineNumber" => 155, "className" => "Main", "methodName" => "mapTransformations"})
        loop.()
      end
    end).()

    filtered = StringMap.new()

    key = temp_map.keys()
    (fn loop ->
      if key.has_next() do
            key = key.next()
        value = temp_map.get(key)
        if ((value > 2)), do: filtered = Map.put(filtered, key, value), else: nil
        loop.()
      end
    end).()

    Log.trace("Filtered (value > 2):", %{"fileName" => "Main.hx", "lineNumber" => 167, "className" => "Main", "methodName" => "mapTransformations"})

    key = Map.keys(filtered)
    (fn loop ->
      if key.has_next() do
            key = key.next()
        Log.trace("  " <> key <> " => " <> to_string(Map.get(filtered, key)), %{"fileName" => "Main.hx", "lineNumber" => 169, "className" => "Main", "methodName" => "mapTransformations"})
        loop.()
      end
    end).()

    g_array = StringMap.new()
    g_array = Map.put(g_array, "a", 1)
    g_array = Map.put(g_array, "b", 2)
    temp_map1 = g_array

    temp_map2 = nil

    g_array = StringMap.new()
    g_array = Map.put(g_array, "c", 3)
    g_array = Map.put(g_array, "d", 4)
    g_array = Map.put(g_array, "a", 10)
    temp_map2 = g_array

    merged = StringMap.new()

    key = temp_map1.keys()
    (fn loop ->
      if key.has_next() do
            key = key.next()
        value = temp_map1.get(key)
        merged = Map.put(merged, key, value)
        loop.()
      end
    end).()

    key = temp_map2.keys()
    (fn loop ->
      if key.has_next() do
            key = key.next()
        value = temp_map2.get(key)
        merged = Map.put(merged, key, value)
        loop.()
      end
    end).()

    Log.trace("Merged maps:", %{"fileName" => "Main.hx", "lineNumber" => 184, "className" => "Main", "methodName" => "mapTransformations"})

    key = Map.keys(merged)
    (fn loop ->
      if key.has_next() do
            key = key.next()
        Log.trace("  " <> key <> " => " <> to_string(Map.get(merged, key)), %{"fileName" => "Main.hx", "lineNumber" => 186, "className" => "Main", "methodName" => "mapTransformations"})
        loop.()
      end
    end).()
  end

  @doc "Generated from Haxe enumMap"
  def enum_map() do
    map = EnumValueMap.new()

    map = Map.put(map, :red, "FF0000")

    map = Map.put(map, :green, "00FF00")

    map = Map.put(map, :blue, "0000FF")

    Log.trace("Enum map:", %{"fileName" => "Main.hx", "lineNumber" => 198, "className" => "Main", "methodName" => "enumMap"})

    color = Map.keys(map)

    (fn loop ->
      if color.has_next() do
            color = color.next()
        Log.trace("  " <> Std.string(color) <> " => #" <> to_string(Map.get(map, color)), %{"fileName" => "Main.hx", "lineNumber" => 200, "className" => "Main", "methodName" => "enumMap"})
        loop.()
      end
    end).()

    if Map.has_key?(map, :red), do: Log.trace("Red color code: #" <> to_string(Map.get(map, :red)), %{"fileName" => "Main.hx", "lineNumber" => 205, "className" => "Main", "methodName" => "enumMap"}), else: nil
  end

  @doc "Generated from Haxe processMap"
  def process_map(input) do
    result = StringMap.new()

    key = Map.keys(input)

    (fn loop ->
      if key.has_next() do
            key = key.next()
        value = Map.get(input, key)
        result = Map.put(result, key, "Value: " <> to_string(value))
        loop.()
      end
    end).()

    result
  end

  @doc "Generated from Haxe main"
  def main() do
    Log.trace("=== String Map ===", %{"fileName" => "Main.hx", "lineNumber" => 220, "className" => "Main", "methodName" => "main"})

    Main.string_map()

    Log.trace("\n=== Int Map ===", %{"fileName" => "Main.hx", "lineNumber" => 223, "className" => "Main", "methodName" => "main"})

    Main.int_map()

    Log.trace("\n=== Object Map ===", %{"fileName" => "Main.hx", "lineNumber" => 226, "className" => "Main", "methodName" => "main"})

    Main.object_map()

    Log.trace("\n=== Map Literals ===", %{"fileName" => "Main.hx", "lineNumber" => 229, "className" => "Main", "methodName" => "main"})

    Main.map_literals()

    Log.trace("\n=== Nested Maps ===", %{"fileName" => "Main.hx", "lineNumber" => 232, "className" => "Main", "methodName" => "main"})

    Main.nested_maps()

    Log.trace("\n=== Map Transformations ===", %{"fileName" => "Main.hx", "lineNumber" => 235, "className" => "Main", "methodName" => "main"})

    Main.map_transformations()

    Log.trace("\n=== Enum Map ===", %{"fileName" => "Main.hx", "lineNumber" => 238, "className" => "Main", "methodName" => "main"})

    Main.enum_map()

    Log.trace("\n=== Map Functions ===", %{"fileName" => "Main.hx", "lineNumber" => 241, "className" => "Main", "methodName" => "main"})

    g_array = StringMap.new()

    g_array = Map.put(g_array, "x", 10)

    g_array = Map.put(g_array, "y", 20)

    g_array = Map.put(g_array, "z", 30)

    output = Main.process_map(g_array)

    key = Map.keys(output)

    (fn loop ->
      if key.has_next() do
            key = key.next()
        Log.trace("" <> key <> ": " <> to_string(Map.get(output, key)), %{"fileName" => "Main.hx", "lineNumber" => 245, "className" => "Main", "methodName" => "main"})
        loop.()
      end
    end).()
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
