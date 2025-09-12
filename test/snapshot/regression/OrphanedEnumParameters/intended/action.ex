defmodule Action do
  def move(arg0, arg1, arg2) do
    {0, arg0, arg1, arg2}
  end
  def rotate(arg0, arg1) do
    {1, arg0, arg1}
  end
  def scale(arg0) do
    {2, arg0}
  end
end