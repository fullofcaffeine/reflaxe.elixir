defmodule Main do
  defp test() do
    _node = TreeNode.new()
    l = TreeNode.new()
    r = TreeNode.new()
    _this = l.left
    _this = l.right
    if ((if this == nil, do: 0, else: this._height) >= (if this == nil, do: 0, else: this._height)) do
      Log.trace("left is taller or equal", %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "test"})
    end
    total_height = (if (l == nil), do: 0, else: l._height) + (if (r == nil), do: 0, else: r._height)
    Log.trace("Total height: " <> total_height, %{:fileName => "Main.hx", :lineNumber => 35, :className => "Main", :methodName => "test"})
    has_height = (if (l == nil), do: 0, else: l._height) > 0
    Log.trace("Has height: " <> Std.string(has_height), %{:fileName => "Main.hx", :lineNumber => 39, :className => "Main", :methodName => "test"})
  end
  defp main() do
    test()
  end
end