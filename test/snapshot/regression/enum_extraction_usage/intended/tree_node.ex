defmodule TreeNode do
  def leaf() do
    {0}
  end
  def node(arg0, arg1, arg2) do
    {1, arg0, arg1, arg2}
  end
end
