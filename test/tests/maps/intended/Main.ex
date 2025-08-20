defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Map/Dictionary test case
     * Tests various map types and operations
  """

  # Static functions
  @doc "Function string_map"
  @spec string_map() :: nil
  def string_map() do
    map = %{}
    Map.put(map, "one", 1)
    Map.put(map, "two", 2)
    Map.put(map, "three", 3)
    Log.trace("Value of \"two\": " <> Kernel.inspect(Map.get(map, "two")), %{"fileName" => "Main.hx", "lineNumber" => 18, "className" => "Main", "methodName" => "stringMap"})
    Log.trace("Value of \"four\": " <> Kernel.inspect(Map.get(map, "four")), %{"fileName" => "Main.hx", "lineNumber" => 19, "className" => "Main", "methodName" => "stringMap"})
    Log.trace("Has \"one\": " <> Std.string(Map.has_key?(map, "one")), %{"fileName" => "Main.hx", "lineNumber" => 22, "className" => "Main", "methodName" => "stringMap"})
    Log.trace("Has \"four\": " <> Std.string(Map.has_key?(map, "four")), %{"fileName" => "Main.hx", "lineNumber" => 23, "className" => "Main", "methodName" => "stringMap"})
    Map.delete(map, "two")
    Log.trace("After remove, has \"two\": " <> Std.string(Map.has_key?(map, "two")), %{"fileName" => "Main.hx", "lineNumber" => 27, "className" => "Main", "methodName" => "stringMap"})
    Log.trace("Iterating string map:", %{"fileName" => "Main.hx", "lineNumber" => 30, "className" => "Main", "methodName" => "stringMap"})
    key = Map.keys(map)
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    Log.trace("  " <> key <> " => " <> Kernel.inspect(Map.get(map, key)), %{"fileName" => "Main.hx", "lineNumber" => 32, "className" => "Main", "methodName" => "stringMap"})
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
    %{}
    g_array = []
    k = Map.keys(map)
    (
      loop_helper = fn loop_fn ->
        if (k.has_next()) do
          try do
            k = k.next()
    g ++ [k]
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
    Log.trace("After clear, keys: " <> Std.string(g), %{"fileName" => "Main.hx", "lineNumber" => 37, "className" => "Main", "methodName" => "stringMap"})
  end

  @doc "Function int_map"
  @spec int_map() :: nil
  def int_map() do
    map = %{}
    Map.put(map, 1, "first")
    Map.put(map, 2, "second")
    Map.put(map, 10, "tenth")
    Map.put(map, 100, "hundredth")
    Log.trace("Int map values:", %{"fileName" => "Main.hx", "lineNumber" => 49, "className" => "Main", "methodName" => "intMap"})
    key = Map.keys(map)
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    Log.trace("  " <> Integer.to_string(key) <> " => " <> Kernel.inspect(Map.get(map, key)), %{"fileName" => "Main.hx", "lineNumber" => 51, "className" => "Main", "methodName" => "intMap"})
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
    temp_array = nil
    g_array = []
    k = Map.keys(map)
    (
      loop_helper = fn loop_fn ->
        if (k.has_next()) do
          try do
            k = k.next()
    g ++ [k]
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
    temp_array = g
    temp_array1 = nil
    g_array = []
    k = Map.keys(map)
    (
      loop_helper = fn loop_fn ->
        if (k.has_next()) do
          try do
            k = k.next()
    g ++ [Map.get(map, k)]
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
    temp_array1 = g
    Log.trace("Keys: " <> Std.string(temp_array), %{"fileName" => "Main.hx", "lineNumber" => 57, "className" => "Main", "methodName" => "intMap"})
    Log.trace("Values: " <> Std.string(temp_array1), %{"fileName" => "Main.hx", "lineNumber" => 58, "className" => "Main", "methodName" => "intMap"})
  end

  @doc "Function object_map"
  @spec object_map() :: nil
  def object_map() do
    map = %{}
    obj1 = %{"id" => 1}
    obj2 = %{"id" => 2}
    Map.put(map, obj1, "Object 1")
    Map.put(map, obj2, "Object 2")
    Log.trace("Object 1 value: " <> Kernel.inspect(Map.get(map, obj1)), %{"fileName" => "Main.hx", "lineNumber" => 71, "className" => "Main", "methodName" => "objectMap"})
    Log.trace("Object 2 value: " <> Kernel.inspect(Map.get(map, obj2)), %{"fileName" => "Main.hx", "lineNumber" => 72, "className" => "Main", "methodName" => "objectMap"})
    obj3 = %{"id" => 1}
    Log.trace("New {id: 1} value: " <> Kernel.inspect(Map.get(map, obj3)), %{"fileName" => "Main.hx", "lineNumber" => 76, "className" => "Main", "methodName" => "objectMap"})
  end

  @doc "Function map_literals"
  @spec map_literals() :: nil
  def map_literals() do
    temp_map = nil
    g = %{}
    g.set("red", 16711680)
    g.set("green", 65280)
    g.set("blue", 255)
    temp_map = g
    Log.trace("Color values:", %{"fileName" => "Main.hx", "lineNumber" => 88, "className" => "Main", "methodName" => "mapLiterals"})
    color = Map.keys(temp_map)
    (
      loop_helper = fn loop_fn ->
        if (color.has_next()) do
          try do
            color = color.next()
    hex = StringTools.hex(Map.get(temp_map, color), 6)
    Log.trace("  " <> color <> " => #" <> hex, %{"fileName" => "Main.hx", "lineNumber" => 91, "className" => "Main", "methodName" => "mapLiterals"})
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
    temp_map1 = nil
    g = %{}
    g.set(1, 1)
    g.set(2, 4)
    g.set(3, 9)
    g.set(4, 16)
    g.set(5, 25)
    temp_map1 = g
    Log.trace("Squares:", %{"fileName" => "Main.hx", "lineNumber" => 103, "className" => "Main", "methodName" => "mapLiterals"})
    n = Map.keys(temp_map1)
    (
      loop_helper = fn loop_fn ->
        if (n.has_next()) do
          try do
            n = n.next()
    Log.trace("  " <> Integer.to_string(n) <> "² = " <> Kernel.inspect(Map.get(temp_map1, n)), %{"fileName" => "Main.hx", "lineNumber" => 105, "className" => "Main", "methodName" => "mapLiterals"})
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

  @doc "Function nested_maps"
  @spec nested_maps() :: nil
  def nested_maps() do
    users = %{}
    alice = %{}
    alice.set("age", 30)
    alice.set("email", "alice@example.com")
    alice.set("active", true)
    bob = %{}
    bob.set("age", 25)
    bob.set("email", "bob@example.com")
    bob.set("active", false)
    users.set("alice", alice)
    users.set("bob", bob)
    Log.trace("User data:", %{"fileName" => "Main.hx", "lineNumber" => 128, "className" => "Main", "methodName" => "nestedMaps"})
    username = users.keys()
    (
      loop_helper = fn loop_fn ->
        if (username.has_next()) do
          try do
            username = username.next()
    user_data = users.get(username)
    Log.trace("  " <> username <> ":", %{"fileName" => "Main.hx", "lineNumber" => 131, "className" => "Main", "methodName" => "nestedMaps"})
    field = Map.keys(user_data)
    (
      loop_helper = fn loop_fn ->
        if (field.has_next()) do
          try do
            field = field.next()
    Log.trace("    " <> field <> ": " <> Std.string(Map.get(user_data, field)), %{"fileName" => "Main.hx", "lineNumber" => 133, "className" => "Main", "methodName" => "nestedMaps"})
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

  @doc "Function map_transformations"
  @spec map_transformations() :: nil
  def map_transformations() do
    temp_map = nil
    g = %{}
    g.set("a", 1)
    g.set("b", 2)
    g.set("c", 3)
    g.set("d", 4)
    temp_map = g
    doubled = %{}
    key = Map.keys(temp_map)
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    value = Map.get(temp_map, key) * 2
    doubled.set(key, value)
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
    Log.trace("Doubled values:", %{"fileName" => "Main.hx", "lineNumber" => 153, "className" => "Main", "methodName" => "mapTransformations"})
    key = doubled.keys()
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    Log.trace("  " <> key <> " => " <> Kernel.inspect(doubled.get(key)), %{"fileName" => "Main.hx", "lineNumber" => 155, "className" => "Main", "methodName" => "mapTransformations"})
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
    filtered = %{}
    key = Map.keys(temp_map)
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    value = Map.get(temp_map, key)
    if (value > 2), do: filtered.set(key, value), else: nil
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
    Log.trace("Filtered (value > 2):", %{"fileName" => "Main.hx", "lineNumber" => 167, "className" => "Main", "methodName" => "mapTransformations"})
    key = filtered.keys()
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    Log.trace("  " <> key <> " => " <> Kernel.inspect(filtered.get(key)), %{"fileName" => "Main.hx", "lineNumber" => 169, "className" => "Main", "methodName" => "mapTransformations"})
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
    temp_map1 = nil
    g = %{}
    g.set("a", 1)
    g.set("b", 2)
    temp_map1 = g
    temp_map2 = nil
    g = %{}
    g.set("c", 3)
    g.set("d", 4)
    g.set("a", 10)
    temp_map2 = g
    merged = %{}
    key = Map.keys(temp_map1)
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    value = Map.get(temp_map1, key)
    merged.set(key, value)
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
    key = Map.keys(temp_map2)
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    value = Map.get(temp_map2, key)
    merged.set(key, value)
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
    Log.trace("Merged maps:", %{"fileName" => "Main.hx", "lineNumber" => 184, "className" => "Main", "methodName" => "mapTransformations"})
    key = merged.keys()
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    Log.trace("  " <> key <> " => " <> Kernel.inspect(merged.get(key)), %{"fileName" => "Main.hx", "lineNumber" => 186, "className" => "Main", "methodName" => "mapTransformations"})
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

  @doc "Function enum_map"
  @spec enum_map() :: nil
  def enum_map() do
    map = Haxe.Ds.EnumValueMap.new()
    Map.put(map, :red, "FF0000")
    Map.put(map, :green, "00FF00")
    Map.put(map, :blue, "0000FF")
    Log.trace("Enum map:", %{"fileName" => "Main.hx", "lineNumber" => 198, "className" => "Main", "methodName" => "enumMap"})
    color = Map.keys(map)
    (
      loop_helper = fn loop_fn ->
        if (color.has_next()) do
          try do
            color = color.next()
    Log.trace("  " <> Std.string(color) <> " => #" <> Kernel.inspect(Map.get(map, color)), %{"fileName" => "Main.hx", "lineNumber" => 200, "className" => "Main", "methodName" => "enumMap"})
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
    if (Map.has_key?(map, :red)), do: Log.trace("Red color code: #" <> Kernel.inspect(Map.get(map, :red)), %{"fileName" => "Main.hx", "lineNumber" => 205, "className" => "Main", "methodName" => "enumMap"}), else: nil
  end

  @doc "Function process_map"
  @spec process_map(Map.t()) :: Map.t()
  def process_map(input) do
    result = %{}
    key = input.keys()
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    value = input.get(key)
    result.set(key, "Value: " <> Kernel.inspect(value))
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
    result
  end

  @doc "Function main"
  @spec main() :: nil
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
    g = %{}
    g.set("x", 10)
    g.set("y", 20)
    g.set("z", 30)
    output = Main.process_map(g)
    key = output.keys()
    (
      loop_helper = fn loop_fn ->
        if (key.has_next()) do
          try do
            key = key.next()
    Log.trace("" <> key <> ": " <> Kernel.inspect(output.get(key)), %{"fileName" => "Main.hx", "lineNumber" => 245, "className" => "Main", "methodName" => "main"})
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

end
