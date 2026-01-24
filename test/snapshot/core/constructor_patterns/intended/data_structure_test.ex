defmodule DataStructureTest do
  def test_collections() do
    map = %{}
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, "one", 1])
    _ = apply(Map.get(map, :__reflaxe_class__) || Map.get(map, :__struct__), :set, [map, "two", 2])
    array = Array.new()
    array = array ++ ["first"]
    _ = array ++ ["second"]
    _ = 1
    _ = 2
    _ = 3
  end
end
