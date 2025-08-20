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
  @doc """
    Fold/reduce map entries into a single value
    @param map The map to reduce
    @param initial Initial accumulator value
    @param reducer Function that takes (accumulator, key, value) and returns new accumulator
    @return Final accumulated value
  """
  @spec reduce(Map.t(), A.t(), Function.t()) :: A.t()
  def reduce(map, initial, reducer) do
    Enum.reduce(map, initial, fn {{k, v}}, acc -> &MapTools.reducer/1.(acc, k, v) end)
  end

  @doc """
    Check if any entry matches the predicate
    @param map The map to check
    @param predicate Function that takes (key, value) and returns boolean
    @return True if any entry matches, false otherwise
  """
  @spec any(Map.t(), Function.t()) :: boolean()
  def any(map, predicate) do
    Enum.any?(map, fn {{k, v}} -> &MapTools.predicate/1.(k, v) end)
  end

  @doc """
    Check if all entries match the predicate
    @param map The map to check
    @param predicate Function that takes (key, value) and returns boolean
    @return True if all entries match, false otherwise
  """
  @spec all(Map.t(), Function.t()) :: boolean()
  def all(map, predicate) do
    Enum.all?(map, fn {{k, v}} -> &MapTools.predicate/1.(k, v) end)
  end

  @doc """
    Find first entry that matches predicate
    @param map The map to search
    @param predicate Function that takes (key, value) and returns boolean
    @return Entry as {key: K, value: V} or null if not found
  """
  @spec find(Map.t(), Function.t()) :: Null.t()
  def find(map, predicate) do
    case Enum.find(map, fn {{k, v}} -> &MapTools.predicate/1.(k, v) end) do
          {{k, v}} -> %{{key: k, value: v}}
          nil -> nil
        end
  end

  @doc """
    Get all keys from the map
    @param map The map to get keys from
    @return Array of all keys
  """
  @spec keys(Map.t()) :: Array.t()
  def keys(map) do
    Map.keys(map) |> Enum.to_list()
  end

  @doc """
    Get all values from the map
    @param map The map to get values from
    @return Array of all values
  """
  @spec values(Map.t()) :: Array.t()
  def values(map) do
    Map.values(map) |> Enum.to_list()
  end

  @doc """
    Convert map to array of key-value pairs
    @param map The map to convert
    @return Array of {key: K, value: V} objects
  """
  @spec to_array(Map.t()) :: Array.t()
  def to_array(map) do
    Enum.map(map, fn {{k, v}} -> %{{key: k, value: v}} end)
  end

  @doc """
    Check if map is empty
    @param map The map to check
    @return True if map has no entries, false otherwise
  """
  @spec is_empty(Map.t()) :: boolean()
  def is_empty(map) do
    Enum.empty?(map)
  end

  @doc """
    Get the size/length of the map
    @param map The map to measure
    @return Number of entries in the map
  """
  @spec size(Map.t()) :: integer()
  def size(map) do
    map_size(map)
  end

end
