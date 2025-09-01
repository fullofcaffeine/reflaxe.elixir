defmodule Map_Impl_ do
  def set(this1, key, value) do
    Map.put(this1, key, value)
  end
  def get(this1, key) do
    Map.get(this1, key)
  end
  def exists(this1, key) do
    Map.has_key?(this1, key)
  end
  def remove(this1, key) do
    Map.delete(this1, key)
  end
  def keys(this1) do
    Map.keys(this1)
  end
  def iterator(this1) do
    this1.iterator()
  end
  def key_value_iterator(this1) do
    this1.keyValueIterator()
  end
  def copy(this1) do
    this1.copy()
  end
  def to_string(this1) do
    this1.toString()
  end
  def clear(this1) do
    this1.clear()
  end
  def array_write(this1, k, v) do
    Map.put(this1, k, v)
    v
  end
  defp to_string_map(t) do
    %{}
  end
  defp to_int_map(t) do
    %{}
  end
  defp to_enum_value_map_map(t) do
    %{}
  end
  defp to_object_map(t) do
    %{}
  end
  defp from_string_map(map) do
    map
  end
  defp from_int_map(map) do
    map
  end
  defp from_object_map(map) do
    map
  end
end