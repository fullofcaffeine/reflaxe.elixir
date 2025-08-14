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
Log.trace("Value of \"two\": " <> map.get("two"), %{fileName: "Main.hx", lineNumber: 18, className: "Main", methodName: "stringMap"})
Log.trace("Value of \"four\": " <> map.get("four"), %{fileName: "Main.hx", lineNumber: 19, className: "Main", methodName: "stringMap"})
Log.trace("Has \"one\": " <> Std.string(map.exists("one")), %{fileName: "Main.hx", lineNumber: 22, className: "Main", methodName: "stringMap"})
Log.trace("Has \"four\": " <> Std.string(map.exists("four")), %{fileName: "Main.hx", lineNumber: 23, className: "Main", methodName: "stringMap"})
map.remove("two")
Log.trace("After remove, has \"two\": " <> Std.string(map.exists("two")), %{fileName: "Main.hx", lineNumber: 27, className: "Main", methodName: "stringMap"})
Log.trace("Iterating string map:", %{fileName: "Main.hx", lineNumber: 30, className: "Main", methodName: "stringMap"})
key = map.keys()
(fn loop_fn ->
  if (key.hasNext()) do
    key2 = key.next()
Log.trace("  " <> key2 <> " => " <> map.get(key2), %{fileName: "Main.hx", lineNumber: 32, className: "Main", methodName: "stringMap"})
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
map.clear()
temp_array = nil
_g = []
k = map.keys()
(fn loop_fn ->
  if (k.hasNext()) do
    k2 = k.next()
_g ++ [k2]
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
temp_array = _g
Log.trace("After clear, keys: " <> Std.string(temp_array), %{fileName: "Main.hx", lineNumber: 37, className: "Main", methodName: "stringMap"})
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
(fn loop_fn ->
  if (key.hasNext()) do
    key2 = key.next()
Log.trace("  " <> key2 <> " => " <> map.get(key2), %{fileName: "Main.hx", lineNumber: 51, className: "Main", methodName: "intMap"})
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
temp_array = nil
_g = []
k = map.keys()
(fn loop_fn ->
  if (k.hasNext()) do
    k2 = k.next()
_g ++ [k2]
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
temp_array = _g
keys = temp_array
temp_array1 = nil
_g = []
k = map.keys()
(fn loop_fn ->
  if (k.hasNext()) do
    k2 = k.next()
_g ++ [map.get(k2)]
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
temp_array1 = _g
values = temp_array1
Log.trace("Keys: " <> Std.string(keys), %{fileName: "Main.hx", lineNumber: 57, className: "Main", methodName: "intMap"})
Log.trace("Values: " <> Std.string(values), %{fileName: "Main.hx", lineNumber: 58, className: "Main", methodName: "intMap"})
  end

  @doc "Function object_map"
  @spec object_map() :: nil
  def object_map() do
    map = Haxe.Ds.ObjectMap.new()
obj1 = %{id: 1}
obj2 = %{id: 2}
map.set(obj1, "Object 1")
map.set(obj2, "Object 2")
Log.trace("Object 1 value: " <> map.get(obj1), %{fileName: "Main.hx", lineNumber: 71, className: "Main", methodName: "objectMap"})
Log.trace("Object 2 value: " <> map.get(obj2), %{fileName: "Main.hx", lineNumber: 72, className: "Main", methodName: "objectMap"})
obj3 = %{id: 1}
Log.trace("New {id: 1} value: " <> map.get(obj3), %{fileName: "Main.hx", lineNumber: 76, className: "Main", methodName: "objectMap"})
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
colors = temp_map
Log.trace("Color values:", %{fileName: "Main.hx", lineNumber: 88, className: "Main", methodName: "mapLiterals"})
color = colors.keys()
(fn loop_fn ->
  if (color.hasNext()) do
    color2 = color.next()
hex = StringTools.hex(colors.get(color2), 6)
Log.trace("  " <> color2 <> " => #" <> hex, %{fileName: "Main.hx", lineNumber: 91, className: "Main", methodName: "mapLiterals"})
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
temp_map1 = nil
_g = Haxe.Ds.IntMap.new()
_g.set(1, 1)
_g.set(2, 4)
_g.set(3, 9)
_g.set(4, 16)
_g.set(5, 25)
temp_map1 = _g
squares = temp_map1
Log.trace("Squares:", %{fileName: "Main.hx", lineNumber: 103, className: "Main", methodName: "mapLiterals"})
n = squares.keys()
(fn loop_fn ->
  if (n.hasNext()) do
    n2 = n.next()
Log.trace("  " <> n2 <> "² = " <> squares.get(n2), %{fileName: "Main.hx", lineNumber: 105, className: "Main", methodName: "mapLiterals"})
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
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
(fn loop_fn ->
  if (username.hasNext()) do
    username2 = username.next()
user_data = users.get(username2)
Log.trace("  " <> username2 <> ":", %{fileName: "Main.hx", lineNumber: 131, className: "Main", methodName: "nestedMaps"})
field = user_data.keys()
(fn loop_fn ->
  if (field.hasNext()) do
    field2 = field.next()
Log.trace("    " <> field2 <> ": " <> Std.string(user_data.get(field2)), %{fileName: "Main.hx", lineNumber: 133, className: "Main", methodName: "nestedMaps"})
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
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
original = temp_map
doubled = Haxe.Ds.StringMap.new()
key = original.keys()
(fn loop_fn ->
  if (key.hasNext()) do
    key2 = key.next()
value = original.get(key2) * 2
doubled.set(key2, value)
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
Log.trace("Doubled values:", %{fileName: "Main.hx", lineNumber: 153, className: "Main", methodName: "mapTransformations"})
key = doubled.keys()
(fn loop_fn ->
  if (key.hasNext()) do
    key2 = key.next()
Log.trace("  " <> key2 <> " => " <> doubled.get(key2), %{fileName: "Main.hx", lineNumber: 155, className: "Main", methodName: "mapTransformations"})
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
filtered = Haxe.Ds.StringMap.new()
key = original.keys()
(fn loop_fn ->
  if (key.hasNext()) do
    key2 = key.next()
value = original.get(key2)
if (value > 2), do: filtered.set(key2, value), else: nil
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
Log.trace("Filtered (value > 2):", %{fileName: "Main.hx", lineNumber: 167, className: "Main", methodName: "mapTransformations"})
key = filtered.keys()
(fn loop_fn ->
  if (key.hasNext()) do
    key2 = key.next()
Log.trace("  " <> key2 <> " => " <> filtered.get(key2), %{fileName: "Main.hx", lineNumber: 169, className: "Main", methodName: "mapTransformations"})
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
temp_map1 = nil
_g = Haxe.Ds.StringMap.new()
_g.set("a", 1)
_g.set("b", 2)
temp_map1 = _g
map1 = temp_map1
temp_map2 = nil
_g = Haxe.Ds.StringMap.new()
_g.set("c", 3)
_g.set("d", 4)
_g.set("a", 10)
temp_map2 = _g
map2 = temp_map2
merged = Haxe.Ds.StringMap.new()
key = map1.keys()
(fn loop_fn ->
  if (key.hasNext()) do
    key2 = key.next()
value = map1.get(key2)
merged.set(key2, value)
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
key = map2.keys()
(fn loop_fn ->
  if (key.hasNext()) do
    key2 = key.next()
value = map2.get(key2)
merged.set(key2, value)
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
Log.trace("Merged maps:", %{fileName: "Main.hx", lineNumber: 184, className: "Main", methodName: "mapTransformations"})
key = merged.keys()
(fn loop_fn ->
  if (key.hasNext()) do
    key2 = key.next()
Log.trace("  " <> key2 <> " => " <> merged.get(key2), %{fileName: "Main.hx", lineNumber: 186, className: "Main", methodName: "mapTransformations"})
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
  end

  @doc "Function enum_map"
  @spec enum_map() :: nil
  def enum_map() do
    map = Haxe.Ds.EnumValueMap.new()
map.set(Color.red(), "FF0000")
map.set(Color.green(), "00FF00")
map.set(Color.blue(), "0000FF")
Log.trace("Enum map:", %{fileName: "Main.hx", lineNumber: 198, className: "Main", methodName: "enumMap"})
color = map.keys()
(fn loop_fn ->
  if (color.hasNext()) do
    color2 = color.next()
Log.trace("  " <> Std.string(color2) <> " => #" <> map.get(color2), %{fileName: "Main.hx", lineNumber: 200, className: "Main", methodName: "enumMap"})
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
if (map.exists(Color.red())), do: Log.trace("Red color code: #" <> map.get(Color.red()), %{fileName: "Main.hx", lineNumber: 205, className: "Main", methodName: "enumMap"}), else: nil
  end

  @doc "Function process_map"
  @spec process_map(Map.t()) :: Map.t()
  def process_map(arg0) do
    result = Haxe.Ds.StringMap.new()
key = arg0.keys()
(fn loop_fn ->
  if (key.hasNext()) do
    key2 = key.next()
value = arg0.get(key2)
result.set(key2, "Value: " <> value)
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
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
temp_map = nil
_g = Haxe.Ds.StringMap.new()
_g.set("x", 10)
_g.set("y", 20)
_g.set("z", 30)
temp_map = _g
input = temp_map
output = Main.processMap(input)
key = output.keys()
(fn loop_fn ->
  if (key.hasNext()) do
    key2 = key.next()
Log.trace("" <> key2 <> ": " <> output.get(key2), %{fileName: "Main.hx", lineNumber: 245, className: "Main", methodName: "main"})
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
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
