defmodule Main do
  def string_map() do
    map = %{}
    map = Map.put(map, :one, 1)
    _ = map
    _
  end
  def int_map() do
    map = %{}
    map = Map.put(map, 1, "first")
    _ = map
    _
  end
  def object_map() do
    map = %{}
    _ = %{:id => 1}
    _ = %{:id => 2}
    map = Map.put(map, obj1, "Object 1")
    _ = map
    _
  end
  def map_literals() do
    colors = %{"red" => 16711680, "green" => 65280, "blue" => 255}
    _ = Log.trace("Color values:", %{:file_name => "Main.hx", :line_number => 89, :class_name => "Main", :method_name => "mapLiterals"})
    _ = colors.keys()
    _ = Enum.each(color, (fn -> fn item ->
  hex = StringTools.hex(colors.get(color2), 6)
  Log.trace("  " <> color2 <> " => #" <> hex, %{:file_name => "Main.hx", :line_number => 92, :class_name => "Main", :method_name => "mapLiterals"})
end end).())
    squares = %{1 => 1, 2 => 4, 3 => 9, 4 => 16, 5 => 25}
    _ = Log.trace("Squares:", %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "mapLiterals"})
    _ = squares.keys()
    _ = Enum.each(n, fn item -> Log.trace("  " <> Kernel.to_string(n2) <> "² = " <> Kernel.to_string(squares.get(n2)), %{:file_name => "Main.hx", :line_number => 106, :class_name => "Main", :method_name => "mapLiterals"}) end)
    _
  end
  def nested_maps() do
    _ = %{}
    alice = %{}
    alice = Map.put(alice, :age, 30)
    _ = alice
    _
  end
  def map_transformations() do
    original = %{"a" => 1, "b" => 2, "c" => 3, "d" => 4}
    doubled = %{}
    _ = original.keys()
    _ = Enum.each(key, (fn -> fn item ->
  value = original.get(item) * 2
  doubled.set(item, value)
end end).())
    _ = Log.trace("Doubled values:", %{:file_name => "Main.hx", :line_number => 154, :class_name => "Main", :method_name => "mapTransformations"})
    _ = doubled.keys()
    _ = Enum.each(key, fn item -> Log.trace("  " <> key2 <> " => " <> Kernel.to_string(doubled.get(key2)), %{:file_name => "Main.hx", :line_number => 156, :class_name => "Main", :method_name => "mapTransformations"}) end)
    filtered = %{}
    _ = original.keys()
    _ = Enum.each(key, (fn -> fn item ->
  value = original.get(item)
  if (value > 2), do: filtered.set(item, value)
end end).())
    _ = Log.trace("Filtered (value > 2):", %{:file_name => "Main.hx", :line_number => 168, :class_name => "Main", :method_name => "mapTransformations"})
    _ = filtered.keys()
    _ = Enum.each(key, fn item -> Log.trace("  " <> key2 <> " => " <> Kernel.to_string(filtered.get(key2)), %{:file_name => "Main.hx", :line_number => 170, :class_name => "Main", :method_name => "mapTransformations"}) end)
    map1 = %{"a" => 1, "b" => 2}
    map2 = %{"c" => 3, "d" => 4, "a" => 10}
    merged = %{}
    _ = map1.keys()
    _ = Enum.each(key, (fn -> fn item ->
  value = map1.get(item)
  merged.set(item, value)
end end).())
    _ = map2.keys()
    _ = Enum.each(key, (fn -> fn item ->
  value = map2.get(item)
  merged.set(item, value)
end end).())
    _ = Log.trace("Merged maps:", %{:file_name => "Main.hx", :line_number => 185, :class_name => "Main", :method_name => "mapTransformations"})
    _ = merged.keys()
    _ = Enum.each(key, fn item -> Log.trace("  " <> key2 <> " => " <> Kernel.to_string(merged.get(key2)), %{:file_name => "Main.hx", :line_number => 187, :class_name => "Main", :method_name => "mapTransformations"}) end)
  end
  def enum_map() do
    map = %{}
    map = Map.put(map, {:red}, "FF0000")
    _ = map
    _
  end
  def process_map(input) do
    _ = input.keys()
    _ = Enum.each(key, (fn -> fn item ->
  value = input.get(item)
  item.set(item, "Value: " <> Kernel.to_string(value))
end end).())
    %{}
  end
  def main() do
    _ = Log.trace("=== String Map ===", %{:file_name => "Main.hx", :line_number => 221, :class_name => "Main", :method_name => "main"})
    _ = string_map()
    _ = Log.trace("\n=== Int Map ===", %{:file_name => "Main.hx", :line_number => 224, :class_name => "Main", :method_name => "main"})
    _ = int_map()
    _ = Log.trace("\n=== Object Map ===", %{:file_name => "Main.hx", :line_number => 227, :class_name => "Main", :method_name => "main"})
    _ = object_map()
    _ = Log.trace("\n=== Map Literals ===", %{:file_name => "Main.hx", :line_number => 230, :class_name => "Main", :method_name => "main"})
    _ = map_literals()
    _ = Log.trace("\n=== Nested Maps ===", %{:file_name => "Main.hx", :line_number => 233, :class_name => "Main", :method_name => "main"})
    _ = nested_maps()
    _ = Log.trace("\n=== Map Transformations ===", %{:file_name => "Main.hx", :line_number => 236, :class_name => "Main", :method_name => "main"})
    _ = map_transformations()
    _ = Log.trace("\n=== Enum Map ===", %{:file_name => "Main.hx", :line_number => 239, :class_name => "Main", :method_name => "main"})
    _ = enum_map()
    _ = Log.trace("\n=== Map Functions ===", %{:file_name => "Main.hx", :line_number => 242, :class_name => "Main", :method_name => "main"})
    input = %{"x" => 10, "y" => 20, "z" => 30}
    output = process_map(input)
    _ = output.keys()
    _ = Enum.each(key, fn item -> Log.trace("" <> key2 <> ": " <> Kernel.to_string(output.get(key2)), %{:file_name => "Main.hx", :line_number => 246, :class_name => "Main", :method_name => "main"}) end)
    _
  end
end
