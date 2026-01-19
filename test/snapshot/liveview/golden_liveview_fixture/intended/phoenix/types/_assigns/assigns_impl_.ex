defmodule Assigns_Impl_ do
  def from_dynamic(value) do
    value
  end
  def from_object(obj) do
    obj
  end
  def to_dynamic(this1) do
    this1
  end
  def get(this1, key) do
    Map.get(this1, key)
  end
  def set(this1, key, value) do
    _ = Map.put(this1, key, value)
    value
  end
  def get_field(this1, field) do
    Map.get(this1, field)
  end
  def set_field(this1, field, value) do
    _ = Map.put(this1, field, value)
    value
  end
  def has_field(this1, field) do
    Map.has_key?(this1, field)
  end
  def get_fields(this1) do
    Reflect.fields(this1)
  end
  def merge(this1, other) do
    result = %{}
    _g = 0
    g_value = Reflect.fields(this1)
    _ = Enum.each(g_value, fn field -> Map.put(result, field, Map.get(this1, field)) end)
    _g = 0
    g_value = Reflect.fields(to_dynamic(other))
    _ = Enum.each(g_value, fn field -> Map.put(result, field, Map.get(to_dynamic(other), field)) end)
    _ = from_dynamic(result)
  end
  def with_field(this1, field, value) do
    result = %{}
    _g = 0
    g_value = Reflect.fields(this1)
    _ = Enum.each(g_value, fn existing_field -> Map.put(result, existing_field, Map.get(this1, existing_field)) end)
    result = Map.put(result, field, value)
    _ = from_dynamic(result)
  end
end
