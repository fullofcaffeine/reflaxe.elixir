defmodule TreeNode do
  def new(l, k, v, r, h) do
    struct = %{:__reflaxe_class__ => TreeNode, :left => nil, :right => nil, :key => nil, :value => nil, :_height => nil}
    struct = %{struct | left: l}
    struct = %{struct | key: k}
    struct = %{struct | value: v}
    struct = %{struct | right: r}
    struct = if (h == -1) do
      %{struct | _height: (if ((fn ->
  this = struct.left
  if (Kernel.is_nil(this)), do: 0, else: this._height
end).() > (fn ->
  this = struct.right
  if (Kernel.is_nil(this)), do: 0, else: this._height
end).()) do
  this = struct.left
  if (Kernel.is_nil(this)), do: 0, else: this._height
else
  this = struct.right
  if (Kernel.is_nil(this)), do: 0, else: this._height
end) + 1}
    else
      %{struct | _height: h}
    end
    struct
  end
end
