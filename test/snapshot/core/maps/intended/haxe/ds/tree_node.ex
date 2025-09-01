defmodule TreeNode do
  def new(l, k, v, r, h) do
    %{:left => l, :key => k, :value => v, :right => r}
  end
end