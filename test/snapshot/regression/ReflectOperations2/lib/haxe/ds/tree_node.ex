defmodule TreeNode do
  def get_height(struct) do
    struct._height
  end
  def to_string(struct) do
    "#{(if (struct.left == nil), do: "", else: struct.left.to_string() <> ", ")}#{("" <> Std.string(struct.key) <> " => " <> Std.string(struct.value))}#{(if (struct.right == nil), do: "", else: ", " <> struct.right.to_string())}"
  end
end