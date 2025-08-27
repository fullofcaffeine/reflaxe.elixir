defmodule MapTools do
  @moduledoc """
    MapTools module generated from Haxe

     * Static extension class providing functional operations for Map<K,V>
     *
     * Usage: `using MapTools;` then call methods on Map instances:
     *   var map = ["key" => "value"];
     *   var filtered = map.filter((k, v) -> v.length > 3);
     *   var keys = map.keys();
     *
     * All methods maintain functional programming principles:
     * - Immutable operations (return new maps)
     * - Type-safe transformations
     * - Cross-platform compatibility
     * - Compile to idiomatic target code (Elixir Map module, etc.)
  """

  # Static functions
  @doc "Generated from Haxe reduce"
  def reduce(map, initial, reducer) do
    Enum.reduce(map, initial, fn {{k, v}}, acc -> reducer.(acc, k, v) end)
  end

  @doc "Generated from Haxe any"
  def any(map, predicate) do
    Enum.any?(map, fn {{k, v}} -> predicate.(k, v) end)
  end

  @doc "Generated from Haxe all"
  def all(map, predicate) do
    Enum.all?(map, fn {{k, v}} -> predicate.(k, v) end)
  end

  @doc "Generated from Haxe find"
  def find(map, predicate) do
    case Enum.find(map, fn {{k, v}} -> predicate.(k, v) end) do
          {{k, v}} -> %{{key: k, value: v}}
          nil -> nil
        end
  end

  @doc "Generated from Haxe keys"
  def keys(map) do
    Map.keys(map) |> Enum.to_list()
  end

  @doc "Generated from Haxe values"
  def values(map) do
    Map.values(map) |> Enum.to_list()
  end

  @doc "Generated from Haxe toArray"
  def to_array(map) do
    Enum.map(map, fn {{k, v}} -> %{{key: k, value: v}} end)
  end

  @doc "Generated from Haxe isEmpty"
  def is_empty(map) do
    Enum.empty?(map)
  end

  @doc "Generated from Haxe size"
  def size(map) do
    map_size(map)
  end

end
