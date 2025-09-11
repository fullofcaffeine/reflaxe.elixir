defmodule Main do
  def string_map() do
    map = %{}
    map = Map.put(map, "one", 1)
    map = Map.put(map, "two", 2)
    map = Map.put(map, "three", 3)
    Log.trace("Value of \"two\": " <> Kernel.to_string(Map.get(map, "two")), %{:file_name => "Main.hx", :line_number => 18, :class_name => "Main", :method_name => "stringMap"})
    Log.trace("Value of \"four\": " <> Kernel.to_string(Map.get(map, "four")), %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "stringMap"})
    Log.trace("Has \"one\": " <> Std.string(Map.has_key?(map, "one")), %{:file_name => "Main.hx", :line_number => 22, :class_name => "Main", :method_name => "stringMap"})
    Log.trace("Has \"four\": " <> Std.string(Map.has_key?(map, "four")), %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "stringMap"})
    map = Map.delete(map, "two")
    Log.trace("After remove, has \"two\": " <> Std.string(Map.has_key?(map, "two")), %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "stringMap"})
    Log.trace("Iterating string map:", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "stringMap"})
    key = Map.keys(map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
    map.clear()
    g = []
    k = Map.keys(map)
    Log.trace("After clear, keys: " <> Std.string(Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} ->
  if (acc_k.has_next()) do
    g = g ++ [(acc_k.next())]
    {:cont, {acc_k, acc_state}}
  else
    {:halt, {acc_k, acc_state}}
  end
end)
g), %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "stringMap"})
  end
  def int_map() do
    map = %{}
    map = Map.put(map, 1, "first")
    map = Map.put(map, 2, "second")
    map = Map.put(map, 10, "tenth")
    map = Map.put(map, 100, "hundredth")
    Log.trace("Int map values:", %{:file_name => "Main.hx", :line_number => 49, :class_name => "Main", :method_name => "intMap"})
    key = Map.keys(map)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
    g = []
    k = Map.keys(map)
    keys = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} ->
  if (acc_k.has_next()) do
    g = g ++ [(acc_k.next())]
    {:cont, {acc_k, acc_state}}
  else
    {:halt, {acc_k, acc_state}}
  end
end)
g
    g = []
    k = Map.keys(map)
    values = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} ->
  if (acc_k.has_next()) do
    g = g ++ [Map.get(map, acc_k)]
    {:cont, {acc_k.next(), acc_state}}
  else
    {:halt, {acc_k.next(), acc_state}}
  end
end)
g
    Log.trace("Keys: " <> Std.string(keys), %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "intMap"})
    Log.trace("Values: " <> Std.string(values), %{:file_name => "Main.hx", :line_number => 58, :class_name => "Main", :method_name => "intMap"})
  end
  def object_map() do
    map = %{}
    obj1 = %{:id => 1}
    obj2 = %{:id => 2}
    map = Map.put(map, obj1, "Object 1")
    map = Map.put(map, obj2, "Object 2")
    Log.trace("Object 1 value: " <> Kernel.to_string(Map.get(map, obj1)), %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "objectMap"})
    Log.trace("Object 2 value: " <> Kernel.to_string(Map.get(map, obj2)), %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "objectMap"})
    obj3 = %{:id => 1}
    Log.trace("New {id: 1} value: " <> Kernel.to_string(Map.get(map, obj3)), %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "objectMap"})
  end
  def map_literals() do
    g = %{}
    g = Map.put(g, "red", 16711680)
    g = Map.put(g, "green", 65280)
    g = Map.put(g, "blue", 255)
    colors = g
    Log.trace("Color values:", %{:file_name => "Main.hx", :line_number => 88, :class_name => "Main", :method_name => "mapLiterals"})
    color = Map.keys(colors)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {color, :ok}, fn _, {acc_color, acc_state} -> nil end)
    g = %{}
    g = Map.put(g, 1, 1)
    g = Map.put(g, 2, 4)
    g = Map.put(g, 3, 9)
    g = Map.put(g, 4, 16)
    g = Map.put(g, 5, 25)
    squares = g
    Log.trace("Squares:", %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "mapLiterals"})
    n = Map.keys(squares)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {n, :ok}, fn _, {acc_n, acc_state} -> nil end)
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
    Log.trace("User data:", %{:file_name => "Main.hx", :line_number => 128, :class_name => "Main", :method_name => "nestedMaps"})
    username = Map.keys(users)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {username, :ok}, fn _, {acc_username, acc_state} -> nil end)
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
    Log.trace("Doubled values:", %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "mapTransformations"})
    key = Map.keys(doubled)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
    filtered = %{}
    key = Map.keys(original)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
    Log.trace("Filtered (value > 2):", %{:file_name => "Main.hx", :line_number => 167, :class_name => "Main", :method_name => "mapTransformations"})
    key = Map.keys(filtered)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
    key = Map.keys(map2)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
    Log.trace("Merged maps:", %{:file_name => "Main.hx", :line_number => 184, :class_name => "Main", :method_name => "mapTransformations"})
    key = Map.keys(merged)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
  end
  def enum_map() do
    map = %{}
    map = Map.put(map, {:red}, "FF0000")
    map = Map.put(map, {:green}, "00FF00")
    map = Map.put(map, {:blue}, "0000FF")
    Log.trace("Enum map:", %{:file_name => "Main.hx", :line_number => 198, :class_name => "Main", :method_name => "enumMap"})
    color = map.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {color, :ok}, fn _, {acc_color, acc_state} -> nil end)
    if (Map.has_key?(map, {:red})) do
      Log.trace("Red color code: #" <> Kernel.to_string(Map.get(map, {:red})), %{:file_name => "Main.hx", :line_number => 205, :class_name => "Main", :method_name => "enumMap"})
    end
  end
  def process_map(input) do
    result = %{}
    key = Map.keys(input)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
    result
  end
  def main() do
    Log.trace("=== String Map ===", %{:file_name => "Main.hx", :line_number => 220, :class_name => "Main", :method_name => "main"})
    string_map()
    Log.trace("\n=== Int Map ===", %{:file_name => "Main.hx", :line_number => 223, :class_name => "Main", :method_name => "main"})
    int_map()
    Log.trace("\n=== Object Map ===", %{:file_name => "Main.hx", :line_number => 226, :class_name => "Main", :method_name => "main"})
    object_map()
    Log.trace("\n=== Map Literals ===", %{:file_name => "Main.hx", :line_number => 229, :class_name => "Main", :method_name => "main"})
    map_literals()
    Log.trace("\n=== Nested Maps ===", %{:file_name => "Main.hx", :line_number => 232, :class_name => "Main", :method_name => "main"})
    nested_maps()
    Log.trace("\n=== Map Transformations ===", %{:file_name => "Main.hx", :line_number => 235, :class_name => "Main", :method_name => "main"})
    map_transformations()
    Log.trace("\n=== Enum Map ===", %{:file_name => "Main.hx", :line_number => 238, :class_name => "Main", :method_name => "main"})
    enum_map()
    Log.trace("\n=== Map Functions ===", %{:file_name => "Main.hx", :line_number => 241, :class_name => "Main", :method_name => "main"})
    g = %{}
    g = Map.put(g, "x", 10)
    g = Map.put(g, "y", 20)
    g = Map.put(g, "z", 30)
    input = g
    output = process_map(input)
    key = Map.keys(output)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
  end
end