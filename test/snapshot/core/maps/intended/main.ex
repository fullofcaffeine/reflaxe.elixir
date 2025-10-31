defmodule Main do
  def string_map() do
    map = %{}
    map = Map.put(map, :one, 1)
    map = Map.put(map, :two, 2)
    map = Map.put(map, :three, 3)
    Log.trace("Value of \"two\": #{(fn -> map.get("two") end).()}", %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "stringMap"})
    Log.trace("Value of \"four\": #{(fn -> map.get("four") end).()}", %{:file_name => "Main.hx", :line_number => 20, :class_name => "Main", :method_name => "stringMap"})
    Log.trace("Has \"one\": #{(fn -> inspect(map.exists("one")) end).()}", %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "stringMap"})
    Log.trace("Has \"four\": #{(fn -> inspect(map.exists("four")) end).()}", %{:file_name => "Main.hx", :line_number => 24, :class_name => "Main", :method_name => "stringMap"})
    map.remove("two")
    Log.trace("After remove, has \"two\": #{(fn -> inspect(map.exists("two")) end).()}", %{:file_name => "Main.hx", :line_number => 28, :class_name => "Main", :method_name => "stringMap"})
    Log.trace("Iterating string map:", %{:file_name => "Main.hx", :line_number => 31, :class_name => "Main", :method_name => "stringMap"})
    key = map.keys()
    Enum.each(key, fn item -> Log.trace("  " <> key2 <> " => " <> map.get(key2).to_string(), %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "stringMap"}) end)
    map.clear()
    Log.trace((
"After clear, keys: #{(fn -> inspect((fn ->
    g = []
    k = map.keys()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k}, fn _, {k} ->
      if (k.has_next.()) do
        k2 = k.next.()
        _g = Enum.concat(_g, [k2])
        {:cont, {k}}
      else
        {:halt, {k}}
      end
    end)
    _g
  end).()) end).()}"
), %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "stringMap"})
  end
  def int_map() do
    map = %{}
    map = Map.put(map, 1, "first")
    map = Map.put(map, 2, "second")
    map = Map.put(map, 10, "tenth")
    map = Map.put(map, 100, "hundredth")
    Log.trace("Int map values:", %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "intMap"})
    key = map.keys()
    Enum.each(key, fn item -> Log.trace("  " <> key2.to_string() <> " => " <> map.get(key2).to_string(), %{:file_name => "Main.hx", :line_number => 52, :class_name => "Main", :method_name => "intMap"}) end)
    keys = _g = []
    k = map.keys()
    Enum.each(k, fn item -> item = Enum.concat(item, [item]) end)
    _g
    values = _g = []
    k = map.keys()
    Enum.each(k, fn item -> item = Enum.concat(item, [item.get(item)]) end)
    _g
    Log.trace("Keys: #{(fn -> inspect(keys) end).()}", %{:file_name => "Main.hx", :line_number => 58, :class_name => "Main", :method_name => "intMap"})
    Log.trace("Values: #{(fn -> inspect(values) end).()}", %{:file_name => "Main.hx", :line_number => 59, :class_name => "Main", :method_name => "intMap"})
  end
  def object_map() do
    map = %{}
    obj1 = %{:id => 1}
    obj2 = %{:id => 2}
    map = Map.put(map, obj1, "Object 1")
    map = Map.put(map, obj2, "Object 2")
    Log.trace("Object 1 value: #{(fn -> map.get(obj1) end).()}", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "objectMap"})
    Log.trace("Object 2 value: #{(fn -> map.get(obj2) end).()}", %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "objectMap"})
    obj3 = %{:id => 1}
    Log.trace("New {id: 1} value: #{(fn -> map.get(obj3) end).()}", %{:file_name => "Main.hx", :line_number => 77, :class_name => "Main", :method_name => "objectMap"})
  end
  def map_literals() do
    colors = %{"red" => 16711680, "green" => 65280, "blue" => 255}
    Log.trace("Color values:", %{:file_name => "Main.hx", :line_number => 89, :class_name => "Main", :method_name => "mapLiterals"})
    color = colors.keys()
    Enum.each(color, fn item ->
      hex = StringTools.hex(colors.get(color2), 6)
      Log.trace("  " <> color2 <> " => #" <> hex, %{:file_name => "Main.hx", :line_number => 92, :class_name => "Main", :method_name => "mapLiterals"})
    end)
    squares = %{1 => 1, 2 => 4, 3 => 9, 4 => 16, 5 => 25}
    Log.trace("Squares:", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "mapLiterals"})
    n = squares.keys()
    Enum.each(n, fn item -> Log.trace("  " <> n2.to_string() <> "² = " <> squares.get(n2).to_string(), %{:file_name => "Main.hx", :line_number => 106, :class_name => "Main", :method_name => "mapLiterals"}) end)
  end
  def nested_maps() do
    users = %{}
    alice = %{}
    alice = Map.put(alice, :age, 30)
    alice = Map.put(alice, :email, "alice@example.com")
    alice = Map.put(alice, :active, true)
    bob = %{}
    bob = Map.put(bob, :age, 25)
    bob = Map.put(bob, :email, "bob@example.com")
    bob = Map.put(bob, :active, false)
    users = Map.put(users, :alice, alice)
    users = Map.put(users, :bob, bob)
    Log.trace("User data:", %{:file_name => "Main.hx", :line_number => 129, :class_name => "Main", :method_name => "nestedMaps"})
    username = users.keys()
    Enum.each(username, fn item ->
      user_data = item.get(username2)
      Log.trace("  " <> username2 <> ":", %{:file_name => "Main.hx", :line_number => 132, :class_name => "Main", :method_name => "nestedMaps"})
      field = user_data.keys()
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {field}, fn _, {field} ->
        if (field.has_next.()) do
          field2 = field.next.()
          Log.trace("    " <> field2 <> ": " <> inspect(user_data.get(field2)), %{:file_name => "Main.hx", :line_number => 134, :class_name => "Main", :method_name => "nestedMaps"})
          {:cont, {field}}
        else
          {:halt, {field}}
        end
      end)
    end)
  end
  def map_transformations() do
    original = %{"a" => 1, "b" => 2, "c" => 3, "d" => 4}
    doubled = %{}
    key = original.keys()
    Enum.each(key, fn item ->
      value = original.get(item) * 2
      doubled.set(item, value)
    end)
    Log.trace("Doubled values:", %{:file_name => "Main.hx", :line_number => 154, :class_name => "Main", :method_name => "mapTransformations"})
    key = doubled.keys()
    Enum.each(key, fn item -> Log.trace("  " <> key2 <> " => " <> doubled.get(key2).to_string(), %{:file_name => "Main.hx", :line_number => 156, :class_name => "Main", :method_name => "mapTransformations"}) end)
    filtered = %{}
    key = original.keys()
    Enum.each(key, fn item ->
      value = original.get(item)
      if (value > 2), do: filtered.set(item, value)
    end)
    Log.trace("Filtered (value > 2):", %{:file_name => "Main.hx", :line_number => 168, :class_name => "Main", :method_name => "mapTransformations"})
    key = filtered.keys()
    Enum.each(key, fn item -> Log.trace("  " <> key2 <> " => " <> filtered.get(key2).to_string(), %{:file_name => "Main.hx", :line_number => 170, :class_name => "Main", :method_name => "mapTransformations"}) end)
    map1 = %{"a" => 1, "b" => 2}
    map2 = %{"c" => 3, "d" => 4, "a" => 10}
    merged = %{}
    key = map1.keys()
    Enum.each(key, fn item ->
      value = map1.get(item)
      merged.set(item, value)
    end)
    key = map2.keys()
    Enum.each(key, fn item ->
      value = map2.get(item)
      merged.set(item, value)
    end)
    Log.trace("Merged maps:", %{:file_name => "Main.hx", :line_number => 185, :class_name => "Main", :method_name => "mapTransformations"})
    key = merged.keys()
    Enum.each(key, fn item -> Log.trace("  " <> key2 <> " => " <> merged.get(key2).to_string(), %{:file_name => "Main.hx", :line_number => 187, :class_name => "Main", :method_name => "mapTransformations"}) end)
  end
  def enum_map() do
    map = %{}
    map = Map.put(map, {:red}, "FF0000")
    map = Map.put(map, {:green}, "00FF00")
    map = Map.put(map, {:blue}, "0000FF")
    Log.trace("Enum map:", %{:file_name => "Main.hx", :line_number => 199, :class_name => "Main", :method_name => "enumMap"})
    color = map.iterator()
    Enum.each(color, fn item -> Log.trace("  " <> inspect(color2) <> " => #" <> map.get(color2).to_string(), %{:file_name => "Main.hx", :line_number => 201, :class_name => "Main", :method_name => "enumMap"}) end)
    if (map.exists({:red})) do
      Log.trace("Red color code: ##{(fn -> map.get({:red}) end).()}", %{:file_name => "Main.hx", :line_number => 206, :class_name => "Main", :method_name => "enumMap"})
    end
  end
  def process_map(input) do
    key = input.keys()
    Enum.each(key, fn item ->
      value = input.get(item)
      result.set(item, "Value: " <> value.to_string())
    end)
    %{}
  end
  def main() do
    Log.trace("=== String Map ===", %{:file_name => "Main.hx", :line_number => 221, :class_name => "Main", :method_name => "main"})
    string_map()
    Log.trace("\n=== Int Map ===", %{:file_name => "Main.hx", :line_number => 224, :class_name => "Main", :method_name => "main"})
    int_map()
    Log.trace("\n=== Object Map ===", %{:file_name => "Main.hx", :line_number => 227, :class_name => "Main", :method_name => "main"})
    object_map()
    Log.trace("\n=== Map Literals ===", %{:file_name => "Main.hx", :line_number => 230, :class_name => "Main", :method_name => "main"})
    map_literals()
    Log.trace("\n=== Nested Maps ===", %{:file_name => "Main.hx", :line_number => 233, :class_name => "Main", :method_name => "main"})
    nested_maps()
    Log.trace("\n=== Map Transformations ===", %{:file_name => "Main.hx", :line_number => 236, :class_name => "Main", :method_name => "main"})
    map_transformations()
    Log.trace("\n=== Enum Map ===", %{:file_name => "Main.hx", :line_number => 239, :class_name => "Main", :method_name => "main"})
    enum_map()
    Log.trace("\n=== Map Functions ===", %{:file_name => "Main.hx", :line_number => 242, :class_name => "Main", :method_name => "main"})
    input = %{"x" => 10, "y" => 20, "z" => 30}
    output = process_map(input)
    key = output.keys()
    Enum.each(key, fn item -> Log.trace("" <> key2 <> ": " <> output.get(key2).to_string(), %{:file_name => "Main.hx", :line_number => 246, :class_name => "Main", :method_name => "main"}) end)
  end
end
