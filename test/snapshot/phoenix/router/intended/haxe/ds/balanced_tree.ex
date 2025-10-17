defmodule BalancedTree do
  def set(struct, _key, _value), do: struct
  def get(_struct, _key), do: nil
  def remove(_struct, _key), do: false
  def exists(_struct, _key), do: false
  def iterator(_struct), do: []
  def key_value_iterator(_struct), do: []
  def keys(_struct), do: []
  def copy(struct), do: struct
  def to_string(struct), do: inspect(struct)
  def clear(_struct), do: nil
end
