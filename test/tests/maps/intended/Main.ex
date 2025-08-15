defmodule Main do
  use Bitwise
  @moduledoc """
  Main module generated from Haxe
  
  
 * Map/Dictionary test case
 * Tests various map types and operations
 
  """

  # Static functions
  @doc "Function string_map"
  @spec string_map() :: nil
  def string_map() do
    map = Haxe.Ds.StringMap.new()
    map.set("one", 1)
    map.set("two", 2)
    map.set("three", 3)
    Log.trace("Value of \"two\": " <> Kernel.inspect(map.get("two")), %{fileName: "Main.hx", lineNumber: 18, className: "Main", methodName: "stringMap"})
    Log.trace("Value of \"four\": " <> Kernel.inspect(map.get("four")), %{fileName: "Main.hx", lineNumber: 19, className: "Main", methodName: "stringMap"})
    Log.trace("Has \"one\": " <> Std.string(map.exists("one")), %{fileName: "Main.hx", lineNumber: 22, className: "Main", methodName: "stringMap"})
    Log.trace("Has \"four\": " <> Std.string(map.exists("four")), %{fileName: "Main.hx", lineNumber: 23, className: "Main", methodName: "stringMap"})
    map.remove("two")
    Log.trace("After remove, has \"two\": " <> Std.string(map.exists("two")), %{fileName: "Main.hx", lineNumber: 27, className: "Main", methodName: "stringMap"})
    Log.trace("Iterating string map:", %{fileName: "Main.hx", lineNumber: 30, className: "Main", methodName: "stringMap"})
    key = map.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    Log.trace("  " <> key <> " => " <> Kernel.inspect(map.get(key)), %{fileName: "Main.hx", lineNumber: 32, className: "Main", methodName: "stringMap"})
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    map.clear()
    _g = []
    k = map.keys()
    (
      try do
        loop_fn = fn ->
          if (k.hasNext()) do
            try do
              k = k.next()
    _g ++ [k]
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    Log.trace("After clear, keys: " <> Std.string(_g), %{fileName: "Main.hx", lineNumber: 37, className: "Main", methodName: "stringMap"})
  end

  @doc "Function int_map"
  @spec int_map() :: nil
  def int_map() do
    map = Haxe.Ds.IntMap.new()
    map.set(1, "first")
    map.set(2, "second")
    map.set(10, "tenth")
    map.set(100, "hundredth")
    Log.trace("Int map values:", %{fileName: "Main.hx", lineNumber: 49, className: "Main", methodName: "intMap"})
    key = map.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    Log.trace("  " <> Integer.to_string(key) <> " => " <> Kernel.inspect(map.get(key)), %{fileName: "Main.hx", lineNumber: 51, className: "Main", methodName: "intMap"})
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    temp_array = nil
    _g = []
    k = map.keys()
    (
      try do
        loop_fn = fn ->
          if (k.hasNext()) do
            try do
              k = k.next()
    _g ++ [k]
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    temp_array = _g
    temp_array1 = nil
    _g = []
    k = map.keys()
    (
      try do
        loop_fn = fn ->
          if (k.hasNext()) do
            try do
              k = k.next()
    _g ++ [map.get(k)]
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    temp_array1 = _g
    Log.trace("Keys: " <> Std.string(temp_array), %{fileName: "Main.hx", lineNumber: 57, className: "Main", methodName: "intMap"})
    Log.trace("Values: " <> Std.string(temp_array1), %{fileName: "Main.hx", lineNumber: 58, className: "Main", methodName: "intMap"})
  end

  @doc "Function object_map"
  @spec object_map() :: nil
  def object_map() do
    map = Haxe.Ds.ObjectMap.new()
    obj1 = %{id: 1}
    obj2 = %{id: 2}
    map.set(obj1, "Object 1")
    map.set(obj2, "Object 2")
    Log.trace("Object 1 value: " <> Kernel.inspect(map.get(obj1)), %{fileName: "Main.hx", lineNumber: 71, className: "Main", methodName: "objectMap"})
    Log.trace("Object 2 value: " <> Kernel.inspect(map.get(obj2)), %{fileName: "Main.hx", lineNumber: 72, className: "Main", methodName: "objectMap"})
    obj3 = %{id: 1}
    Log.trace("New {id: 1} value: " <> Kernel.inspect(map.get(obj3)), %{fileName: "Main.hx", lineNumber: 76, className: "Main", methodName: "objectMap"})
  end

  @doc "Function map_literals"
  @spec map_literals() :: nil
  def map_literals() do
    temp_map = nil
    _g = Haxe.Ds.StringMap.new()
    _g.set("red", 16711680)
    _g.set("green", 65280)
    _g.set("blue", 255)
    temp_map = _g
    Log.trace("Color values:", %{fileName: "Main.hx", lineNumber: 88, className: "Main", methodName: "mapLiterals"})
    color = temp_map.keys()
    (
      try do
        loop_fn = fn ->
          if (color.hasNext()) do
            try do
              color = color.next()
    hex = StringTools.hex(temp_map.get(color), 6)
    Log.trace("  " <> color <> " => #" <> hex, %{fileName: "Main.hx", lineNumber: 91, className: "Main", methodName: "mapLiterals"})
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    temp_map1 = nil
    _g = Haxe.Ds.IntMap.new()
    _g.set(1, 1)
    _g.set(2, 4)
    _g.set(3, 9)
    _g.set(4, 16)
    _g.set(5, 25)
    temp_map1 = _g
    Log.trace("Squares:", %{fileName: "Main.hx", lineNumber: 103, className: "Main", methodName: "mapLiterals"})
    n = temp_map1.keys()
    (
      try do
        loop_fn = fn ->
          if (n.hasNext()) do
            try do
              n = n.next()
    Log.trace("  " <> Integer.to_string(n) <> "² = " <> Kernel.inspect(temp_map1.get(n)), %{fileName: "Main.hx", lineNumber: 105, className: "Main", methodName: "mapLiterals"})
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
  end

  @doc "Function nested_maps"
  @spec nested_maps() :: nil
  def nested_maps() do
    users = Haxe.Ds.StringMap.new()
    alice = Haxe.Ds.StringMap.new()
    alice.set("age", 30)
    alice.set("email", "alice@example.com")
    alice.set("active", true)
    bob = Haxe.Ds.StringMap.new()
    bob.set("age", 25)
    bob.set("email", "bob@example.com")
    bob.set("active", false)
    users.set("alice", alice)
    users.set("bob", bob)
    Log.trace("User data:", %{fileName: "Main.hx", lineNumber: 128, className: "Main", methodName: "nestedMaps"})
    username = users.keys()
    (
      try do
        loop_fn = fn ->
          if (username.hasNext()) do
            try do
              username = username.next()
    user_data = users.get(username)
    Log.trace("  " <> username <> ":", %{fileName: "Main.hx", lineNumber: 131, className: "Main", methodName: "nestedMaps"})
    field = user_data.keys()
    (
      try do
        loop_fn = fn ->
          if (field.hasNext()) do
            try do
              field = field.next()
    Log.trace("    " <> field <> ": " <> Std.string(user_data.get(field)), %{fileName: "Main.hx", lineNumber: 133, className: "Main", methodName: "nestedMaps"})
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
  end

  @doc "Function map_transformations"
  @spec map_transformations() :: nil
  def map_transformations() do
    temp_map = nil
    _g = Haxe.Ds.StringMap.new()
    _g.set("a", 1)
    _g.set("b", 2)
    _g.set("c", 3)
    _g.set("d", 4)
    temp_map = _g
    doubled = Haxe.Ds.StringMap.new()
    key = temp_map.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    value = temp_map.get(key) * 2
    doubled.set(key, value)
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    Log.trace("Doubled values:", %{fileName: "Main.hx", lineNumber: 153, className: "Main", methodName: "mapTransformations"})
    key = doubled.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    Log.trace("  " <> key <> " => " <> Kernel.inspect(doubled.get(key)), %{fileName: "Main.hx", lineNumber: 155, className: "Main", methodName: "mapTransformations"})
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    filtered = Haxe.Ds.StringMap.new()
    key = temp_map.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    value = temp_map.get(key)
    if (value > 2), do: filtered.set(key, value), else: nil
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    Log.trace("Filtered (value > 2):", %{fileName: "Main.hx", lineNumber: 167, className: "Main", methodName: "mapTransformations"})
    key = filtered.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    Log.trace("  " <> key <> " => " <> Kernel.inspect(filtered.get(key)), %{fileName: "Main.hx", lineNumber: 169, className: "Main", methodName: "mapTransformations"})
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    temp_map1 = nil
    _g = Haxe.Ds.StringMap.new()
    _g.set("a", 1)
    _g.set("b", 2)
    temp_map1 = _g
    temp_map2 = nil
    _g = Haxe.Ds.StringMap.new()
    _g.set("c", 3)
    _g.set("d", 4)
    _g.set("a", 10)
    temp_map2 = _g
    merged = Haxe.Ds.StringMap.new()
    key = temp_map1.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    value = temp_map1.get(key)
    merged.set(key, value)
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    key = temp_map2.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    value = temp_map2.get(key)
    merged.set(key, value)
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    Log.trace("Merged maps:", %{fileName: "Main.hx", lineNumber: 184, className: "Main", methodName: "mapTransformations"})
    key = merged.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    Log.trace("  " <> key <> " => " <> Kernel.inspect(merged.get(key)), %{fileName: "Main.hx", lineNumber: 186, className: "Main", methodName: "mapTransformations"})
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
  end

  @doc "Function enum_map"
  @spec enum_map() :: nil
  def enum_map() do
    map = Haxe.Ds.EnumValueMap.new()
    map.set(:red, "FF0000")
    map.set(:green, "00FF00")
    map.set(:blue, "0000FF")
    Log.trace("Enum map:", %{fileName: "Main.hx", lineNumber: 198, className: "Main", methodName: "enumMap"})
    color = map.keys()
    (
      try do
        loop_fn = fn ->
          if (color.hasNext()) do
            try do
              color = color.next()
    Log.trace("  " <> Std.string(color) <> " => #" <> Kernel.inspect(map.get(color)), %{fileName: "Main.hx", lineNumber: 200, className: "Main", methodName: "enumMap"})
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    if (map.exists(:red)), do: Log.trace("Red color code: #" <> Kernel.inspect(map.get(:red)), %{fileName: "Main.hx", lineNumber: 205, className: "Main", methodName: "enumMap"}), else: nil
  end

  @doc "Function process_map"
  @spec process_map(Map.t()) :: Map.t()
  def process_map(input) do
    result = Haxe.Ds.StringMap.new()
    key = input.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    value = input.get(key)
    result.set(key, "Value: " <> Kernel.inspect(value))
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    result
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("=== String Map ===", %{fileName: "Main.hx", lineNumber: 220, className: "Main", methodName: "main"})
    Main.stringMap()
    Log.trace("\n=== Int Map ===", %{fileName: "Main.hx", lineNumber: 223, className: "Main", methodName: "main"})
    Main.intMap()
    Log.trace("\n=== Object Map ===", %{fileName: "Main.hx", lineNumber: 226, className: "Main", methodName: "main"})
    Main.objectMap()
    Log.trace("\n=== Map Literals ===", %{fileName: "Main.hx", lineNumber: 229, className: "Main", methodName: "main"})
    Main.mapLiterals()
    Log.trace("\n=== Nested Maps ===", %{fileName: "Main.hx", lineNumber: 232, className: "Main", methodName: "main"})
    Main.nestedMaps()
    Log.trace("\n=== Map Transformations ===", %{fileName: "Main.hx", lineNumber: 235, className: "Main", methodName: "main"})
    Main.mapTransformations()
    Log.trace("\n=== Enum Map ===", %{fileName: "Main.hx", lineNumber: 238, className: "Main", methodName: "main"})
    Main.enumMap()
    Log.trace("\n=== Map Functions ===", %{fileName: "Main.hx", lineNumber: 241, className: "Main", methodName: "main"})
    _g = Haxe.Ds.StringMap.new()
    _g.set("x", 10)
    _g.set("y", 20)
    _g.set("z", 30)
    output = Main.processMap(_g)
    key = output.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    Log.trace("" <> key <> ": " <> Kernel.inspect(output.get(key)), %{fileName: "Main.hx", lineNumber: 245, className: "Main", methodName: "main"})
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
  end

end


defmodule Color do
  @moduledoc """
  Color enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :red |
    :green |
    :blue

  @doc "Creates red enum value"
  @spec red() :: :red
  def red(), do: :red

  @doc "Creates green enum value"
  @spec green() :: :green
  def green(), do: :green

  @doc "Creates blue enum value"
  @spec blue() :: :blue
  def blue(), do: :blue

  # Predicate functions for pattern matching
  @doc "Returns true if value is red variant"
  @spec is_red(t()) :: boolean()
  def is_red(:red), do: true
  def is_red(_), do: false

  @doc "Returns true if value is green variant"
  @spec is_green(t()) :: boolean()
  def is_green(:green), do: true
  def is_green(_), do: false

  @doc "Returns true if value is blue variant"
  @spec is_blue(t()) :: boolean()
  def is_blue(:blue), do: true
  def is_blue(_), do: false

end
