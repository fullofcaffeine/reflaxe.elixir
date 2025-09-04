defmodule TreeNode do
  def new(l, k, v, r, _h) do
    %{:left => l, :key => k, :value => v, :right => r, :_height => (if (_h == -1), do: 1, else: _h)}
  end
  def get_height(struct) do
    struct._height
  end
  def to_string(struct) do
    (if (struct.left == nil), do: "", else: struct.left.toString() <> ", ") <> ("" <> Std.string(struct.key) <> " => " <> Std.string(struct.value)) <> (if (struct.right == nil), do: "", else: ", " <> struct.right.toString())
  end
end