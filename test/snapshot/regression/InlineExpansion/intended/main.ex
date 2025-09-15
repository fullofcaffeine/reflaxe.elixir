defmodule Main do
  defp test() do
    _node = TreeNode.new()
    l = TreeNode.new()
    r = TreeNode.new()
    _this = l.left
    _this = l.right
    if ((if this == nil, do: 0, else: this._height) >= (if this == nil, do: 0, else: this._height)) do
      Log.trace("left is taller or equal", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "test"})
    end
    total_height = (if (l == nil), do: 0, else: l._height) + (if (r == nil), do: 0, else: r._height)
    Log.trace("Total height: #{total_height}", %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "test"})
    has_height = (if (l == nil), do: 0, else: l._height) > 0
    Log.trace("Has height: #{has_height}", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "test"})
  end
  def main() do
    test()
  end
end