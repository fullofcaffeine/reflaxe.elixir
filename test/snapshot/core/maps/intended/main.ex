defmodule Main do
  def string_map() do
    map = %{}
    map = Map.put(map, "one", 1)
    map = Map.put(map, "two", 2)
    map = Map.put(map, "three", 3)
    Log.trace("Value of \"two\": " <> Map.get(map, "two"), %{:fileName => "Main.hx", :lineNumber => 18, :className => "Main", :methodName => "stringMap"})
    Log.trace("Value of \"four\": " <> Map.get(map, "four"), %{:fileName => "Main.hx", :lineNumber => 19, :className => "Main", :methodName => "stringMap"})
    Log.trace("Has \"one\": " <> Std.string(Map.has_key?(map, "one")), %{:fileName => "Main.hx", :lineNumber => 22, :className => "Main", :methodName => "stringMap"})
    Log.trace("Has \"four\": " <> Std.string(Map.has_key?(map, "four")), %{:fileName => "Main.hx", :lineNumber => 23, :className => "Main", :methodName => "stringMap"})
    map = Map.delete(map, "two")
    Log.trace("After remove, has \"two\": " <> Std.string(Map.has_key?(map, "two")), %{:fileName => "Main.hx", :lineNumber => 27, :className => "Main", :methodName => "stringMap"})
    Log.trace("Iterating string map:", %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "stringMap"})
    key = Map.keys(map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    Log.trace("  " <> acc_key <> " => " <> Map.get(map, acc_key), %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "stringMap"})
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
    map.clear()
    g = []
    k = Map.keys(map)
    Log.trace("After clear, keys: " <> Std.string(Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} ->
  if acc_k.hasNext() do
    g ++ [acc_k]
    {:cont, {acc_k, acc_state}}
  else
    {:halt, {acc_k, acc_state}}
  end
end)
g), %{:fileName => "Main.hx", :lineNumber => 37, :className => "Main", :methodName => "stringMap"})
  end
  def int_map() do
    map = %{}
    map = Map.put(map, 1, "first")
    map = Map.put(map, 2, "second")
    map = Map.put(map, 10, "tenth")
    map = Map.put(map, 100, "hundredth")
    Log.trace("Int map values:", %{:fileName => "Main.hx", :lineNumber => 49, :className => "Main", :methodName => "intMap"})
    key = Map.keys(map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    Log.trace("  " <> acc_key <> " => " <> Map.get(map, acc_key), %{:fileName => "Main.hx", :lineNumber => 51, :className => "Main", :methodName => "intMap"})
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
    g = []
    k = Map.keys(map)
    keys = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} ->
  if (acc_k.hasNext()) do
    g ++ [acc_k]
    {:cont, {acc_k, acc_state}}
  else
    {:halt, {acc_k, acc_state}}
  end
end)
g
    g = []
    k = Map.keys(map)
    values = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} ->
  if (acc_k.hasNext()) do
    g ++ [Map.get(map, acc_k)]
    {:cont, {acc_k, acc_state}}
  else
    {:halt, {acc_k, acc_state}}
  end
end)
g
    Log.trace("Keys: " <> Std.string(keys), %{:fileName => "Main.hx", :lineNumber => 57, :className => "Main", :methodName => "intMap"})
    Log.trace("Values: " <> Std.string(values), %{:fileName => "Main.hx", :lineNumber => 58, :className => "Main", :methodName => "intMap"})
  end
  def object_map() do
    map = %{}
    obj1 = %{:id => 1}
    obj2 = %{:id => 2}
    map = Map.put(map, obj1, "Object 1")
    map = Map.put(map, obj2, "Object 2")
    Log.trace("Object 1 value: " <> Map.get(map, obj1), %{:fileName => "Main.hx", :lineNumber => 71, :className => "Main", :methodName => "objectMap"})
    Log.trace("Object 2 value: " <> Map.get(map, obj2), %{:fileName => "Main.hx", :lineNumber => 72, :className => "Main", :methodName => "objectMap"})
    obj3 = %{:id => 1}
    Log.trace("New {id: 1} value: " <> Map.get(map, obj3), %{:fileName => "Main.hx", :lineNumber => 76, :className => "Main", :methodName => "objectMap"})
  end
  def map_literals() do
    g = %{}
    g = Map.put(g, "red", 16711680)
    g = Map.put(g, "green", 65280)
    g = Map.put(g, "blue", 255)
    colors = g
    Log.trace("Color values:", %{:fileName => "Main.hx", :lineNumber => 88, :className => "Main", :methodName => "mapLiterals"})
    color = Map.keys(colors)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {color, :ok}, fn _, {acc_color, acc_state} ->
  if (acc_color.hasNext()) do
    acc_color = acc_color.next()
    hex = StringTools.hex(Map.get(colors, acc_color), 6)
    Log.trace("  " <> acc_color <> " => #" <> hex, %{:fileName => "Main.hx", :lineNumber => 91, :className => "Main", :methodName => "mapLiterals"})
    {:cont, {acc_color, acc_state}}
  else
    {:halt, {acc_color, acc_state}}
  end
