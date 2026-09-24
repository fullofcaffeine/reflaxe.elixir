defmodule DataStructureTest do
  def test_collections() do
    map = %{}
    _ = map |> Map.put("one", 1) |> Map.put("two", 2)
    array = []
    array = array ++ ["first"]
    _ = array ++ ["second"]
    _ = 3
  end
end
