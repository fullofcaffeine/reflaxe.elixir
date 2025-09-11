defmodule Tree do
  def leaf(arg0) do
    {0, arg0}
  end
  def node(arg0, arg1) do
    {1, arg0, arg1}
  end
end