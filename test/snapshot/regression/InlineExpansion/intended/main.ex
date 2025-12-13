defmodule Main do
  defp test() do
    node = MyApp.TreeNode.new()
    l = MyApp.TreeNode.new()
    r = MyApp.TreeNode.new()
    if ((fn ->
  this = l.left
  if (Kernel.is_nil(this)), do: 0, else: this._height
end).() >= (fn ->
  this = l.right
  if (Kernel.is_nil(this)), do: 0, else: this._height
end).()), do: nil
    total_height = (if (Kernel.is_nil(l)), do: 0, else: l._height) + (if (Kernel.is_nil(r)), do: 0, else: r._height)
    has_height = (if (Kernel.is_nil(l)), do: 0, else: l._height) > 0
    nil
  end
end
