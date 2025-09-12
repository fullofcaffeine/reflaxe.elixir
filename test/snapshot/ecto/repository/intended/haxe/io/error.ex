defmodule Haxe.Io.Error do
  def blocked() do
    {0}
  end
  def overflow() do
    {1}
  end
  def outside_bounds() do
    {2}
  end
  def custom(arg0) do
    {3, arg0}
  end
end