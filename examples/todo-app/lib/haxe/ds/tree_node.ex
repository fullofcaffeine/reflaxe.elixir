defmodule TreeNode do
  @left nil
  @right nil
  @key nil
  @value nil
  @_height nil
  def get_height(_struct) do
    struct._height
  end
  def to_string(_struct) do
    (if (struct.left == nil), do: "", else: struct.left.to_string() <> ", ") <> ("" <> Std.string(struct.key) <> " => " <> Std.string(struct.value)) <> (if (struct.right == nil), do: "", else: ", " <> struct.right.to_string())
  end
end