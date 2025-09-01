defmodule Tree do
  def leaf(arg0) do
    {:Leaf, arg0}
  end
  def node(arg0, arg1) do
    {:Node, arg0, arg1}
  end
end