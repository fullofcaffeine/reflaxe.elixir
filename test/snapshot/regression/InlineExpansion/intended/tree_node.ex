defmodule TreeNode do
  def new() do
    struct = %{:_height => nil, :left => nil, :right => nil}
    struct = %{struct | _height: 0}
    struct
  end
end
