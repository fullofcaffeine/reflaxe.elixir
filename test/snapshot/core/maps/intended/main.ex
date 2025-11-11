defmodule Main do
  def string_map() do
    map = %{}
    map = Map.put(map, :one, 1)
    _ = map
  end
  def int_map() do
    map = %{}
    map = Map.put(map, 1, "first")
    _ = map
  end
  def object_map() do
    map = %{}
    obj1 = %{:id => 1}
    obj2 = %{:id => 2}
    map = Map.put(map, obj1, "Object 1")
    _ = map
  end
  def map_literals() do
    colors = %{"red" => 16711680, "green" => 65280, "blue" => 255}
    color = colors.keys()
    _ = Enum.each(color, (fn -> fn item ->
  hex = StringTools.hex(colors.get(color), 6)
  nil
end end).())
    squares = %{1 => 1, 2 => 4, 3 => 9, 4 => 16, 5 => 25}
    n = squares.keys()
    _ = Enum.each(n, fn _ -> nil end)
  end
  def nested_maps() do
    users = %{}
    alice = %{}
    alice = Map.put(alice, :age, 30)
    _ = alice
  end
  def map_transformations() do
    original = %{"a" => 1, "b" => 2, "c" => 3, "d" => 4}
    doubled = %{}
    key = original.keys()
    _ = Enum.each(key, (fn -> fn item ->
  value = original.get(item) * 2
  doubled.set(item, value)
end end).())
    key = doubled.keys()
    _ = Enum.each(key, fn _ -> nil end)
    filtered = %{}
    key = original.keys()
    _ = Enum.each(key, (fn -> fn item ->
  value = original.get(item)
  if (value > 2), do: filtered.set(item, value)
end end).())
    key = filtered.keys()
    _ = Enum.each(key, fn _ -> nil end)
    map1 = %{"a" => 1, "b" => 2}
    map2 = %{"c" => 3, "d" => 4, "a" => 10}
    merged = %{}
    key = map1.keys()
    _ = Enum.each(key, (fn -> fn item ->
  value = map1.get(item)
  merged.set(item, value)
end end).())
    key = map2.keys()
    _ = Enum.each(key, (fn -> fn item ->
  value = map2.get(item)
  merged.set(item, value)
end end).())
    key = merged.keys()
    _ = Enum.each(key, fn _ -> nil end)
  end
  def enum_map() do
    map = %{}
    map = Map.put(map, {:red}, "FF0000")
    _ = map
  end
  def process_map(input) do
    key = input.keys()
    _ = Enum.each(key, (fn -> fn item ->
  value = input.get(item)
  item.set(item, "Value: " <> Kernel.to_string(value))
end end).())
    %{}
  end
  def main() do
    _ = string_map()
    _ = int_map()
    _ = object_map()
    _ = map_literals()
    _ = nested_maps()
    _ = map_transformations()
    _ = enum_map()
    input = %{"x" => 10, "y" => 20, "z" => 30}
    output = process_map(input)
    key = output.keys()
    _ = Enum.each(key, fn _ -> nil end)
  end
end
