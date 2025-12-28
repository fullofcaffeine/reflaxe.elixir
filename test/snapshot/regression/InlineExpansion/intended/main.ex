defmodule Main do
  defp test() do
    _node = %TreeNode{}
    l = %TreeNode{}
    r = %TreeNode{}
    if ((fn ->
  this = l.left
  if (Kernel.is_nil(this)), do: 0, else: this._height
end).() >= (fn ->
  this = l.right
  if (Kernel.is_nil(this)), do: 0, else: this._height
end).()), do: nil
    _total_height = (if (Kernel.is_nil(l)), do: 0, else: l._height) + (if (Kernel.is_nil(r)), do: 0, else: r._height)
    _has_height = (if (Kernel.is_nil(l)), do: 0, else: l._height) > 0
    nil
  end
  def main() do
    test()
  end
end