end)
    g = %{}
    g = Map.put(g, 1, 1)
    g = Map.put(g, 2, 4)
    g = Map.put(g, 3, 9)
    g = Map.put(g, 4, 16)
    g = Map.put(g, 5, 25)
    squares = g
    Log.trace("Squares:", %{:fileName => "Main.hx", :lineNumber => 103, :className => "Main", :methodName => "mapLiterals"})
    n = Map.keys(squares)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {n, :ok}, fn _, {acc_n, acc_state} ->
  if (acc_n.hasNext()) do
    acc_n = acc_n.next()
    Log.trace("  " <> acc_n <> "² = " <> Map.get(squares, acc_n), %{:fileName => "Main.hx", :lineNumber => 105, :className => "Main", :methodName => "mapLiterals"})
    {:cont, {acc_n, acc_state}}
  else
    {:halt, {acc_n, acc_state}}
  end
end)
  end
  def nested_maps() do
    users = %{}
    alice = %{}
    alice = Map.put(alice, "age", 30)
    alice = Map.put(alice, "email", "alice@example.com")
    alice = Map.put(alice, "active", true)
    bob = %{}
    bob = Map.put(bob, "age", 25)
    bob = Map.put(bob, "email", "bob@example.com")
    bob = Map.put(bob, "active", false)
    users = Map.put(users, "alice", alice)
    users = Map.put(users, "bob", bob)
    Log.trace("User data:", %{:fileName => "Main.hx", :lineNumber => 128, :className => "Main", :methodName => "nestedMaps"})
    username = Map.keys(users)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {username, :ok}, fn _, {acc_username, acc_state} ->
  if (acc_username.hasNext()) do
    acc_username = acc_username.next()
    user_data = Map.get(users, acc_username)
    Log.trace("  " <> acc_username <> ":", %{:fileName => "Main.hx", :lineNumber => 131, :className => "Main", :methodName => "nestedMaps"})
    field = Map.keys(user_data)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {field, :ok}, fn _, {acc_field, acc_state} ->
  if (acc_field.hasNext()) do
    acc_field = acc_field.next()
    Log.trace("    " <> acc_field <> ": " <> Std.string(Map.get(user_data, acc_field)), %{:fileName => "Main.hx", :lineNumber => 133, :className => "Main", :methodName => "nestedMaps"})
    {:cont, {acc_field, acc_state}}
  else
    {:halt, {acc_field, acc_state}}
  end
end)
    {:cont, {acc_username, acc_state}}
  else
    {:halt, {acc_username, acc_state}}
  end
