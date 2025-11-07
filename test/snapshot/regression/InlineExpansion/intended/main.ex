defmodule Main do
  defp test() do
    node = MyApp.TreeNode.new()
    l = MyApp.TreeNode.new()
    r = MyApp.TreeNode.new()
    if ((fn ->
  _this = l.left
  if (Kernel.is_nil(this)), do: 0, else: this._height
end).() >= (fn ->
  _this = l.right
  if (Kernel.is_nil(this)), do: 0, else: this._height
end).()) do
      Log.trace("left is taller or equal", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "test"})
    end
    total_height = (if (Kernel.is_nil(l)), do: 0, else: l._height) + (if (Kernel.is_nil(r)), do: 0, else: r._height)
    _ = Log.trace("Total height: #{(fn -> total_height end).()}", %{:file_name => "Main.hx", :line_number => 35, :class_name => "Main", :method_name => "test"})
    has_height = (if (Kernel.is_nil(l)), do: 0, else: l._height) > 0
    _ = Log.trace("Has height: #{(fn -> inspect(has_height) end).()}", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "test"})
  end
end
