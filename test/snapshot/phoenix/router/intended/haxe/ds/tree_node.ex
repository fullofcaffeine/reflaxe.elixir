defmodule TreeNode do
  def get_height(struct), do: Map.get(struct, :_height)
  def to_string(struct), do: inspect(struct)
end