end)
  end
  def map_transformations() do
    g = %{}
    g = Map.put(g, "a", 1)
    g = Map.put(g, "b", 2)
    g = Map.put(g, "c", 3)
    g = Map.put(g, "d", 4)
    original = g
    doubled = %{}
    key = Map.keys(original)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    value = Map.get(original, acc_key) * 2
    Map.put(doubled, acc_key, value)
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
    Log.trace("Doubled values:", %{:fileName => "Main.hx", :lineNumber => 153, :className => "Main", :methodName => "mapTransformations"})
    key = Map.keys(doubled)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    Log.trace("  " <> acc_key <> " => " <> Map.get(doubled, acc_key), %{:fileName => "Main.hx", :lineNumber => 155, :className => "Main", :methodName => "mapTransformations"})
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
    filtered = %{}
    key = Map.keys(original)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    value = Map.get(original, acc_key)
    if (value > 2) do
      Map.put(filtered, acc_key, value)
    end
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
    Log.trace("Filtered (value > 2):", %{:fileName => "Main.hx", :lineNumber => 167, :className => "Main", :methodName => "mapTransformations"})
    key = Map.keys(filtered)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    Log.trace("  " <> acc_key <> " => " <> Map.get(filtered, acc_key), %{:fileName => "Main.hx", :lineNumber => 169, :className => "Main", :methodName => "mapTransformations"})
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
    g = %{}
    g = Map.put(g, "a", 1)
    g = Map.put(g, "b", 2)
    map1 = g
    g = %{}
    g = Map.put(g, "c", 3)
    g = Map.put(g, "d", 4)
    g = Map.put(g, "a", 10)
    map2 = g
    merged = %{}
    key = Map.keys(map1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    value = Map.get(map1, acc_key)
    Map.put(merged, acc_key, value)
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
    key = Map.keys(map2)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    value = Map.get(map2, acc_key)
    Map.put(merged, acc_key, value)
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
    Log.trace("Merged maps:", %{:fileName => "Main.hx", :lineNumber => 184, :className => "Main", :methodName => "mapTransformations"})
    key = Map.keys(merged)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    Log.trace("  " <> acc_key <> " => " <> Map.get(merged, acc_key), %{:fileName => "Main.hx", :lineNumber => 186, :className => "Main", :methodName => "mapTransformations"})
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
  end
  def enum_map() do
    map = %{}
    map = Map.put(map, :red, "FF0000")
    map = Map.put(map, :green, "00FF00")
    map = Map.put(map, :blue, "0000FF")
    Log.trace("Enum map:", %{:fileName => "Main.hx", :lineNumber => 198, :className => "Main", :methodName => "enumMap"})
    color = Map.keys(map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {color, :ok}, fn _, {acc_color, acc_state} ->
  if (acc_color.hasNext()) do
    acc_color = {:ModuleRef}
    Log.trace("  " <> Std.string(acc_color) <> " => #" <> Map.get(map, acc_color), %{:fileName => "Main.hx", :lineNumber => 200, :className => "Main", :methodName => "enumMap"})
    {:cont, {acc_color, acc_state}}
  else
    {:halt, {acc_color, acc_state}}
  end
end)
    if (Map.has_key?(map, :red)) do
      Log.trace("Red color code: #" <> Map.get(map, :red), %{:fileName => "Main.hx", :lineNumber => 205, :className => "Main", :methodName => "enumMap"})
    end
  end
  def process_map(input) do
    result = %{}
    key = Map.keys(input)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    value = Map.get(input, acc_key)
    Map.put(result, acc_key, "Value: " <> value)
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
    result
  end
  def main() do
    Log.trace("=== String Map ===", %{:fileName => "Main.hx", :lineNumber => 220, :className => "Main", :methodName => "main"})
    string_map()
    Log.trace("\n=== Int Map ===", %{:fileName => "Main.hx", :lineNumber => 223, :className => "Main", :methodName => "main"})
    int_map()
    Log.trace("\n=== Object Map ===", %{:fileName => "Main.hx", :lineNumber => 226, :className => "Main", :methodName => "main"})
    object_map()
    Log.trace("\n=== Map Literals ===", %{:fileName => "Main.hx", :lineNumber => 229, :className => "Main", :methodName => "main"})
    map_literals()
    Log.trace("\n=== Nested Maps ===", %{:fileName => "Main.hx", :lineNumber => 232, :className => "Main", :methodName => "main"})
    nested_maps()
    Log.trace("\n=== Map Transformations ===", %{:fileName => "Main.hx", :lineNumber => 235, :className => "Main", :methodName => "main"})
    map_transformations()
    Log.trace("\n=== Enum Map ===", %{:fileName => "Main.hx", :lineNumber => 238, :className => "Main", :methodName => "main"})
    enum_map()
    Log.trace("\n=== Map Functions ===", %{:fileName => "Main.hx", :lineNumber => 241, :className => "Main", :methodName => "main"})
    g = %{}
    g = Map.put(g, "x", 10)
    g = Map.put(g, "y", 20)
    g = Map.put(g, "z", 30)
    input = g
    output = process_map(input)
    key = Map.keys(output)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} ->
  if (acc_key.hasNext()) do
    acc_key = acc_key.next()
    Log.trace("" <> acc_key <> ": " <> Map.get(output, acc_key), %{:fileName => "Main.hx", :lineNumber => 245, :className => "Main", :methodName => "main"})
    {:cont, {acc_key, acc_state}}
  else
    {:halt, {acc_key, acc_state}}
  end
end)
  end
end