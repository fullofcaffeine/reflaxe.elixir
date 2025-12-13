defmodule MapTools do
  def filter(map, predicate) do
    Map.new(Enum.filter(map, fn {k, v} -> predicate.(k, v) end))
  end
  def map(map, transform) do
    Map.new(Enum.map(map, fn {k, v} -> {k, transform.(k, v)} end))
  end
  def map_keys(map, transform) do
    Map.new(Enum.map(map, fn {k, v} -> {transform.(k, v), v} end))
  end
  def reduce(map, initial, reducer) do
    Enum.reduce(map, initial, fn {k, v}, acc -> reducer.(acc, k, v) end)
  end
  def any(map, predicate) do
    Enum.any?(map, fn {k, v} -> predicate.(k, v) end)
  end
  def all(map, predicate) do
    Enum.all?(map, fn {k, v} -> predicate.(k, v) end)
  end
  def find(map, predicate) do
    case Enum.find(map, fn {k, v} -> predicate.(k, v) end) do
      {k, v} -> %{key: k, value: v}
      nil -> nil
    end
  end
  def keys(map) do
    Map.keys(map) |> Enum.to_list()
  end
  def values(map) do
    Map.values(map) |> Enum.to_list()
  end
  def to_array(map) do
    Enum.map(map, fn {k, v} -> %{key: k, value: v} end)
  end
  def from_array(pairs) do
    Map.new(Enum.map(pairs, fn %{key: k, value: v} -> {k, v} end))
  end
  def merge(map1, map2) do
    Map.merge(map1, map2)
  end
  def is_empty(map) do
    Enum.empty?(map)
  end
  def size(map) do
    map_size(map)
  end
end
