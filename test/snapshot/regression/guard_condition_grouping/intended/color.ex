defmodule Color do
  def rgb(arg0, arg1, arg2) do
    {0, arg0, arg1, arg2}
  end
  def hsl(arg0, arg1, arg2) do
    {1, arg0, arg1, arg2}
  end
  def named(arg0) do
    {2, arg0}
  end
end
