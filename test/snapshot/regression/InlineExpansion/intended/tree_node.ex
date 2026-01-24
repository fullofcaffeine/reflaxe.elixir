defmodule TreeNode do
  def new() do
    struct = %{:__reflaxe_class__ => TreeNode, :_height => nil, :left => nil, :right => nil}
    struct = %{struct | _height: 0}
    struct
  end
end
