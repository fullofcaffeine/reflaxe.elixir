defmodule Main do
  def string_map() do
    map = %{}
    Map.put(map, "one", 1)
    Map.put(map, "two", 2)
    Map.put(map, "three", 3)
    Log.trace("Value of \"two\": " + Map.get(map, "two"), %{:fileName => "Main.hx", :lineNumber => 18, :className => "Main", :methodName => "stringMap"})
    Log.trace("Value of \"four\": " + Map.get(map, "four"), %{:fileName => "Main.hx", :lineNumber => 19, :className => "Main", :methodName => "stringMap"})
    Log.trace("Has \"one\": " + Std.string(Map.has_key?(map, "one")), %{:fileName => "Main.hx", :lineNumber => 22, :className => "Main", :methodName => "stringMap"})
    Log.trace("Has \"four\": " + Std.string(Map.has_key?(map, "four")), %{:fileName => "Main.hx", :lineNumber => 23, :className => "Main", :methodName => "stringMap"})
    Map.delete(map, "two")
    Log.trace("After remove, has \"two\": " + Std.string(Map.has_key?(map, "two")), %{:fileName => "Main.hx", :lineNumber => 27, :className => "Main", :methodName => "stringMap"})
    Log.trace("Iterating string map:", %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "stringMap"})
    key = Map.keys(map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (key.hasNext()) do
  key = key.next()
  Log.trace("  " + key + " => " + Map.get(map, key), %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "stringMap"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    map.clear()
    Log.trace("After clear, keys: " + Std.string(g = []
k = Map.keys(map)
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (k.hasNext()) do
  k = k.next()
  g.push(k)
  {:cont, acc}
else
  {:halt, acc}
end end)
g), %{:fileName => "Main.hx", :lineNumber => 37, :className => "Main", :methodName => "stringMap"})
  end
  def int_map() do
    map = %{}
    Map.put(map, 1, "first")
    Map.put(map, 2, "second")
    Map.put(map, 10, "tenth")
    Map.put(map, 100, "hundredth")
    Log.trace("Int map values:", %{:fileName => "Main.hx", :lineNumber => 49, :className => "Main", :methodName => "intMap"})
    key = Map.keys(map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (key.hasNext()) do
  key = key.next()
  Log.trace("  " + key + " => " + Map.get(map, key), %{:fileName => "Main.hx", :lineNumber => 51, :className => "Main", :methodName => "intMap"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    keys = g = []
k = Map.keys(map)
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (k.hasNext()) do
  k = k.next()
  g.push(k)
  {:cont, acc}
else
  {:halt, acc}
end end)
g
    values = g = []
k = Map.keys(map)
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (k.hasNext()) do
  k = k.next()
  g.push(Map.get(map, k))
  {:cont, acc}
else
  {:halt, acc}
end end)
g
    Log.trace("Keys: " + Std.string(keys), %{:fileName => "Main.hx", :lineNumber => 57, :className => "Main", :methodName => "intMap"})
    Log.trace("Values: " + Std.string(values), %{:fileName => "Main.hx", :lineNumber => 58, :className => "Main", :methodName => "intMap"})
  end
  def object_map() do
    map = %{}
    obj_1 = %{:id => 1}
    obj_2 = %{:id => 2}
    Map.put(map, obj, "Object 1")
    Map.put(map, obj, "Object 2")
    Log.trace("Object 1 value: " + Map.get(map, obj), %{:fileName => "Main.hx", :lineNumber => 71, :className => "Main", :methodName => "objectMap"})
    Log.trace("Object 2 value: " + Map.get(map, obj), %{:fileName => "Main.hx", :lineNumber => 72, :className => "Main", :methodName => "objectMap"})
    obj_3 = %{:id => 1}
    Log.trace("New {id: 1} value: " + Map.get(map, obj), %{:fileName => "Main.hx", :lineNumber => 76, :className => "Main", :methodName => "objectMap"})
  end
  def map_literals() do
    colors = g = %{}
Map.put(g, "red", 16711680)
Map.put(g, "green", 65280)
Map.put(g, "blue", 255)
g
    Log.trace("Color values:", %{:fileName => "Main.hx", :lineNumber => 88, :className => "Main", :methodName => "mapLiterals"})
    color = Map.keys(colors)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (color.hasNext()) do
  color = color.next()
  hex = StringTools.hex(Map.get(colors, color), 6)
  Log.trace("  " + color + " => #" + hex, %{:fileName => "Main.hx", :lineNumber => 91, :className => "Main", :methodName => "mapLiterals"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    squares = g = %{}
Map.put(g, 1, 1)
Map.put(g, 2, 4)
Map.put(g, 3, 9)
Map.put(g, 4, 16)
Map.put(g, 5, 25)
g
    Log.trace("Squares:", %{:fileName => "Main.hx", :lineNumber => 103, :className => "Main", :methodName => "mapLiterals"})
    n = Map.keys(squares)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (n.hasNext()) do
  n = n.next()
  Log.trace("  " + n + "² = " + Map.get(squares, n), %{:fileName => "Main.hx", :lineNumber => 105, :className => "Main", :methodName => "mapLiterals"})
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  def nested_maps() do
    users = %{}
    alice = %{}
    Map.put(alice, "age", 30)
    Map.put(alice, "email", "alice@example.com")
    Map.put(alice, "active", true)
    bob = %{}
    Map.put(bob, "age", 25)
    Map.put(bob, "email", "bob@example.com")
    Map.put(bob, "active", false)
    Map.put(users, "alice", alice)
    Map.put(users, "bob", bob)
    Log.trace("User data:", %{:fileName => "Main.hx", :lineNumber => 128, :className => "Main", :methodName => "nestedMaps"})
    username = Map.keys(users)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (username.hasNext()) do
  username = username.next()
  user_data = Map.get(users, username)
  Log.trace("  " + username + ":", %{:fileName => "Main.hx", :lineNumber => 131, :className => "Main", :methodName => "nestedMaps"})
  field = Map.keys(user_data)
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (field.hasNext()) do
  field = field.next()
  Log.trace("    " + field + ": " + Std.string(Map.get(user_data, field)), %{:fileName => "Main.hx", :lineNumber => 133, :className => "Main", :methodName => "nestedMaps"})
  {:cont, acc}
else
  {:halt, acc}
end end)
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  def map_transformations() do
    original = g = %{}
Map.put(g, "a", 1)
Map.put(g, "b", 2)
Map.put(g, "c", 3)
Map.put(g, "d", 4)
g
    doubled = %{}
    key = Map.keys(original)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (key.hasNext()) do
  key = key.next()
  value = Map.get(original, key) * 2
  Map.put(doubled, key, value)
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Doubled values:", %{:fileName => "Main.hx", :lineNumber => 153, :className => "Main", :methodName => "mapTransformations"})
    key = Map.keys(doubled)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (key.hasNext()) do
  key = key.next()
  Log.trace("  " + key + " => " + Map.get(doubled, key), %{:fileName => "Main.hx", :lineNumber => 155, :className => "Main", :methodName => "mapTransformations"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    filtered = %{}
    key = Map.keys(original)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (key.hasNext()) do
  key = key.next()
  value = Map.get(original, key)
  if (value > 2) do
    Map.put(filtered, key, value)
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Filtered (value > 2):", %{:fileName => "Main.hx", :lineNumber => 167, :className => "Main", :methodName => "mapTransformations"})
    key = Map.keys(filtered)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (key.hasNext()) do
  key = key.next()
  Log.trace("  " + key + " => " + Map.get(filtered, key), %{:fileName => "Main.hx", :lineNumber => 169, :className => "Main", :methodName => "mapTransformations"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    map_1 = g = %{}
Map.put(g, "a", 1)
Map.put(g, "b", 2)
g
    map_2 = g = %{}
Map.put(g, "c", 3)
Map.put(g, "d", 4)
Map.put(g, "a", 10)
g
    merged = %{}
    key = Map.keys(map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (key.hasNext()) do
  key = key.next()
  value = Map.get(map, key)
  Map.put(merged, key, value)
  {:cont, acc}
else
  {:halt, acc}
end end)
    key = Map.keys(map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (key.hasNext()) do
  key = key.next()
  value = Map.get(map, key)
  Map.put(merged, key, value)
  {:cont, acc}
else
  {:halt, acc}
end end)
    Log.trace("Merged maps:", %{:fileName => "Main.hx", :lineNumber => 184, :className => "Main", :methodName => "mapTransformations"})
    key = Map.keys(merged)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (key.hasNext()) do
  key = key.next()
  Log.trace("  " + key + " => " + Map.get(merged, key), %{:fileName => "Main.hx", :lineNumber => 186, :className => "Main", :methodName => "mapTransformations"})
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
  def enum_map() do
    map = %{}
    Map.put(map, :Red, "FF0000")
    Map.put(map, :Green, "00FF00")
    Map.put(map, :Blue, "0000FF")
    Log.trace("Enum map:", %{:fileName => "Main.hx", :lineNumber => 198, :className => "Main", :methodName => "enumMap"})
    color = Map.keys(map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (color.hasNext()) do
  color = {:ModuleRef}
  Log.trace("  " + Std.string(color) + " => #" + Map.get(map, color), %{:fileName => "Main.hx", :lineNumber => 200, :className => "Main", :methodName => "enumMap"})
  {:cont, acc}
else
  {:halt, acc}
end end)
    if (Map.has_key?(map, :Red)) do
      Log.trace("Red color code: #" + Map.get(map, :Red), %{:fileName => "Main.hx", :lineNumber => 205, :className => "Main", :methodName => "enumMap"})
    end
  end
  def process_map(input) do
    result = %{}
    key = Map.keys(input)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (key.hasNext()) do
  key = key.next()
  value = Map.get(input, key)
  Map.put(result, key, "Value: " + value)
  {:cont, acc}
else
  {:halt, acc}
end end)
    result
  end
  def main() do
    Log.trace("=== String Map ===", %{:fileName => "Main.hx", :lineNumber => 220, :className => "Main", :methodName => "main"})
    Main.string_map()
    Log.trace("\n=== Int Map ===", %{:fileName => "Main.hx", :lineNumber => 223, :className => "Main", :methodName => "main"})
    Main.int_map()
    Log.trace("\n=== Object Map ===", %{:fileName => "Main.hx", :lineNumber => 226, :className => "Main", :methodName => "main"})
    Main.object_map()
    Log.trace("\n=== Map Literals ===", %{:fileName => "Main.hx", :lineNumber => 229, :className => "Main", :methodName => "main"})
    Main.map_literals()
    Log.trace("\n=== Nested Maps ===", %{:fileName => "Main.hx", :lineNumber => 232, :className => "Main", :methodName => "main"})
    Main.nested_maps()
    Log.trace("\n=== Map Transformations ===", %{:fileName => "Main.hx", :lineNumber => 235, :className => "Main", :methodName => "main"})
    Main.map_transformations()
    Log.trace("\n=== Enum Map ===", %{:fileName => "Main.hx", :lineNumber => 238, :className => "Main", :methodName => "main"})
    Main.enum_map()
    Log.trace("\n=== Map Functions ===", %{:fileName => "Main.hx", :lineNumber => 241, :className => "Main", :methodName => "main"})
    input = g = %{}
Map.put(g, "x", 10)
Map.put(g, "y", 20)
Map.put(g, "z", 30)
g
    output = Main.process_map(input)
    key = Map.keys(output)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (key.hasNext()) do
  key = key.next()
  Log.trace("" + key + ": " + Map.get(output, key), %{:fileName => "Main.hx", :lineNumber => 245, :className => "Main", :methodName => "main"})
  {:cont, acc}
else
  {:halt, acc}
end end)
  end
end