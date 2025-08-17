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
    _g = map.keyValueIterator()
    (
      try do
        loop_fn = fn {initial} ->
          if (_g.hasNext()) do
            try do
              _g = _g.next()
          key = _g.key
          value = _g.value
          # initial updated to reducer.(initial, key, value)
          loop_fn.({reducer.(initial, key, value)})
            catch
              :break -> {initial}
              :continue -> loop_fn.({initial})
            end
          else
            {initial}
          end
        end
        loop_fn.({initial})
      catch
        :break -> {initial}
      end
    )
    initial
  end

  @doc """
    Check if any entry matches the predicate
    @param map The map to check
    @param predicate Function that takes (key, value) and returns boolean
    @return True if any entry matches, false otherwise
  """
  @spec any(Map.t(), Function.t()) :: boolean()
  def any(map, predicate) do
    _g = map.keyValueIterator()
    (
      try do
        loop_fn = fn ->
          if (_g.hasNext()) do
            try do
              _g = _g.next()
    key = _g.key
    value = _g.value
    if (predicate.(key, value)), do: true, else: nil
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    false
  end

  @doc """
    Check if all entries match the predicate
    @param map The map to check
    @param predicate Function that takes (key, value) and returns boolean
    @return True if all entries match, false otherwise
  """
  @spec all(Map.t(), Function.t()) :: boolean()
  def all(map, predicate) do
    _g = map.keyValueIterator()
    (
      try do
        loop_fn = fn ->
          if (_g.hasNext()) do
            try do
              _g = _g.next()
    key = _g.key
    value = _g.value
    if (!predicate.(key, value)), do: false, else: nil
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    true
  end

  @doc """
    Find first entry that matches predicate
    @param map The map to search
    @param predicate Function that takes (key, value) and returns boolean
    @return Entry as {key: K, value: V} or null if not found
  """
  @spec find(Map.t(), Function.t()) :: Null.t()
  def find(map, predicate) do
    _g = map.keyValueIterator()
    (
      try do
        loop_fn = fn ->
          if (_g.hasNext()) do
            try do
              _g = _g.next()
    key = _g.key
    value = _g.value
    if (predicate.(key, value)), do: %{"key" => key, "value" => value}, else: nil
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    nil
  end

  @doc """
    Get all keys from the map
    @param map The map to get keys from
    @return Array of all keys
  """
  @spec keys(Map.t()) :: Array.t()
  def keys(map) do
    result = []
    key = map.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    result ++ [key]
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    result
  end

  @doc """
    Get all values from the map
    @param map The map to get values from
    @return Array of all values
  """
  @spec values(Map.t()) :: Array.t()
  def values(map) do
    result = []
    value = map.iterator()
    (
      try do
        loop_fn = fn ->
          if (value.hasNext()) do
            try do
              value = value.next()
    result ++ [value]
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    result
  end

  @doc """
    Convert map to array of key-value pairs
    @param map The map to convert
    @return Array of {key: K, value: V} objects
  """
  @spec to_array(Map.t()) :: Array.t()
  def to_array(map) do
    result = []
    _g = map.keyValueIterator()
    (
      try do
        loop_fn = fn ->
          if (_g.hasNext()) do
            try do
              _g = _g.next()
    key = _g.key
    value = _g.value
    result ++ [%{"key" => key, "value" => value}]
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    result
  end

  @doc """
    Check if map is empty
    @param map The map to check
    @return True if map has no entries, false otherwise
  """
  @spec is_empty(Map.t()) :: boolean()
  def is_empty(map) do
    _ = map.iterator()
    (
      try do
        loop_fn = fn ->
          if (_.hasNext()) do
            try do
              _.next()
    false
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    true
  end

  @doc """
    Get the size/length of the map
    @param map The map to measure
    @return Number of entries in the map
  """
  @spec size(Map.t()) :: integer()
  def size(map) do
    count = 0
    _ = map.iterator()
    (
      try do
        loop_fn = fn {count} ->
          if (_.hasNext()) do
            try do
              _.next()
          # count incremented
          loop_fn.({count + 1})
            catch
              :break -> {count}
              :continue -> loop_fn.({count})
            end
          else
            {count}
          end
        end
        loop_fn.({count})
      catch
        :break -> {count}
      end
    )
    count
  end

end
