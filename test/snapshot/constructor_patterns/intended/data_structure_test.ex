defmodule DataStructureTest do
  def test_collections() do
    map = %{}
    map = Map.put(map, "one", 1)
    map = Map.put(map, "two", 2)
    array = Array.new()
    array = array ++ ["first"]
    array = array ++ ["second"]
    list_0 = 1
    list_1 = 2
    list_2 = 3
  end
end