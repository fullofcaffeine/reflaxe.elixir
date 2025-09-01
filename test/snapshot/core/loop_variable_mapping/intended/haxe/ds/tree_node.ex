defmodule TreeNode do
  def new(l, k, v, r, h) do
    %{:left => l, :key => k, :value => v, :right => r}
  end
  def to_string(struct) do
    (if (struct.left == nil), do: "", else: struct.left.toString() + ", ") + ("" + Std.string(struct.key) + " => " + Std.string(struct.value)) + (if (struct.right == nil), do: "", else: ", " + struct.right.toString())
  end
end