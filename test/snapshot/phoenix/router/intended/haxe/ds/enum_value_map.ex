defmodule EnumValueMap do
  def keys(struct), do: Map.keys(struct)
  def copy(struct), do: struct
  def to_string(struct), do: inspect(struct)
  def iterator(struct), do: Map.keys(struct)
end
